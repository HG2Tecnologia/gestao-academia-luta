import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firebase_identity_service.dart';

/// Exibida quando um Admin/Secretaria redefiniu a senha desta conta
/// (`must_change_password == true`). Bloqueia a navegação — sem botão de
/// voltar, sem gesto de swipe — até a pessoa definir uma senha definitiva.
class TrocaSenhaObrigatoriaScreen extends StatefulWidget {
  const TrocaSenhaObrigatoriaScreen({super.key});

  @override
  State<TrocaSenhaObrigatoriaScreen> createState() =>
      _TrocaSenhaObrigatoriaScreenState();
}

class _TrocaSenhaObrigatoriaScreenState
    extends State<TrocaSenhaObrigatoriaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _novaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _ocultarNova = true;
  bool _ocultarConfirmar = true;
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _novaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _concluir() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Sessão expirada.');

      await user.updatePassword(_novaCtrl.text);
      await firebaseIdentityService.completeMandatoryPasswordChange();

      final stored = await AuthStorage.getUser();
      if (stored != null) {
        await AuthStorage.saveUser(
          StoredUser(
            id: stored.id,
            nome: stored.nome,
            email: stored.email,
            perfil: stored.perfil,
            academiaId: stored.academiaId,
            permissoes: stored.permissoes,
            perfis: stored.perfis,
            mustChangePassword: false,
          ),
        );
      }

      if (!mounted) return;
      switch (stored?.perfil) {
        case 'Admin':
        case 'Secretaria':
          context.go('/admin/dashboard');
        case 'Professor':
          context.go('/professor/dashboard');
        case 'Aluno':
          context.go('/aluno/perfil');
        default:
          context.go('/boas-vindas');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.code == 'requires-recent-login'
            ? 'Por segurança, saia e entre de novo com a senha temporária antes de trocá-la.'
            : 'Erro ao definir a nova senha (${e.code}).';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: kPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Defina sua senha definitiva',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kText1,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sua academia gerou uma senha temporária para você. '
                      'Antes de continuar, defina uma senha definitiva que só você conhece.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kText2, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    _SenhaField(
                      controller: _novaCtrl,
                      hint: 'Nova senha',
                      ocultar: _ocultarNova,
                      onToggle: () => setState(() => _ocultarNova = !_ocultarNova),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obrigatório';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _SenhaField(
                      controller: _confirmarCtrl,
                      hint: 'Confirme a nova senha',
                      ocultar: _ocultarConfirmar,
                      onToggle: () =>
                          setState(() => _ocultarConfirmar = !_ocultarConfirmar),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obrigatório';
                        if (v != _novaCtrl.text) return 'As senhas não coincidem';
                        return null;
                      },
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kDanger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _erro!,
                          style: TextStyle(color: kDanger, fontSize: 13),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _salvando ? null : _concluir,
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Salvar e continuar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SenhaField extends StatelessWidget {
  const _SenhaField({
    required this.controller,
    required this.hint,
    required this.ocultar,
    required this.onToggle,
    required this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final bool ocultar;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: ocultar,
      validator: validator,
      style: TextStyle(color: kText1, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: kText2),
        prefixIcon: Icon(Icons.lock_outline_rounded, color: kText2, size: 20),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            ocultar ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: kText2,
            size: 18,
          ),
        ),
        filled: true,
        fillColor: kSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: BorderSide(color: kPrimary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kDanger),
        ),
      ),
    );
  }
}
