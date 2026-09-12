import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/firebase_identity_service.dart';
import '../../core/theme/context_ext.dart';

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
    final l = context.l10n;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(l.tsoErrSessionExpired);

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
          context.go('/aluno/inicio');
        default:
          context.go('/boas-vindas');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.code == 'requires-recent-login'
            ? l.tsoErrRequiresRecentLogin
            : l.tsoErrGeneric(e.code);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = l.tsoErrUnexpected);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.c.surface,
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
                        color: context.c.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: context.c.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l.tsoTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.tsoSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SenhaField(
                      controller: _novaCtrl,
                      hint: l.tsoNewPasswordHint,
                      ocultar: _ocultarNova,
                      onToggle: () =>
                          setState(() => _ocultarNova = !_ocultarNova),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return l.commonRequiredField;
                        if (v.length < 6) return l.commonMinChars(6);
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _SenhaField(
                      controller: _confirmarCtrl,
                      hint: l.tsoConfirmPasswordHint,
                      ocultar: _ocultarConfirmar,
                      onToggle: () => setState(
                        () => _ocultarConfirmar = !_ocultarConfirmar,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return l.commonRequiredField;
                        if (v != _novaCtrl.text)
                          return l.commonPasswordsDontMatch;
                        return null;
                      },
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.sem.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _erro!,
                          style: TextStyle(
                            color: context.sem.danger,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _salvando ? null : _concluir,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.c.primary,
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
                          : Text(
                              l.tsoConfirmButton,
                              style: const TextStyle(
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
      style: TextStyle(color: context.c.onSurface, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.c.onSurfaceVariant),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: context.c.onSurfaceVariant,
          size: 20,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            ocultar ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: context.c.onSurfaceVariant,
            size: 18,
          ),
        ),
        filled: true,
        fillColor: context.c.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          borderSide: BorderSide(color: context.c.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.sem.danger),
        ),
      ),
    );
  }
}
