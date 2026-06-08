import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';

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
      if (mounted) setState(() { _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _erro = true; _loading = false; });
    }
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w800,
        letterSpacing: 0.4));
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
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Excluir conta?', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Text(
          'Seus dados pessoais serão removidos permanentemente. Esta ação não pode ser desfeita.',
          style: TextStyle(color: kText2),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
