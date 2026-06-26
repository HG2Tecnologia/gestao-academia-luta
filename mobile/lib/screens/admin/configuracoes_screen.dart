import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/paywall_modal.dart';
import '../../core/plan_service.dart';
import 'modalidades_screen.dart';

class AdminConfiguracoesScreen extends StatefulWidget {
  const AdminConfiguracoesScreen({super.key});

  @override
  State<AdminConfiguracoesScreen> createState() => _AdminConfiguracoesScreenState();
}

class _AdminConfiguracoesScreenState extends State<AdminConfiguracoesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();

  bool _loading = true;
  bool _salvando = false;
  bool _erro = false;
  String _subdominio = '';
  String? _logoBase64;
  bool _uploadandoLogo = false;

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
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _erro = false; });
    try {
      final res = await dio.get('/api/academia');
      final dados = res.data['dados'] as Map<String, dynamic>? ?? {};
      _nomeCtrl.text = dados['nome'] as String? ?? '';
      _emailCtrl.text = dados['email'] as String? ?? '';
      _telefoneCtrl.text = dados['telefone'] as String? ?? '';
      _cnpjCtrl.text = dados['cnpj'] as String? ?? '';
      _subdominio = dados['subdominio'] as String? ?? '';
      _logoBase64 = dados['logoUrl'] as String?;
      if (mounted) setState(() { _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _erro = true; _loading = false; });
    }
  }

  Future<void> _escolherLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    final bytes = result.files.single.bytes!;
    final ext = (result.files.single.extension ?? 'jpg').toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    setState(() => _logoBase64 = 'data:$mime;base64,${base64Encode(bytes)}');
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _salvando = true; });
    try {
      await dio.put('/api/academia', data: {
        'nome': _nomeCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'telefone': _telefoneCtrl.text.trim().isEmpty ? null : _telefoneCtrl.text.trim(),
        'cnpj': _cnpjCtrl.text.trim().isEmpty ? null : _cnpjCtrl.text.trim(),
        'logoUrl': _logoBase64,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configurações salvas com sucesso!'),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      String msg = 'Erro ao salvar configurações';
      try {
        final data = (e as dynamic).response?.data;
        if (data is Map && data['mensagem'] != null) msg = data['mensagem'].toString();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() { _salvando = false; });
    }
  }

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
        title: Text('Configurações da Academia', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          if (!_loading && !_erro)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _salvando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: _salvar,
                      style: TextButton.styleFrom(
                        backgroundColor: kPrimary.withOpacity(0.12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Salvar', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
                    ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, color: kDanger, size: 52),
                      const SizedBox(height: 14),
                      Text('Não foi possível carregar', style: TextStyle(color: kText2)),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tentar novamente'),
                        style: OutlinedButton.styleFrom(foregroundColor: kPrimary),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PlanStatusTile(),
                        const SizedBox(height: 24),
                        _SectionLabel('Logo da Academia'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _uploadandoLogo ? null : _escolherLogo,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _logoBase64 != null && _logoBase64!.startsWith('data:')
                                    ? Image.memory(
                                        base64Decode(_logoBase64!.split(',').last),
                                        width: 52, height: 52, fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 52, height: 52,
                                        decoration: BoxDecoration(
                                          color: kPrimary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.add_photo_alternate_rounded, color: kPrimary, size: 26),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  _logoBase64 != null ? 'Logo definida' : 'Adicionar logo',
                                  style: TextStyle(color: kText1, fontWeight: FontWeight.w700),
                                ),
                                Text('Toque para alterar a imagem', style: TextStyle(color: kText2, fontSize: 12)),
                              ])),
                              if (_logoBase64 != null)
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: kDanger, size: 20),
                                  tooltip: 'Remover logo',
                                  onPressed: () => setState(() => _logoBase64 = null),
                                ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Informações Gerais'),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _nomeCtrl,
                          label: 'Nome da Academia',
                          icon: Icons.sports_martial_arts_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _emailCtrl,
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
                          controller: _telefoneCtrl,
                          label: 'Telefone',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _cnpjCtrl,
                          label: 'CNPJ',
                          icon: Icons.business_rounded,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Graduações'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.push('/admin/dashboard/faixas'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: kWarning.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.military_tech_rounded, color: kWarning, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Gestão de Faixas', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
                                    Text('Cadastrar e editar graduações por modalidade',
                                        style: TextStyle(color: kText2, fontSize: 11)),
                                  ]),
                                ),
                                Icon(Icons.chevron_right_rounded, color: kText2),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminModalidadesScreen())),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.category_rounded, color: kPrimary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Gestão de Modalidades', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
                                    Text('Ativar, desativar ou criar modalidades da academia',
                                        style: TextStyle(color: kText2, fontSize: 11)),
                                  ]),
                                ),
                                Icon(Icons.chevron_right_rounded, color: kText2),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.push('/admin/dashboard/contratos'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.description_rounded, color: kPrimary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Modelos de Contrato', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
                                    Text('Criar e editar templates de contrato',
                                        style: TextStyle(color: kText2, fontSize: 11)),
                                  ]),
                                ),
                                Icon(Icons.chevron_right_rounded, color: kText2),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Comunicação'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.push('/admin/noticias'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.newspaper_rounded, color: Color(0xFF8B5CF6), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Notícias', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
                                    Text('Publicar notícias e comunicados para alunos e professores',
                                        style: TextStyle(color: kText2, fontSize: 11)),
                                  ]),
                                ),
                                Icon(Icons.chevron_right_rounded, color: kText2),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Informações do Sistema'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link_rounded, color: kText2, size: 18),
                              const SizedBox(width: 10),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Subdomínio', style: TextStyle(color: kText2, fontSize: 11)),
                                Text(_subdominio.isEmpty ? '—' : _subdominio,
                                    style: TextStyle(color: kText1, fontWeight: FontWeight.w600)),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Segurança'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.push('/alterar-senha'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: kDanger.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.lock_reset_rounded, color: kDanger, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Alterar Senha', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
                                    Text('Redefinir a senha de acesso ao sistema',
                                        style: TextStyle(color: kText2, fontSize: 11)),
                                  ]),
                                ),
                                Icon(Icons.chevron_right_rounded, color: kText2),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _salvando ? null : _salvar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _salvando
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Salvar Configurações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _SectionLabel('Legal'),
                        const SizedBox(height: 12),
                        _LegalTile(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Política de Privacidade',
                          subtitle: 'Como tratamos seus dados (LGPD)',
                          url: 'https://senseimanager.com.br/privacidade',
                        ),
                        const SizedBox(height: 8),
                        _LegalTile(
                          icon: Icons.gavel_rounded,
                          label: 'Termos de Uso',
                          subtitle: 'Condições de uso do Sensei Manager',
                          url: 'https://senseimanager.com.br/termos',
                        ),
                        const SizedBox(height: 32),
                        _SectionLabel('Conta'),
                        const SizedBox(height: 12),
                        _BotaoSair(),
                        const SizedBox(height: 16),
                        _SectionLabel('Zona de Perigo'),
                        const SizedBox(height: 12),
                        _BotaoExcluirConta(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({required this.icon, required this.label, required this.subtitle, required this.url});
  final IconData icon;
  final String label;
  final String subtitle;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
            Text(subtitle, style: TextStyle(color: kText2, fontSize: 11)),
          ])),
          Icon(Icons.open_in_new_rounded, color: kText2, size: 16),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w800,
        letterSpacing: 0.4));
  }
}

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
        title: Text('Sair', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Text('Deseja encerrar sua sessão?', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Sair', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    setState(() => _loading = true);
    try { await dio.post('/api/auth/logout'); } on DioException catch (_) {}
    await AuthStorage.clear();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _sair,
        icon: _loading
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kDanger))
            : Icon(Icons.logout_rounded, color: kDanger, size: 18),
        label: const Text('Sair da conta', style: TextStyle(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: kDanger,
          side: BorderSide(color: kDanger.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        title: Text('Excluir conta?', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Text(
          'Seus dados pessoais serão removidos permanentemente. Esta ação não pode ser desfeita.',
          style: TextStyle(color: kText2),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Excluir', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await dio.delete('/api/usuarios/me');
      await AuthStorage.clear();
      if (!mounted) return;
      context.go('/login');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao excluir conta. Tente novamente.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _loading ? null : _excluir,
        style: OutlinedButton.styleFrom(
          foregroundColor: kDanger,
          side: BorderSide(color: kDanger.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kDanger))
            : const Text('Excluir minha conta', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Plan status tile ────────────────────────────────────────────────────────

class _PlanStatusTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final plan = PlanService.instance;
    final isPro = plan.isPro;
    final isInTrial = plan.isInTrial;
    final days = plan.daysLeftInTrial;
    final displayName = plan.planDisplayName;

    final Color borderColor = isPro
        ? const Color(0xFF6C3FFF)
        : isInTrial
            ? const Color(0xFF6C3FFF)
            : kWarning;
    final Color iconColor = isPro ? const Color(0xFFFFD700) : isInTrial ? kPrimary : kWarning;
    final IconData icon = isPro
        ? Icons.workspace_premium_rounded
        : isInTrial
            ? Icons.hourglass_top_rounded
            : Icons.lock_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withOpacity(0.5)),
        gradient: isPro
            ? LinearGradient(
                colors: [const Color(0xFF1A0F3C), kSurface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(displayName,
              style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w800)),
          if (isPro)
            Text('Acesso completo sem anúncios', style: TextStyle(color: kText2, fontSize: 12))
          else if (isInTrial)
            Text(days <= 1 ? 'Último dia do trial!' : '$days dias restantes no trial',
                style: TextStyle(color: kText2, fontSize: 12))
          else
            Text('3 turmas · 10 alunos/turma · anúncios', style: TextStyle(color: kText2, fontSize: 12)),
        ])),
        if (!isPro) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final ok = await mostrarPaywall(context);
              if (ok == true) await PlanService.instance.refresh();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kPrimary, const Color(0xFF9B6DFF)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Assinar PRO',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ]),
    );
  }
}

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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
