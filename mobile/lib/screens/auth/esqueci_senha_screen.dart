import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firebase_identity_service.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';

class EsqueciSenhaScreen extends StatefulWidget {
  /// 'aluno' ou 'academia'; propagado de volta ao login ao concluir/voltar.
  final String? contexto;

  const EsqueciSenhaScreen({super.key, this.contexto});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _campoCtrl = TextEditingController();
  bool _loading = false;
  bool _enviado = false;
  String? _erro;

  static final _emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  bool get _ehAluno => widget.contexto == 'aluno';

  void _voltarLogin() {
    final contexto = widget.contexto;
    if (contexto != null) {
      context.go('/login', extra: {'contexto': contexto});
    } else {
      context.go('/boas-vindas');
    }
  }

  /// Fluxo do aluno/responsável: aceita telefone OU e-mail e vira uma
  /// solicitação que aparece no sino de notificações da academia (em vez de
  /// mandar e-mail, que nunca chega pra quem loga por telefone via e-mail
  /// sintético `@sensei.app`).
  Future<void> _enviarSolicitacao() async {
    final l = context.l10n;
    final identifier = _campoCtrl.text.trim();
    final digits = identifier.replaceAll(RegExp(r'\D'), '');
    final pareceEmail = identifier.contains('@');
    if (identifier.isEmpty ||
        (pareceEmail && !_emailRegex.hasMatch(identifier.toLowerCase())) ||
        (!pareceEmail && digits.length < 10)) {
      setState(() => _erro = l.fpErrInvalidIdentifier);
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await firebaseIdentityService.requestPasswordReset(
        identifier: pareceEmail ? identifier.toLowerCase() : digits,
      );
      if (mounted) {
        setState(() {
          _enviado = true;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro = l.fpErrUnexpected;
          _loading = false;
        });
      }
    }
  }

  /// Fluxo de academia/funcionário: mantido como sempre foi (link por e-mail
  /// via Firebase Auth) — esse público usa e-mail real com mais frequência e
  /// não faz parte do pedido de solicitação-pela-academia.
  Future<void> _enviarLinkEmail() async {
    final l = context.l10n;
    final email = _campoCtrl.text.trim().toLowerCase();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _erro = l.fpErrInvalidEmail);
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await FirebaseAuth.instance.setLanguageCode('pt-BR');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() {
          _enviado = true;
          _loading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          // Por segurança, não revelamos se o email existe
          if (mounted) {
            setState(() {
              _enviado = true;
              _loading = false;
            });
          }
          return;
        case 'invalid-email':
          msg = l.fpErrInvalidEmail;
        case 'too-many-requests':
          msg = l.fpErrTooManyRequests;
        default:
          msg = l.fpErrGeneric;
      }
      if (mounted) {
        setState(() {
          _erro = msg;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro = l.fpErrUnexpected;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _campoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surface,
        foregroundColor: context.c.onSurface,
        title: Text(l.fpTitle),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _voltarLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _enviado ? _buildSucesso(l) : _buildForm(l),
        ),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          l.fpHeading,
          style: TextStyle(
            color: context.c.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _ehAluno ? l.fpAlunoSubtitle : l.fpSubtitle,
          style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 32),
        Text(
          _ehAluno ? l.fpIdentifierLabel : l.fpEmailLabel,
          style: TextStyle(
            color: context.c.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _campoCtrl,
          keyboardType: _ehAluno
              ? TextInputType.text
              : TextInputType.emailAddress,
          inputFormatters: _ehAluno
              ? [SmartPhoneOrEmailInputFormatter()]
              : null,
          autofocus: true,
          style: TextStyle(color: context.c.onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: _ehAluno ? l.fpIdentifierHint : l.fpEmailHint,
            hintStyle: TextStyle(color: context.c.onSurfaceVariant),
            prefixIcon: Icon(
              _ehAluno ? Icons.person_outline : Icons.mail_outline,
              color: context.c.onSurfaceVariant,
              size: 20,
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
          ),
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
              style: TextStyle(color: context.sem.danger, fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _loading
              ? null
              : (_ehAluno ? _enviarSolicitacao : _enviarLinkEmail),
          style: FilledButton.styleFrom(
            backgroundColor: context.c.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _ehAluno ? l.fpAlunoSendButton : l.fpSendButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSucesso(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.sem.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _ehAluno
                  ? Icons.notifications_active_outlined
                  : Icons.mark_email_read_outlined,
              color: context.sem.success,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          _ehAluno ? l.fpRequestSentTitle : l.fpSentTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.c.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _ehAluno ? l.fpRequestSentBody : l.fpSentBody,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.c.onSurfaceVariant,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        FilledButton(
          onPressed: _voltarLogin,
          style: FilledButton.styleFrom(
            backgroundColor: context.c.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            l.fpBackToLogin,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
