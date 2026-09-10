import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_settings.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../core/firestore_service.dart';
import '../../core/paywall_modal.dart';
import '../../core/plan_service.dart';
import '../../l10n/app_localizations.dart';
import 'modalidades_screen.dart';
import 'planos_screen.dart';

/// Central de Configurações da Academia — hub compacto. Cada configuração com
/// edição própria abre um bottom sheet dedicado que salva no seu próprio fluxo
/// (chamando [_AdminConfiguracoesScreenState._persistirTudo], que reescreve o
/// documento da academia com o estado completo — nenhum campo é perdido).
class AdminConfiguracoesScreen extends StatefulWidget {
  const AdminConfiguracoesScreen({super.key});

  @override
  State<AdminConfiguracoesScreen> createState() =>
      _AdminConfiguracoesScreenState();
}

class _AdminConfiguracoesScreenState extends State<AdminConfiguracoesScreen> {
  AppLocalizations get _l => context.l10n;
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _msgEvasaoCtrl = TextEditingController();
  final _taxaAtrasoValorCtrl = TextEditingController();

  bool _loading = true;
  bool _salvando = false;
  bool _erro = false;
  String _subdominio = '';
  String? _logoBase64;
  bool _bloqueioCheckinAtivo = false;
  int _carenciaDias = 3;
  bool _pesquisaAtiva = false;
  int _pesquisaXpRecompensa = 50;
  bool _taxaAtrasoAtiva = false;
  int _taxaAtrasoTipo = 0; // 0=percentual, 1=fixo

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _cnpjCtrl.dispose();
    _msgEvasaoCtrl.dispose();
    _taxaAtrasoValorCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _erro = false;
    });
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;
      final dados = await firestoreService.getAcademia(academiaId) ?? {};
      _nomeCtrl.text = dados['nome'] as String? ?? '';
      _emailCtrl.text = dados['email'] as String? ?? '';
      _telefoneCtrl.text = dados['telefone'] as String? ?? '';
      _cnpjCtrl.text = dados['cnpj'] as String? ?? '';
      _msgEvasaoCtrl.text = dados['mensagem_evasao'] as String? ?? '';
      _subdominio = dados['subdominio'] as String? ?? '';
      _logoBase64 = dados['logoUrl'] as String?;
      _bloqueioCheckinAtivo = dados['bloqueio_checkin_ativo'] as bool? ?? false;
      _carenciaDias =
          (dados['bloqueio_checkin_carencia_dias'] as num?)?.toInt() ?? 3;
      _pesquisaAtiva = dados['pesquisa_satisfacao_ativa'] as bool? ?? false;
      _pesquisaXpRecompensa =
          (dados['pesquisa_xp_recompensa'] as num?)?.toInt() ?? 50;
      _taxaAtrasoAtiva = dados['taxa_atraso_ativa'] as bool? ?? false;
      _taxaAtrasoTipo = (dados['taxa_atraso_tipo'] as num?)?.toInt() ?? 0;
      _taxaAtrasoValorCtrl.text =
          ((dados['taxa_atraso_valor'] as num?)?.toDouble() ?? 0.0)
              .toStringAsFixed(2)
              .replaceAll('.', ',');
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro = true;
          _loading = false;
        });
      }
    }
  }

  // ── Persistência ──────────────────────────────────────────────────────────

  Map<String, dynamic> _payload() => {
    'nome': _nomeCtrl.text.trim(),
    'email': _emailCtrl.text.trim(),
    'telefone': _telefoneCtrl.text.trim().isEmpty
        ? null
        : _telefoneCtrl.text.trim(),
    'cnpj': _cnpjCtrl.text.trim().isEmpty ? null : _cnpjCtrl.text.trim(),
    'mensagem_evasao': _msgEvasaoCtrl.text.trim().isEmpty
        ? null
        : _msgEvasaoCtrl.text.trim(),
    'logoUrl': _logoBase64,
    'bloqueio_checkin_ativo': _bloqueioCheckinAtivo,
    'bloqueio_checkin_carencia_dias': _carenciaDias,
    'pesquisa_satisfacao_ativa': _pesquisaAtiva,
    'pesquisa_xp_recompensa': _pesquisaXpRecompensa,
    'taxa_atraso_ativa': _taxaAtrasoAtiva,
    'taxa_atraso_tipo': _taxaAtrasoTipo,
    'taxa_atraso_valor':
        double.tryParse(_taxaAtrasoValorCtrl.text.replaceAll(',', '.')) ?? 0.0,
  };

  /// Grava o documento completo da academia (mesma chamada que o antigo botão
  /// "Salvar" global). Retorna `true` em caso de sucesso.
  Future<bool> _persistirTudo() async {
    if (_salvando) return false;
    setState(() => _salvando = true);
    try {
      final user = await AuthStorage.getUser();
      await firestoreService.updateAcademia(user!.academiaId!, _payload());
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _snack(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: erro ? context.sem.danger : context.sem.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggle(
    String label,
    bool atual,
    void Function(bool) aplicar,
    bool novo,
  ) async {
    setState(() => aplicar(novo));
    final ok = await _persistirTudo();
    if (!mounted) return;
    if (!ok) {
      setState(() => aplicar(atual));
      _snack(_l.cfgSaveToggleError, erro: true);
    }
  }

  // ── Aberturas de sheet ────────────────────────────────────────────────────

  Future<T?> _sheet<T>(Widget child) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => child,
  );

  Future<void> _abrirInfoGerais() async {
    await _sheet<void>(
      _InfoGeraisSheet(
        nome: _nomeCtrl.text,
        email: _emailCtrl.text,
        telefone: _telefoneCtrl.text,
        cnpj: _cnpjCtrl.text,
        onSalvar: (m) async {
          _nomeCtrl.text = m['nome']!;
          _emailCtrl.text = m['email']!;
          _telefoneCtrl.text = m['telefone']!;
          _cnpjCtrl.text = m['cnpj']!;
          final ok = await _persistirTudo();
          if (ok) _snack(_l.cfgInfoSaved);
          return ok;
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _abrirLogo() async {
    await _sheet<void>(
      _LogoSheet(
        inicial: _logoBase64,
        onSalvar: (b64) async {
          _logoBase64 = b64;
          final ok = await _persistirTudo();
          if (ok) _snack(_l.cfgLogoSaved);
          return ok;
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _abrirMensagemRetorno() async {
    await _sheet<void>(
      _MensagemRetornoSheet(
        inicial: _msgEvasaoCtrl.text,
        onSalvar: (texto) async {
          _msgEvasaoCtrl.text = texto;
          final ok = await _persistirTudo();
          if (ok) _snack(_l.cfgMsgSaved);
          return ok;
        },
      ),
    );
  }

  Future<void> _abrirTaxaAtraso() async {
    await _sheet<void>(
      _TaxaAtrasoSheet(
        ativa: _taxaAtrasoAtiva,
        tipo: _taxaAtrasoTipo,
        valor: _taxaAtrasoValorCtrl.text,
        onSalvar: (m) async {
          _taxaAtrasoAtiva = m['ativa'] as bool;
          _taxaAtrasoTipo = m['tipo'] as int;
          _taxaAtrasoValorCtrl.text = m['valor'] as String;
          final ok = await _persistirTudo();
          if (ok) _snack(_l.cfgFeeSaved);
          return ok;
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _abrirCarencia() async {
    await _sheet<void>(
      _CarenciaSheet(
        inicial: _carenciaDias,
        onSalvar: (dias) async {
          _carenciaDias = dias;
          final ok = await _persistirTudo();
          if (ok) _snack(_l.cfgGraceSaved);
          return ok;
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _abrirPesquisaConfig() async {
    await _sheet<void>(
      _PesquisaConfigSheet(
        ativa: _pesquisaAtiva,
        xp: _pesquisaXpRecompensa,
        onSalvar: (m) async {
          _pesquisaAtiva = m['ativa'] as bool;
          _pesquisaXpRecompensa = m['xp'] as int;
          final ok = await _persistirTudo();
          if (ok) _snack(_l.cfgSurveySaved);
          return ok;
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _copiarSubdominio() async {
    if (_subdominio.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _subdominio));
    _snack(_l.cfgSubdomainCopied);
  }

  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _idiomaLabel(AppLocalizations l) =>
      switch (appSettings.value.localePref) {
        LocalePref.pt => l.settingsLanguagePt,
        LocalePref.en => l.settingsLanguageEn,
        LocalePref.system => l.settingsOptionSystem,
      };

  String _temaLabel(AppLocalizations l) =>
      switch (appSettings.value.themePref) {
        ThemePref.light => l.settingsThemeLight,
        ThemePref.dark => l.settingsThemeDark,
        ThemePref.system => l.settingsOptionSystem,
      };

  Future<void> _abrirIdioma() async {
    final l = AppLocalizations.of(context);
    await _sheet<void>(
      _OpcaoSheet(
        titulo: l.settingsLanguageSheetTitle,
        opcoes: [
          _Opcao(
            'system',
            l.settingsOptionSystem,
            l.settingsOptionSystemLanguageHint,
            Icons.smartphone_rounded,
          ),
          _Opcao('pt', l.settingsLanguagePt, null, Icons.translate_rounded),
          _Opcao('en', l.settingsLanguageEn, null, Icons.translate_rounded),
        ],
        selecionada: appSettings.value.localePref.name,
        onSelecionar: (v) => setLocalePref(switch (v) {
          'pt' => LocalePref.pt,
          'en' => LocalePref.en,
          _ => LocalePref.system,
        }),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _abrirTema() async {
    final l = AppLocalizations.of(context);
    await _sheet<void>(
      _OpcaoSheet(
        titulo: l.settingsThemeSheetTitle,
        opcoes: [
          _Opcao(
            'system',
            l.settingsOptionSystem,
            l.settingsOptionSystemThemeHint,
            Icons.smartphone_rounded,
          ),
          _Opcao('light', l.settingsThemeLight, null, Icons.light_mode_rounded),
          _Opcao('dark', l.settingsThemeDark, null, Icons.dark_mode_rounded),
        ],
        selecionada: appSettings.value.themePref.name,
        onSelecionar: (v) => setThemePref(switch (v) {
          'light' => ThemePref.light,
          'dark' => ThemePref.dark,
          _ => ThemePref.system,
        }),
      ),
    );
    if (mounted) setState(() {});
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.c.onSurface,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _l.cfgTitle,
          style: TextStyle(
            color: context.c.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _erro
          ? _ErroBox(onRetry: _load)
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Text(
                    _l.cfgSubtitle,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PlanStatusTile(),

                  Builder(
                    builder: (context) {
                      final l = AppLocalizations.of(context);
                      return _SettingsSection(
                        titulo: l.settingsAppearanceSection,
                        subtitulo: l.settingsAppearanceSubtitle,
                        child: _GroupCard(
                          children: [
                            _NavRow(
                              icon: Icons.translate_rounded,
                              titulo: l.settingsLanguage,
                              subtitulo: _idiomaLabel(l),
                              onTap: _abrirIdioma,
                            ),
                            _NavRow(
                              icon: Icons.brightness_6_rounded,
                              titulo: l.settingsTheme,
                              subtitulo: _temaLabel(l),
                              onTap: _abrirTema,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  _SettingsSection(
                    titulo: _l.cfgIdentitySection,
                    subtitulo: _l.cfgIdentitySub,
                    child: _GroupCard(
                      children: [
                        _NavRow(
                          icon: Icons.image_rounded,
                          titulo: _l.cfgLogo,
                          subtitulo: _logoBase64 != null
                              ? _l.cfgLogoHasSub
                              : _l.cfgLogoEmptySub,
                          onTap: _abrirLogo,
                        ),
                        _NavRow(
                          icon: Icons.business_rounded,
                          titulo: _l.cfgGeneralInfo,
                          subtitulo: _l.cfgGeneralInfoSub,
                          onTap: _abrirInfoGerais,
                        ),
                      ],
                    ),
                  ),

                  _SettingsSection(
                    titulo: _l.cfgStudentsSection,
                    subtitulo: _l.cfgStudentsSub,
                    child: _GroupCard(
                      children: [
                        _SwitchRow(
                          icon: Icons.groups_rounded,
                          titulo: _l.cfgBlockCheckin,
                          subtitulo: _l.cfgBlockCheckinSub,
                          valor: _bloqueioCheckinAtivo,
                          onChanged: (v) => _toggle(
                            _l.cfgBlockCheckin,
                            _bloqueioCheckinAtivo,
                            (x) => _bloqueioCheckinAtivo = x,
                            v,
                          ),
                        ),
                        if (_bloqueioCheckinAtivo)
                          _NavRow(
                            icon: Icons.hourglass_bottom_rounded,
                            titulo: _l.cfgGraceDays,
                            subtitulo: _l.cfgGraceDaysSub,
                            trailing: Text(
                              _l.cfgDaysCount(_carenciaDias),
                              style: TextStyle(
                                color: context.c.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            onTap: _abrirCarencia,
                          ),
                      ],
                    ),
                  ),

                  _SettingsSection(
                    titulo: _l.cfgCommSection,
                    subtitulo: _l.cfgCommSub,
                    child: _GroupCard(
                      children: [
                        _NavRow(
                          icon: Icons.chat_rounded,
                          titulo: _l.cfgReturnMsg,
                          subtitulo: _l.cfgReturnMsgSub,
                          onTap: _abrirMensagemRetorno,
                        ),
                        _NavRow(
                          icon: Icons.newspaper_rounded,
                          titulo: _l.menuNews,
                          subtitulo: _l.cfgNewsSub,
                          onTap: () => context.push('/admin/noticias'),
                        ),
                      ],
                    ),
                  ),

                  _SettingsSection(
                    titulo: _l.cfgFinanceSection,
                    subtitulo: _l.cfgFinanceSub,
                    child: _GroupCard(
                      children: [
                        _NavRow(
                          icon: Icons.credit_card_rounded,
                          titulo: _l.plnTitle,
                          subtitulo: _l.cfgPlansSub,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminPlanosScreen(),
                            ),
                          ),
                        ),
                        _SwitchRow(
                          icon: Icons.percent_rounded,
                          titulo: _l.cfgLateFee,
                          subtitulo: _l.cfgLateFeeSub,
                          valor: _taxaAtrasoAtiva,
                          onChanged: (v) => _toggle(
                            _l.cfgLateFee,
                            _taxaAtrasoAtiva,
                            (x) => _taxaAtrasoAtiva = x,
                            v,
                          ),
                        ),
                        if (_taxaAtrasoAtiva)
                          _NavRow(
                            icon: Icons.tune_rounded,
                            titulo: _l.cfgConfigFee,
                            subtitulo: _taxaAtrasoTipo == 0
                                ? _l.cfgFeePercentSub
                                : _l.cfgFeeFixedSub,
                            trailing: Text(
                              _taxaAtrasoTipo == 0
                                  ? '${_taxaAtrasoValorCtrl.text}%'
                                  : 'R\$ ${_taxaAtrasoValorCtrl.text}',
                              style: TextStyle(
                                color: context.c.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            onTap: _abrirTaxaAtraso,
                          ),
                      ],
                    ),
                  ),

                  _SettingsSection(
                    titulo: _l.cfgGradSection,
                    subtitulo: _l.cfgGradSub,
                    child: _GroupCard(
                      children: [
                        _NavRow(
                          icon: Icons.workspace_premium_rounded,
                          titulo: _l.fxTitle,
                          subtitulo: _l.cfgBeltsSub,
                          onTap: () => context.push('/admin/dashboard/faixas'),
                        ),
                        _NavRow(
                          icon: Icons.category_rounded,
                          titulo: _l.cfgModalitiesMgmt,
                          subtitulo: _l.cfgModalitiesSub,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminModalidadesScreen(),
                            ),
                          ),
                        ),
                        _NavRow(
                          icon: Icons.description_rounded,
                          titulo: _l.ctTitle,
                          subtitulo: _l.cfgContractsSub,
                          onTap: () =>
                              context.push('/admin/dashboard/contratos'),
                        ),
                      ],
                    ),
                  ),

                  _SettingsSection(
                    titulo: _l.psvSatisfactionTitle,
                    subtitulo: _l.cfgSurveySub,
                    child: _GroupCard(
                      children: [
                        _NavRow(
                          icon: Icons.tune_rounded,
                          titulo: _l.cfgSurveyConfig,
                          subtitulo: _pesquisaAtiva
                              ? _l.cfgSurveyActiveSub(_pesquisaXpRecompensa)
                              : _l.cfgSurveyInactiveSub,
                          onTap: _abrirPesquisaConfig,
                        ),
                        _NavRow(
                          icon: Icons.poll_rounded,
                          titulo: _l.psvManageTitle,
                          subtitulo: _l.cfgSurveyManageSub,
                          onTap: () =>
                              context.push('/admin/pesquisa/templates'),
                        ),
                        _NavRow(
                          icon: Icons.analytics_rounded,
                          titulo: _l.cfgSurveyAllResponses,
                          subtitulo: _l.cfgSurveyAllResponsesSub,
                          onTap: () => context.push('/admin/pesquisa'),
                        ),
                      ],
                    ),
                  ),

                  _SettingsSection(
                    titulo: _l.cfgSystemSection,
                    subtitulo: _l.cfgSystemSub,
                    child: _GroupCard(
                      children: [
                        _NavRow(
                          icon: Icons.link_rounded,
                          titulo: _l.cfgSubdomain,
                          subtitulo: _subdominio.isEmpty ? '—' : _subdominio,
                          trailing: _subdominio.isEmpty
                              ? const SizedBox.shrink()
                              : Icon(
                                  Icons.copy_rounded,
                                  color: context.c.onSurfaceVariant,
                                  size: 16,
                                ),
                          onTap: _subdominio.isEmpty ? null : _copiarSubdominio,
                        ),
                        _NavRow(
                          icon: Icons.shield_rounded,
                          titulo: _l.cfgPrivacy,
                          subtitulo: _l.cfgPrivacySub,
                          trailing: Icon(
                            Icons.open_in_new_rounded,
                            color: context.c.onSurfaceVariant,
                            size: 16,
                          ),
                          onTap: () => _abrirLink(
                            'https://senseimanager.com.br/privacidade',
                          ),
                        ),
                        _NavRow(
                          icon: Icons.gavel_rounded,
                          titulo: _l.cfgTerms,
                          subtitulo: _l.cfgTermsSub,
                          trailing: Icon(
                            Icons.open_in_new_rounded,
                            color: context.c.onSurfaceVariant,
                            size: 16,
                          ),
                          onTap: () =>
                              _abrirLink('https://senseimanager.com.br/termos'),
                        ),
                      ],
                    ),
                  ),

                  _SettingsSection(
                    titulo: _l.cfgAccountSection,
                    child: _BotaoSair(),
                  ),
                  _SettingsSection(
                    titulo: _l.cfgDangerSection,
                    child: _BotaoExcluirConta(),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─── Hub: seções, cards agrupados e linhas ───────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.titulo,
    this.subtitulo,
    required this.child,
  });
  final String titulo;
  final String? subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: context.c.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitulo!,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(left: 62),
            child: Divider(height: 1, color: context.c.outline),
          ),
        );
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: context.c.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitulo,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      icon: icon,
      titulo: titulo,
      subtitulo: subtitulo,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?trailing,
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: context.c.onSurfaceVariant,
              size: 18,
            ),
          ],
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.onChanged,
  });
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: valor,
      label: titulo,
      child: _RowShell(
        icon: icon,
        titulo: titulo,
        subtitulo: subtitulo,
        trailing: Switch(
          value: valor,
          onChanged: onChanged,
          activeThumbColor: context.c.primary,
        ),
      ),
    );
  }
}

class _ErroBox extends StatelessWidget {
  const _ErroBox({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: context.sem.danger, size: 44),
            const SizedBox(height: 14),
            Text(
              context.l10n.cfgLoadError,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.commonRetry),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.c.primary,
                minimumSize: const Size(0, 46),
                side: BorderSide(
                  color: context.c.primary.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Base dos bottom sheets ─────────────────────────────────────────────────

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.titulo,
    required this.child,
    this.descricao,
  });
  final String titulo;
  final String? descricao;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.c.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (descricao != null) ...[
              const SizedBox(height: 6),
              Text(
                descricao!,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

/// Botão de salvar padronizado dos sheets: bloqueia duplo clique, mostra
/// progresso e fecha em caso de sucesso.
class _SheetSaveButton extends StatefulWidget {
  const _SheetSaveButton({required this.label, required this.onSalvar});
  final String label;
  final Future<bool> Function() onSalvar;

  @override
  State<_SheetSaveButton> createState() => _SheetSaveButtonState();
}

class _SheetSaveButtonState extends State<_SheetSaveButton> {
  AppLocalizations get _l => context.l10n;
  bool _salvando = false;

  Future<void> _go() async {
    setState(() => _salvando = true);
    final ok = await widget.onSalvar();
    if (!mounted) return;
    setState(() => _salvando = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l.cfgSaveError),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _salvando ? null : _go,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.c.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _salvando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(widget.label),
      ),
    );
  }
}

// ─── Sheet: Informações Gerais ─────────────────────────────────────────────

class _InfoGeraisSheet extends StatefulWidget {
  const _InfoGeraisSheet({
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cnpj,
    required this.onSalvar,
  });
  final String nome, email, telefone, cnpj;
  final Future<bool> Function(Map<String, String>) onSalvar;

  @override
  State<_InfoGeraisSheet> createState() => _InfoGeraisSheetState();
}

class _InfoGeraisSheetState extends State<_InfoGeraisSheet> {
  AppLocalizations get _l => context.l10n;
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.nome);
  late final _email = TextEditingController(text: widget.email);
  late final _telefone = TextEditingController(text: widget.telefone);
  late final _cnpj = TextEditingController(text: widget.cnpj);

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _cnpj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      titulo: _l.cfgGeneralInfo,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _Field(
              controller: _nome,
              label: _l.cfgAcademyName,
              icon: Icons.sports_martial_arts_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? _l.commonRequiredField
                  : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _email,
              label: _l.cfgEmail,
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return _l.commonRequiredField;
                if (!v.contains('@')) return _l.commonInvalidEmail;
                return null;
              },
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _telefone,
              label: _l.cfgPhone,
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _cnpj,
              label: _l.cfgCnpj,
              icon: Icons.business_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _SheetSaveButton(
              label: _l.sdSaveChanges,
              onSalvar: () async {
                if (!_formKey.currentState!.validate()) return false;
                return widget.onSalvar({
                  'nome': _nome.text.trim(),
                  'email': _email.text.trim(),
                  'telefone': _telefone.text.trim(),
                  'cnpj': _cnpj.text.trim(),
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sheet: Logo da Academia ──────────────────────────────────────────────

class _LogoSheet extends StatefulWidget {
  const _LogoSheet({required this.inicial, required this.onSalvar});
  final String? inicial;
  final Future<bool> Function(String?) onSalvar;

  @override
  State<_LogoSheet> createState() => _LogoSheetState();
}

class _LogoSheetState extends State<_LogoSheet> {
  AppLocalizations get _l => context.l10n;
  late String? _b64 = widget.inicial;

  Future<void> _escolher() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    final bytes = result.files.single.bytes!;
    final ext = (result.files.single.extension ?? 'jpg').toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    setState(() => _b64 = 'data:$mime;base64,${base64Encode(bytes)}');
  }

  @override
  Widget build(BuildContext context) {
    final temLogo = _b64 != null && _b64!.contains(',');
    return _SheetScaffold(
      titulo: _l.cfgLogo,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.c.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.c.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: temLogo
                ? Image.memory(
                    base64Decode(_b64!.split(',').last),
                    fit: BoxFit.cover,
                  )
                : Icon(
                    Icons.add_photo_alternate_rounded,
                    color: context.c.primary,
                    size: 40,
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _escolher,
                  icon: Icon(Icons.upload_rounded, size: 18),
                  label: Text(temLogo ? _l.cfgChangeImage : _l.cfgChooseImage),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.c.primary,
                    minimumSize: const Size(0, 46),
                    side: BorderSide(
                      color: context.c.primary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (temLogo) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => setState(() => _b64 = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.sem.danger,
                    minimumSize: const Size(0, 46),
                    side: BorderSide(
                      color: context.sem.danger.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_l.commonRemove),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _SheetSaveButton(
            label: _l.commonSave,
            onSalvar: () => widget.onSalvar(_b64),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet: Mensagem de retorno (WhatsApp) ─────────────────────────────────

class _MensagemRetornoSheet extends StatefulWidget {
  const _MensagemRetornoSheet({required this.inicial, required this.onSalvar});
  final String inicial;
  final Future<bool> Function(String) onSalvar;

  @override
  State<_MensagemRetornoSheet> createState() => _MensagemRetornoSheetState();
}

class _MensagemRetornoSheetState extends State<_MensagemRetornoSheet> {
  AppLocalizations get _l => context.l10n;
  late final _ctrl = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _preview {
    final base = _ctrl.text.trim().isEmpty
        ? _l.cfgReturnMsgDefault('{nome}', '{dias}')
        : _ctrl.text.trim();
    return base.replaceAll('{nome}', 'Gabriel').replaceAll('{dias}', '13');
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      titulo: _l.cfgReturnMsgTitle,
      descricao: _l.cfgReturnMsgDesc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final v in ['{nome}', '{dias}'])
                Chip(
                  label: Text(
                    v,
                    style: TextStyle(color: context.c.primary, fontSize: 12),
                  ),
                  backgroundColor: context.c.primary.withValues(alpha: 0.12),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: context.c.onSurface, fontSize: 13),
            decoration: InputDecoration(
              hintText: _l.cfgReturnMsgHint('{nome}', '{dias}'),
              hintStyle: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 12,
              ),
              filled: true,
              fillColor: context.c.surfaceContainer,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.c.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.c.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _l.commonPreview,
            style: TextStyle(
              color: context.c.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.sem.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.sem.success.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              _preview,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _ctrl.clear()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.c.onSurfaceVariant,
                    minimumSize: const Size(0, 46),
                    side: BorderSide(color: context.c.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_l.cfgRestoreDefault),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SheetSaveButton(
                  label: _l.cfgSaveMsg,
                  onSalvar: () => widget.onSalvar(_ctrl.text.trim()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sheet: Taxa de atraso ────────────────────────────────────────────────

class _TaxaAtrasoSheet extends StatefulWidget {
  const _TaxaAtrasoSheet({
    required this.ativa,
    required this.tipo,
    required this.valor,
    required this.onSalvar,
  });
  final bool ativa;
  final int tipo;
  final String valor;
  final Future<bool> Function(Map<String, dynamic>) onSalvar;

  @override
  State<_TaxaAtrasoSheet> createState() => _TaxaAtrasoSheetState();
}

class _TaxaAtrasoSheetState extends State<_TaxaAtrasoSheet> {
  AppLocalizations get _l => context.l10n;
  late bool _ativa = widget.ativa;
  late int _tipo = widget.tipo;
  late final _valorCtrl = TextEditingController(text: widget.valor);

  @override
  void dispose() {
    _valorCtrl.dispose();
    super.dispose();
  }

  String get _descricao {
    final v = _valorCtrl.text.trim().isEmpty ? '0' : _valorCtrl.text.trim();
    return _tipo == 0 ? _l.cfgFeePercentDesc(v) : _l.cfgFeeFixedDesc(v);
  }

  Widget _segmento(String label, int tipo) {
    final sel = _tipo == tipo;
    return Expanded(
      child: GestureDetector(
        onTap: _ativa ? () => setState(() => _tipo = tipo) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? context.c.primary : context.c.surfaceContainer,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(tipo == 0 ? 10 : 0),
              right: Radius.circular(tipo == 1 ? 10 : 0),
            ),
            border: Border.all(
              color: sel ? context.c.primary : context.c.outline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.black : context.c.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      titulo: _l.cfgLateFee,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _l.cfgLateFeeToggle,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _ativa,
                onChanged: (v) => setState(() => _ativa = v),
                activeThumbColor: context.c.primary,
              ),
            ],
          ),
          if (_ativa) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _segmento(_l.cfgPercent, 0),
                _segmento(_l.cfgFixedValue, 1),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: context.c.onSurface),
              decoration: InputDecoration(
                labelText: _tipo == 0
                    ? _l.cfgFeePercentLabel
                    : _l.cfgFeeFixedLabel,
                labelStyle: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 13,
                ),
                prefixText: _tipo == 1 ? 'R\$ ' : null,
                suffixText: _tipo == 0 ? '%' : null,
                filled: true,
                fillColor: context.c.surfaceContainer,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.c.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.c.primary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _descricao,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          _SheetSaveButton(
            label: _l.commonSave,
            onSalvar: () => widget.onSalvar({
              'ativa': _ativa,
              'tipo': _tipo,
              'valor': _valorCtrl.text.trim().isEmpty
                  ? '0,00'
                  : _valorCtrl.text.trim(),
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet: Dias de carência ──────────────────────────────────────────────

class _CarenciaSheet extends StatefulWidget {
  const _CarenciaSheet({required this.inicial, required this.onSalvar});
  final int inicial;
  final Future<bool> Function(int) onSalvar;

  @override
  State<_CarenciaSheet> createState() => _CarenciaSheetState();
}

class _CarenciaSheetState extends State<_CarenciaSheet> {
  AppLocalizations get _l => context.l10n;
  late int _dias = widget.inicial;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      titulo: _l.cfgGraceDays,
      descricao: _l.cfgGraceDaysDesc,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 32,
                onPressed: _dias > 0 ? () => setState(() => _dias--) : null,
                icon: Icon(
                  Icons.remove_circle_outline_rounded,
                  color: _dias > 0 ? context.c.primary : context.c.outline,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '$_dias',
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                iconSize: 32,
                onPressed: _dias < 30 ? () => setState(() => _dias++) : null,
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: _dias < 30 ? context.c.primary : context.c.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SheetSaveButton(
            label: _l.commonSave,
            onSalvar: () => widget.onSalvar(_dias),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet: Configurações da pesquisa ─────────────────────────────────────

class _PesquisaConfigSheet extends StatefulWidget {
  const _PesquisaConfigSheet({
    required this.ativa,
    required this.xp,
    required this.onSalvar,
  });
  final bool ativa;
  final int xp;
  final Future<bool> Function(Map<String, dynamic>) onSalvar;

  @override
  State<_PesquisaConfigSheet> createState() => _PesquisaConfigSheetState();
}

class _PesquisaConfigSheetState extends State<_PesquisaConfigSheet> {
  AppLocalizations get _l => context.l10n;
  late bool _ativa = widget.ativa;
  late int _xp = widget.xp;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      titulo: _l.cfgSurveyConfig,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _l.cfgSurveyEnable,
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _l.cfgSurveyEnableSub,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _ativa,
                onChanged: (v) => setState(() => _ativa = v),
                activeThumbColor: context.c.primary,
              ),
            ],
          ),
          if (_ativa) ...[
            const Divider(height: 26),
            Text(
              _l.cfgSurveyXp,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _l.cfgSurveyXpSub,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 30,
                  onPressed: _xp >= 25 ? () => setState(() => _xp -= 25) : null,
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: _xp >= 25 ? context.c.primary : context.c.outline,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    '$_xp',
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 30,
                  onPressed: _xp < 500 ? () => setState(() => _xp += 25) : null,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: _xp < 500 ? context.c.primary : context.c.outline,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          _SheetSaveButton(
            label: _l.commonSave,
            onSalvar: () => widget.onSalvar({'ativa': _ativa, 'xp': _xp}),
          ),
        ],
      ),
    );
  }
}

// ─── Conta / Zona de perigo (reaproveitados) ──────────────────────────────

class _BotaoSair extends StatefulWidget {
  @override
  State<_BotaoSair> createState() => _BotaoSairState();
}

class _BotaoSairState extends State<_BotaoSair> {
  AppLocalizations get _l => context.l10n;
  bool _loading = false;

  Future<void> _sair() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.cfgLogout,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          _l.cfgLogoutConfirm,
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              _l.cfgLogout,
              style: TextStyle(
                color: context.sem.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await AuthStorage.clear();
    if (!mounted) return;
    context.go('/boas-vindas');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _sair,
        icon: _loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.sem.danger,
                ),
              )
            : Icon(Icons.logout_rounded, color: context.sem.danger, size: 18),
        label: Text(
          _l.cfgLogoutBtn,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.sem.danger,
          side: BorderSide(color: context.sem.danger.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _BotaoExcluirConta extends StatefulWidget {
  @override
  State<_BotaoExcluirConta> createState() => _BotaoExcluirContaState();
}

class _BotaoExcluirContaState extends State<_BotaoExcluirConta> {
  AppLocalizations get _l => context.l10n;
  bool _loading = false;

  Future<void> _excluir() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.cfgDeleteAccountTitle,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          _l.cfgDeleteAccountBody,
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              _l.commonDelete,
              style: TextStyle(
                color: context.sem.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.currentUser?.delete();
      await AuthStorage.clear();
      if (!mounted) return;
      context.go('/boas-vindas');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l.cfgDeleteAccountError),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _excluir,
        icon: _loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.sem.danger,
                ),
              )
            : Icon(
                Icons.delete_outline_rounded,
                color: context.sem.danger,
                size: 18,
              ),
        label: Text(
          _l.cfgDeleteAccountBtn,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.sem.danger,
          side: BorderSide(color: context.sem.danger.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ─── Card do plano (reaproveitado) ───────────────────────────────────────────

class _PlanStatusTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final plan = PlanService.instance;
    final isPro = plan.isPro;
    final isInTrial = plan.isInTrial;
    final days = plan.daysLeftInTrial;
    final displayName = plan.planDisplayName;

    final Color borderColor = (isPro || isInTrial)
        ? const Color(0xFF6C3FFF)
        : context.sem.warning;
    final Color iconColor = isPro
        ? const Color(0xFFFFD700)
        : isInTrial
        ? context.c.primary
        : context.sem.warning;
    final IconData icon = isPro
        ? Icons.workspace_premium_rounded
        : isInTrial
        ? Icons.hourglass_top_rounded
        : Icons.lock_outline_rounded;

    Future<void> abrir() async {
      if (isPro) return;
      final ok = await mostrarPaywall(context);
      if (ok == true) await PlanService.instance.refresh();
    }

    return GestureDetector(
      onTap: abrir,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.c.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF6C3FFF,
                          ).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPro
                              ? context.l10n.cfgPlanActive
                              : isInTrial
                              ? context.l10n.cfgPlanTrial
                              : context.l10n.cfgPlanFree,
                          style: const TextStyle(
                            color: Color(0xFFB79CFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPro
                        ? context.l10n.cfgPlanProDesc
                        : isInTrial
                        ? (days <= 1
                              ? context.l10n.cfgPlanTrialLastDay
                              : context.l10n.cfgPlanTrialDaysLeft(days))
                        : context.l10n.cfgPlanFreeDesc,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isPro ? Icons.chevron_right_rounded : Icons.chevron_right_rounded,
              color: context.c.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Campo de formulário (reaproveitado pelos sheets) ────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: context.c.onSurface, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.c.onSurfaceVariant, fontSize: 13),
        prefixIcon: Icon(icon, color: context.c.onSurfaceVariant, size: 18),
        filled: true,
        fillColor: context.c.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.c.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.c.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.c.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.sem.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.sem.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

// ── Seletor genérico de opção (idioma / tema) ──────────────────────────────

class _Opcao {
  const _Opcao(this.valor, this.titulo, this.hint, this.icone);
  final String valor;
  final String titulo;
  final String? hint;
  final IconData icone;
}

class _OpcaoSheet extends StatefulWidget {
  const _OpcaoSheet({
    required this.titulo,
    required this.opcoes,
    required this.selecionada,
    required this.onSelecionar,
  });

  final String titulo;
  final List<_Opcao> opcoes;
  final String selecionada;
  final Future<void> Function(String) onSelecionar;

  @override
  State<_OpcaoSheet> createState() => _OpcaoSheetState();
}

class _OpcaoSheetState extends State<_OpcaoSheet> {
  late String _sel = widget.selecionada;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      titulo: widget.titulo,
      child: Column(
        children: widget.opcoes.map((o) {
          final sel = o.valor == _sel;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: sel
                  ? context.c.primary.withValues(alpha: 0.12)
                  : context.c.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final nav = Navigator.of(context);
                  setState(() => _sel = o.valor);
                  await widget.onSelecionar(o.valor);
                  if (mounted) nav.pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? context.c.primary : context.c.outline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        o.icone,
                        size: 20,
                        color: sel
                            ? context.c.primary
                            : context.c.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.titulo,
                              style: TextStyle(
                                color: context.c.onSurface,
                                fontSize: 14,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            if (o.hint != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                o.hint!,
                                style: TextStyle(
                                  color: context.c.onSurfaceVariant,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (sel)
                        Icon(
                          Icons.check_rounded,
                          color: context.c.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
