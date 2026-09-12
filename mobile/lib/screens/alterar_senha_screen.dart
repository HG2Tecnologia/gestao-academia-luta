import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/context_ext.dart';
import '../l10n/app_localizations.dart';

class AlterarSenhaScreen extends StatefulWidget {
  const AlterarSenhaScreen({super.key});

  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _atualCtrl = TextEditingController();
  final _novaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  bool _salvando = false;
  bool _ocultarAtual = true;
  bool _ocultarNova = true;
  bool _ocultarConfirmar = true;

  @override
  void dispose() {
    _atualCtrl.dispose();
    _novaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final l = context.l10n;
    setState(() => _salvando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null)
        throw Exception('Não autenticado');

      // Reautentica com a senha atual antes de alterar
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _atualCtrl.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_novaCtrl.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.changePwSuccess),
          backgroundColor: context.sem.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          msg = l.changePwErrWrongCurrent;
        case 'weak-password':
          msg = l.changePwErrWeak;
        default:
          msg = l.changePwErrGeneric;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surface,
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
          l.changePwTitle,
          style: TextStyle(
            color: context.c.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.c.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.c.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: context.c.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.changePwHint,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _label(context, l.changePwCurrentLabel),
              const SizedBox(height: 6),
              _SenhaField(
                controller: _atualCtrl,
                hint: l.changePwCurrentHint,
                ocultar: _ocultarAtual,
                onToggle: () => setState(() => _ocultarAtual = !_ocultarAtual),
                validator: (v) {
                  if (v == null || v.isEmpty) return l.commonRequiredField;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _label(context, l.changePwNewLabel),
              const SizedBox(height: 6),
              _SenhaField(
                controller: _novaCtrl,
                hint: l.changePwNewHint,
                ocultar: _ocultarNova,
                onToggle: () => setState(() => _ocultarNova = !_ocultarNova),
                validator: (v) {
                  if (v == null || v.isEmpty) return l.commonRequiredField;
                  if (v.length < 6) return l.changePwErrMinLength;
                  if (v == _atualCtrl.text) return l.changePwMustBeDifferent;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _label(context, l.changePwConfirmLabel),
              const SizedBox(height: 6),
              _SenhaField(
                controller: _confirmarCtrl,
                hint: l.changePwConfirmHint,
                ocultar: _ocultarConfirmar,
                onToggle: () =>
                    setState(() => _ocultarConfirmar = !_ocultarConfirmar),
                validator: (v) {
                  if (v == null || v.isEmpty) return l.commonRequiredField;
                  if (v != _novaCtrl.text) return l.changePwErrMismatch;
                  return null;
                },
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.c.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l.changePwTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String t) => Text(
    t,
    style: TextStyle(
      color: context.c.onSurfaceVariant,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
  );
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
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: ocultar,
      validator: validator,
      style: TextStyle(color: context.c.onSurface, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: context.c.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.lock_rounded,
          color: context.c.onSurfaceVariant,
          size: 18,
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
