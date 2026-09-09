import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';
import '../../core/paywall_modal.dart';
import '../../core/plan_service.dart';
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
        backgroundColor: erro ? kDanger : kSuccess,
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
      _snack('Não foi possível salvar a alteração.', erro: true);
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
          if (ok) _snack('Informações salvas.');
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
          if (ok) _snack('Logo atualizada.');
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
          if (ok) _snack('Mensagem salva.');
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
          if (ok) _snack('Taxa de atraso salva.');
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
          if (ok) _snack('Carência atualizada.');
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
          if (ok) _snack('Configurações da pesquisa salvas.');
          return ok;
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _copiarSubdominio() async {
    if (_subdominio.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _subdominio));
    _snack('Subdomínio copiado.');
  }

  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kText1, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Configurações da Academia',
          style: TextStyle(
            color: kText1,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro
          ? _ErroBox(onRetry: _load)
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Text(
                    'Gerencie as informações e preferências da sua academia.',
                    style: TextStyle(color: kText2, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _PlanStatusTile(),

                  _SettingsSection(
                    titulo: 'Identidade da Academia',
                    subtitulo: 'Personalize as informações da sua academia.',
                    child: _GroupCard(
                      children: [
                        _NavRow(
                          icon: Icons.image_rounded,
                          titulo: 'Logo da Academia',
                          subtitulo: _logoBase64 != null
                              ? 'Toque para alterar ou remover'
                              : 'Adicione a logo da academia',
                          onTap: _abrirLogo,
                        ),
                        _NavRow(
                          icon: Icons.business_rounded,
                          titulo: 'Informações Gerais',
                          subtitulo: 'Nome, e-mail, telefone, CNPJ',
                          onTap: _abrirInfoGerais,
                        ),
                      ],
                    ),
                  ),

                  _SettingsSection(
                    titulo: 'Alunos',
                    subtitulo: 'Configure opções relacionadas aos alunos.',
                    child: _GroupCard(
                      children: [
                        _SwitchRow(
                          icon: Icons.groups_rounded,
                          titulo: 'Bloquear check-in por mensalidade vencida',
                          subtitulo:
                              'Impede check-in de alunos com pagamento vencido',
                          valor: _bloqueioCheckinAtivo,
                          onChanged: (v) => _toggle(
                            'Bloqueio de check-in',
                            _bloqueioCheckinAtivo,
                            (x) => _bloqueioCheckinAtivo = x,
                            v,
                          ),
                        ),
                        if (_bloqueioCheckinAtivo)
                          _NavRow(
                            icon: Icons.hourglass_bottom_rounded,
                            titulo: 'Dias de carência',
                            subtitulo:
                                'Bloqueia após os dias definidos do vencimento',
                            trailing: Text(
                              '$_carenciaDias ${_carenciaDias == 1 ? "dia" : "dias"}',
                              style: TextStyle(
                                color: kPrimary,
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
                    titulo: 'Comunicação',
                    subtitulo: 'Personalize as mensagens enviadas aos alunos.',
                    child: _GroupCard(
                      children: [
                        _NavRow(
                          icon: Icons.chat_rounded,
                          titulo: 'Mensagem de retorno (WhatsApp)',
                          subtitulo: 'Mensagem para alunos em risco de evasão',
                          onTap: _abrirMensagemRetorno,
                        ),
                        _NavRow(
                          icon: Icons.newspaper_rounded,
                          titulo: 'Notícias',
                          subtitulo: 'Publicar notícias e comunicados',
                          onTap: () => context.push('/admin/noticias'),
                        ),
                      ],
                    ),
                  ),

                  _SettingsSection(
                    titulo: 'Financeiro',
                    subtitulo: 'Configure cobranças e opções financeiras.',
                    child: _GroupCard(
                      children: [
                        _NavRow(
                          icon: Icons.credit_card_rounded,
                          titulo: 'Planos de Pagamento',
                          subtitulo:
                              'Criar, editar e excluir planos de mensalidade',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminPlanosScreen(),
                            ),
                          ),
                        ),
                        _SwitchRow(
                          icon: Icons.percent_rounded,
                          titulo: 'Taxa de atraso',
                          subtitulo:
                              'Valor extra exibido em cobranças vencidas',
                          valor: _taxaAtrasoAtiva,
                          onChanged: (v) => _toggle(
                            'Taxa de atraso',
                            _taxaAtrasoAtiva,
                            (x) => _taxaAtrasoAtiva = x,
                            v,
                          ),
                        ),
                        if (_taxaAtrasoAtiva)
                          _NavRow(
                            icon: Icons.tune_rounded,
                            titulo: 'Configurar taxa',
                            subtitulo: _taxaAtrasoTipo == 0
                                ? 'Percentual sobre cobranças vencidas'
                                : 'Valor fixo em cobranças vencidas',
                            trailing: Text(
                              _taxaAtrasoTipo == 0
                                  ? '${_taxaAtrasoValorCtrl.text}%'
                                  : 'R\$ ${_taxaAtrasoValorCtrl.text}',
                              style: TextStyle(
                                color: kPrimary,
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
                    titulo: 'Graduações e Modalidades',
                    subtitulo: 'Configure faixas, graduações e modalidades.',
                    child: _GroupCard(
                      children: [
                        _NavRow(
                          icon: Icons.workspace_premium_rounded,
                          titulo: 'Gestão de Faixas',
                          subtitulo:
                              'Cadastrar e editar graduações por modalidade',
                          onTap: () => context.push('/admin/dashboard/faixas'),
                        ),
                        _NavRow(
                          icon: Icons.category_rounded,
                          titulo: 'Gestão de Modalidades',
                          subtitulo: 'Ativar, desativar ou criar modalidades',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminModalidadesScreen(),
                            ),
                          ),
                        ),
                        _NavRow(
                          icon: Icons.description_rounded,
                          titulo: 'Modelos de Contrato',
                          subtitulo: 'Criar e editar modelos de contrato',
                          onTap: () =>
                              context.push('/admin/dashboard/contratos'),
                        ),
                      ],
                    ),
                  ),

                  _SettingsSection(
                    titulo: 'Pesquisa de Satisfação',
                    subtitulo:
                        'Configure pesquisas e acompanhe as respostas dos alunos.',
                    child: _GroupCard(
                      children: [
                        _NavRow(
                          icon: Icons.tune_rounded,
                          titulo: 'Configurações da pesquisa',
                          subtitulo: _pesquisaAtiva
                              ? 'Ativa · $_pesquisaXpRecompensa XP por resposta'
                              : 'Pesquisa mensal desativada',
                          onTap: _abrirPesquisaConfig,
                        ),
                        _NavRow(
                          icon: Icons.poll_rounded,
                          titulo: 'Gerenciar pesquisas',
                          subtitulo: 'Criar, ativar e acompanhar pesquisas',
                          onTap: () =>
                              context.push('/admin/pesquisa/templates'),
                        ),
                        _NavRow(
                          icon: Icons.analytics_rounded,
                          titulo: 'Ver todas as respostas',
                          subtitulo: 'Avaliações e comentários dos alunos',
                          onTap: () => context.push('/admin/pesquisa'),
                        ),
                      ],
                    ),
                  ),

                  _SettingsSection(
                    titulo: 'Sistema e Legal',
                    subtitulo: 'Informações do sistema e documentos legais.',
                    child: _GroupCard(
                      children: [
                        _NavRow(
                          icon: Icons.link_rounded,
                          titulo: 'Subdomínio',
                          subtitulo: _subdominio.isEmpty ? '—' : _subdominio,
                          trailing: _subdominio.isEmpty
                              ? const SizedBox.shrink()
                              : Icon(
                                  Icons.copy_rounded,
                                  color: kText2,
                                  size: 16,
                                ),
                          onTap: _subdominio.isEmpty ? null : _copiarSubdominio,
                        ),
                        _NavRow(
                          icon: Icons.shield_rounded,
                          titulo: 'Política de Privacidade',
                          subtitulo: 'Como tratamos seus dados (LGPD)',
                          trailing: Icon(
                            Icons.open_in_new_rounded,
                            color: kText2,
                            size: 16,
                          ),
                          onTap: () => _abrirLink(
                            'https://senseimanager.com.br/privacidade',
                          ),
                        ),
                        _NavRow(
                          icon: Icons.gavel_rounded,
                          titulo: 'Termos de Uso',
                          subtitulo: 'Condições de uso do Sensei Manager',
                          trailing: Icon(
                            Icons.open_in_new_rounded,
                            color: kText2,
                            size: 16,
                          ),
                          onTap: () =>
                              _abrirLink('https://senseimanager.com.br/termos'),
                        ),
                      ],
                    ),
                  ),

                  _SettingsSection(titulo: 'Conta', child: _BotaoSair()),
                  _SettingsSection(
                    titulo: 'Zona de Perigo',
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
              color: kText1,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(subtitulo!, style: TextStyle(color: kText2, fontSize: 12)),
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
            child: Divider(height: 1, color: kBorder),
          ),
        );
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
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
              color: kPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: kPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: kText1,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitulo,
                  style: TextStyle(color: kText2, fontSize: 11.5),
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
            Icon(Icons.chevron_right_rounded, color: kText2, size: 18),
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
          activeThumbColor: kPrimary,
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
            Icon(Icons.wifi_off_rounded, color: kDanger, size: 44),
            const SizedBox(height: 14),
            Text(
              'Não foi possível carregar as configurações.',
              style: TextStyle(color: kText2, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                minimumSize: const Size(0, 46),
                side: BorderSide(color: kPrimary.withValues(alpha: 0.5)),
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
      decoration: const BoxDecoration(
        color: kBg,
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
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              style: TextStyle(
                color: kText1,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (descricao != null) ...[
              const SizedBox(height: 6),
              Text(
                descricao!,
                style: TextStyle(color: kText2, fontSize: 12.5, height: 1.4),
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
          content: const Text('Não foi possível salvar as alterações.'),
          backgroundColor: kDanger,
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
          backgroundColor: kPrimary,
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
      titulo: 'Informações Gerais',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _Field(
              controller: _nome,
              label: 'Nome da Academia',
              icon: Icons.sports_martial_arts_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _email,
              label: 'E-mail',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Obrigatório';
                if (!v.contains('@')) return 'E-mail inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _telefone,
              label: 'Telefone',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _cnpj,
              label: 'CNPJ',
              icon: Icons.business_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _SheetSaveButton(
              label: 'Salvar alterações',
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
      titulo: 'Logo da Academia',
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: temLogo
                ? Image.memory(
                    base64Decode(_b64!.split(',').last),
                    fit: BoxFit.cover,
                  )
                : Icon(
                    Icons.add_photo_alternate_rounded,
                    color: kPrimary,
                    size: 40,
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _escolher,
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: Text(temLogo ? 'Trocar imagem' : 'Escolher imagem'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimary,
                    minimumSize: const Size(0, 46),
                    side: BorderSide(color: kPrimary.withValues(alpha: 0.5)),
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
                    foregroundColor: kDanger,
                    minimumSize: const Size(0, 46),
                    side: BorderSide(color: kDanger.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Remover'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _SheetSaveButton(
            label: 'Salvar',
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
  late final _ctrl = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _preview {
    final base = _ctrl.text.trim().isEmpty
        ? 'Oi {nome}! Sentimos sua falta — faz {dias} dias sem treino. '
              'Está tudo bem? Qualquer coisa a gente ajuda pra você voltar. 🥋'
        : _ctrl.text.trim();
    return base.replaceAll('{nome}', 'Gabriel').replaceAll('{dias}', '13');
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      titulo: 'Mensagem de retorno',
      descricao:
          'Usada ao entrar em contato com alunos que estão há alguns dias '
          'sem treinar. Deixe em branco para usar a mensagem padrão do sistema.',
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
                    style: TextStyle(color: kPrimary, fontSize: 12),
                  ),
                  backgroundColor: kPrimary.withValues(alpha: 0.12),
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
            style: TextStyle(color: kText1, fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  'Oi {nome}! Sentimos sua falta — faz {dias} dias sem treino...',
              hintStyle: TextStyle(color: kText2, fontSize: 12),
              filled: true,
              fillColor: kSurface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kPrimary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Prévia',
            style: TextStyle(
              color: kText2,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSuccess.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kSuccess.withValues(alpha: 0.25)),
            ),
            child: Text(
              _preview,
              style: TextStyle(color: kText1, fontSize: 12.5, height: 1.4),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _ctrl.clear()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kText2,
                    minimumSize: const Size(0, 46),
                    side: BorderSide(color: kBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Restaurar padrão'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SheetSaveButton(
                  label: 'Salvar mensagem',
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
    return _tipo == 0
        ? 'Será adicionado $v% às cobranças vencidas.'
        : 'Será adicionado R\$ $v às cobranças vencidas.';
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
            color: sel ? kPrimary : kSurface,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(tipo == 0 ? 10 : 0),
              right: Radius.circular(tipo == 1 ? 10 : 0),
            ),
            border: Border.all(color: sel ? kPrimary : kBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.black : kText2,
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
      titulo: 'Taxa de atraso',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cobrar taxa em cobranças vencidas',
                  style: TextStyle(
                    color: kText1,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _ativa,
                onChanged: (v) => setState(() => _ativa = v),
                activeThumbColor: kPrimary,
              ),
            ],
          ),
          if (_ativa) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _segmento('Percentual (%)', 0),
                _segmento('Valor fixo (R\$)', 1),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: kText1),
              decoration: InputDecoration(
                labelText: _tipo == 0
                    ? 'Percentual de atraso'
                    : 'Valor fixo de atraso',
                labelStyle: TextStyle(color: kText2, fontSize: 13),
                prefixText: _tipo == 1 ? 'R\$ ' : null,
                suffixText: _tipo == 0 ? '%' : null,
                filled: true,
                fillColor: kSurface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: kPrimary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(_descricao, style: TextStyle(color: kText2, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          _SheetSaveButton(
            label: 'Salvar',
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
  late int _dias = widget.inicial;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      titulo: 'Dias de carência',
      descricao:
          'O check-in do aluno é bloqueado somente após este número de dias '
          'do vencimento da mensalidade.',
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
                  color: _dias > 0 ? kPrimary : kBorder,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '$_dias',
                  style: TextStyle(
                    color: kText1,
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
                  color: _dias < 30 ? kPrimary : kBorder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SheetSaveButton(
            label: 'Salvar',
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
  late bool _ativa = widget.ativa;
  late int _xp = widget.xp;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      titulo: 'Configurações da pesquisa',
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
                      'Ativar pesquisa mensal',
                      style: TextStyle(
                        color: kText1,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Alunos serão convidados a avaliar a academia 1x/mês.',
                      style: TextStyle(color: kText2, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _ativa,
                onChanged: (v) => setState(() => _ativa = v),
                activeThumbColor: kPrimary,
              ),
            ],
          ),
          if (_ativa) ...[
            const Divider(height: 26),
            Text(
              'XP por resposta',
              style: TextStyle(
                color: kText1,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Pontos concedidos ao aluno após responder.',
              style: TextStyle(color: kText2, fontSize: 12),
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
                    color: _xp >= 25 ? kPrimary : kBorder,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    '$_xp',
                    style: TextStyle(
                      color: kText1,
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
                    color: _xp < 500 ? kPrimary : kBorder,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          _SheetSaveButton(
            label: 'Salvar',
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
  bool _loading = false;

  Future<void> _sair() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(
          'Sair',
          style: TextStyle(color: kText1, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Deseja encerrar sua sessão?',
          style: TextStyle(color: kText2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancelar', style: TextStyle(color: kText2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              'Sair',
              style: TextStyle(color: kDanger, fontWeight: FontWeight.w700),
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
                  color: kDanger,
                ),
              )
            : Icon(Icons.logout_rounded, color: kDanger, size: 18),
        label: const Text(
          'Sair da conta',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: kDanger,
          side: BorderSide(color: kDanger.withValues(alpha: 0.5)),
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
  bool _loading = false;

  Future<void> _excluir() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(
          'Excluir conta?',
          style: TextStyle(color: kText1, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Seus dados pessoais serão removidos permanentemente. '
          'Esta ação não pode ser desfeita.',
          style: TextStyle(color: kText2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancelar', style: TextStyle(color: kText2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              'Excluir',
              style: TextStyle(color: kDanger, fontWeight: FontWeight.w700),
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
          content: const Text('Erro ao excluir conta. Tente novamente.'),
          backgroundColor: kDanger,
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
                  color: kDanger,
                ),
              )
            : Icon(Icons.delete_outline_rounded, color: kDanger, size: 18),
        label: const Text(
          'Excluir minha conta',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: kDanger,
          side: BorderSide(color: kDanger.withValues(alpha: 0.5)),
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
        : kWarning;
    final Color iconColor = isPro
        ? const Color(0xFFFFD700)
        : isInTrial
        ? kPrimary
        : kWarning;
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
          color: kSurface,
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
                            color: kText1,
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
                              ? 'Plano Ativo'
                              : isInTrial
                              ? 'Trial'
                              : 'Gratuito',
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
                        ? 'Acesso completo sem anúncios'
                        : isInTrial
                        ? (days <= 1
                              ? 'Último dia do trial!'
                              : '$days dias restantes no trial')
                        : '3 turmas · 10 alunos/turma · anúncios',
                    style: TextStyle(color: kText2, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isPro ? Icons.chevron_right_rounded : Icons.chevron_right_rounded,
              color: kText2,
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
      style: TextStyle(color: kText1, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kText2, fontSize: 13),
        prefixIcon: Icon(icon, color: kText2, size: 18),
        filled: true,
        fillColor: kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kDanger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
