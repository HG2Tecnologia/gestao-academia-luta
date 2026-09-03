import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';

class EsqueciSenhaScreen extends StatefulWidget {
  /// 'aluno' ou 'academia'; propagado de volta ao login ao concluir/voltar.
  final String? contexto;

  const EsqueciSenhaScreen({super.key, this.contexto});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _enviado = false;
  String? _erro;

  static final _emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  void _voltarLogin() {
    final contexto = widget.contexto;
    if (contexto != null) {
      context.go('/login', extra: {'contexto': contexto});
    } else {
      context.go('/boas-vindas');
    }
  }

  Future<void> _enviar() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _erro = 'Informe um e-mail válido.');
      return;
    }
    setState(() { _loading = true; _erro = null; });
    try {
      await FirebaseAuth.instance.setLanguageCode('pt-BR');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() { _enviado = true; _loading = false; });
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          // Por segurança, não revelamos se o email existe
          if (mounted) setState(() { _enviado = true; _loading = false; });
          return;
        case 'invalid-email':
          msg = 'E-mail inválido.';
        case 'too-many-requests':
          msg = 'Muitas tentativas. Aguarde alguns minutos.';
        default:
          msg = 'Erro ao enviar e-mail. Tente novamente.';
      }
      if (mounted) setState(() { _erro = msg; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _erro = 'Erro inesperado. Tente novamente.'; _loading = false; });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        foregroundColor: kText1,
        title: const Text('Esqueci minha senha'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _voltarLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _enviado ? _buildSucesso() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text('Recuperar acesso',
            style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Informe seu e-mail e enviaremos um link para você criar uma nova senha.',
          style: TextStyle(color: kText2, fontSize: 14),
        ),
        const SizedBox(height: 32),
        Text('E-mail', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          style: TextStyle(color: kText1, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'seu@email.com',
            hintStyle: TextStyle(color: kText2),
            prefixIcon: Icon(Icons.mail_outline, color: kText2, size: 20),
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
          ),
        ),
        if (_erro != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kDanger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_erro!, style: TextStyle(color: kDanger, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _loading ? null : _enviar,
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Enviar link de recuperação', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildSucesso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kSuccess.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mark_email_read_outlined, color: kSuccess, size: 48),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'E-mail enviado!',
          textAlign: TextAlign.center,
          style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Verifique sua caixa de entrada (e spam). Clique no link recebido para criar sua nova senha.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kText2, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 40),
        FilledButton(
          onPressed: _voltarLogin,
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Voltar ao login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
