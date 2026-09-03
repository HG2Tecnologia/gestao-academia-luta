import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';
import '../notificacoes_screen.dart';

class ProfPerfilScreen extends StatefulWidget {
  const ProfPerfilScreen({super.key});

  @override
  State<ProfPerfilScreen> createState() => _ProfPerfilScreenState();
}

class _ProfPerfilScreenState extends State<ProfPerfilScreen> {
  final _nomeCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _academiaId;
  String? _userId;
  bool _isFuncionario = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await AuthStorage.getUser();
      if (user != null) {
        _academiaId = user.academiaId;
        _userId = user.id;
        // Professores, secretaria e admin ficam em 'funcionarios'; alunos em 'usuarios'
        _isFuncionario = user.perfil == 'Professor' ||
            user.perfil == 'Admin' ||
            user.perfil == 'Secretaria';
        _nomeCtrl.text = user.nome;
        if (user.academiaId != null) {
          try {
            final Map<String, dynamic>? dados;
            if (_isFuncionario) {
              dados = await firestoreService.getFuncionario(user.academiaId!, user.id);
            } else {
              dados = await firestoreService.getUsuario(user.academiaId!, user.id);
            }
            if (dados != null) {
              _nomeCtrl.text = dados['nome'] as String? ?? user.nome;
              _telCtrl.text = dados['telefone'] as String? ?? '';
            }
          } catch (_) {}
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      if (_academiaId != null && _userId != null) {
        final data = {
          'nome': _nomeCtrl.text.trim(),
          'telefone': _telCtrl.text.trim(),
        };
        if (_isFuncionario) {
          await firestoreService.updateFuncionario(_academiaId!, _userId!, data);
        } else {
          await firestoreService.updateUsuario(_academiaId!, _userId!, data);
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sair() async {
    await AuthStorage.clear();
    if (mounted) context.go('/boas-vindas');
  }

  Future<void> _excluirConta(BuildContext context) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Excluir conta?', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Text('Seus dados pessoais serão removidos permanentemente. Esta ação não pode ser desfeita.', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Excluir', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    // Clear local storage and go to login (no server deletion call in Firestore flow)
    await AuthStorage.clear();
    if (mounted) context.go('/boas-vindas');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: kPrimary))
            : RefreshIndicator(
                onRefresh: _load,
                color: kPrimary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(children: [
                      GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
                      const SizedBox(width: 14),
                      Expanded(child: Text('Meu Perfil', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800))),
                      const SinoNotificacoes(),
                    ]),
                    const SizedBox(height: 28),
                    _label('Nome'),
                    _input(_nomeCtrl, 'Seu nome'),
                    const SizedBox(height: 16),
                    _label('Telefone'),
                    _input(_telCtrl, '(00) 00000-0000', keyboard: TextInputType.phone),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _saving ? null : _salvar,
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : const Text('Salvar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => context.push('/noticias'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.newspaper_rounded, color: const Color(0xFFC9A020), size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Notícias da Academia', style: TextStyle(color: kText1, fontWeight: FontWeight.w600))),
                            Icon(Icons.chevron_right, color: kText2, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/alterar-senha'),
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      label: const Text('Alterar Senha', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kText1,
                        side: BorderSide(color: kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _sair,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kDanger,
                        side: BorderSide(color: kDanger.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Sair', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _excluirConta(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kDanger,
                        side: BorderSide(color: kDanger.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Excluir minha conta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _input(TextEditingController c, String hint, {TextInputType keyboard = TextInputType.text}) => TextField(
        controller: c,
        keyboardType: keyboard,
        style: TextStyle(color: kText1, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: kText2),
          filled: true,
          fillColor: kSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
        ),
      );
}
