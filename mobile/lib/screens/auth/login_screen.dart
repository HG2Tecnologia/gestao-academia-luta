import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';

class _SmartInputFormatter extends TextInputFormatter {
  static final _onlyDigits = RegExp(r'\D');
  static final _hasLetter = RegExp(r'[a-zA-Z@]');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final text = next.text;
    if (text.isEmpty) return next;
    if (_hasLetter.hasMatch(text)) return next;

    final raw = text.replaceAll(_onlyDigits, '');
    final digits = raw.length > 11 ? raw.substring(0, 11) : raw;

    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (digits.length == 11 && i == 7) buf.write('-');
      if (digits.length <= 10 && i == 6) buf.write('-');
      buf.write(digits[i]);
    }

    final formatted = buf.toString();
    return next.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

enum _InputMode { indefinido, email, telefone }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;
  _InputMode _mode = _InputMode.indefinido;

  static const _loadingMsgs = [
    'Autenticando...',
    'Carregando seus dados...',
    'Quase lá...',
  ];
  int _loadingMsgIdx = 0;
  Timer? _loadingTimer;

  static final _emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  void _onIdChanged(String v) {
    if (v.isEmpty) {
      if (_mode != _InputMode.indefinido) setState(() => _mode = _InputMode.indefinido);
      return;
    }
    final hasLetter = RegExp(r'[a-zA-Z@]').hasMatch(v);
    final newMode = hasLetter ? _InputMode.email : _InputMode.telefone;
    if (newMode != _mode) setState(() => _mode = newMode);
  }

  String? _validarId() {
    final v = _idCtrl.text.trim();
    if (v.isEmpty) return 'Informe seu e-mail ou telefone.';
    if (_mode == _InputMode.email) {
      if (!_emailRegex.hasMatch(v)) return 'E-mail inválido.';
    } else if (_mode == _InputMode.telefone) {
      final digits = v.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 10) return 'Telefone inválido. Ex: (11) 99999-0000';
    }
    return null;
  }

  Future<void> _login() async {
    final erroId = _validarId();
    if (erroId != null) { setState(() => _erro = erroId); return; }
    if (_senhaCtrl.text.isEmpty) { setState(() => _erro = 'Informe sua senha.'); return; }

    setState(() { _loading = true; _erro = null; _loadingMsgIdx = 0; });
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) setState(() => _loadingMsgIdx = (_loadingMsgIdx + 1) % _loadingMsgs.length);
    });

    try {
      // Usuários cadastrados só com telefone usam email sintético no Firebase Auth
      final String email;
      if (_mode == _InputMode.telefone) {
        final digits = _idCtrl.text.replaceAll(RegExp(r'\D'), '');
        email = '$digits@sensei.app';
      } else {
        email = _idCtrl.text.trim();
      }
      final senha = _senhaCtrl.text;

      // 1. Autenticar com Firebase (sem backend, instantâneo)
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: senha)
          .timeout(const Duration(seconds: 15));

      final uid = credential.user!.uid;

      // 2. Buscar dados do usuário no Firestore (sem backend, sem cold start)
      final userData = await firestoreService.getUserByFirebaseUid(uid);
      if (userData == null) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() => _erro = 'Usuário não encontrado no sistema. Contate o administrador.');
        return;
      }

      // Verifica bloqueios de acesso (aluno inativo, acesso suspenso, mensalidade)
      if ((userData['perfil'] as String?) == 'Aluno') {
        final alunoId = userData['usuarioId'] as String?;
        final academiaId = userData['academiaId'] as String?;
        if (alunoId != null && academiaId != null) {
          final alunoDoc = await firestoreService.getUsuario(academiaId, alunoId);
          if (alunoDoc != null) {
            if (alunoDoc['ativo'] == false) {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              setState(() => _erro = 'Seu cadastro está inativo. Entre em contato com a secretaria.');
              return;
            }
            if (alunoDoc['acesso_app_bloqueado'] == true) {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              setState(() => _erro = 'Seu acesso ao app está suspenso. Entre em contato com a secretaria.');
              return;
            }
            // Verifica bloqueio por mensalidade vencida (respeita config da academia)
            final motivoMensalidade = await firestoreService.motivoBloqueioCheckin(academiaId, alunoId);
            if (motivoMensalidade != null) {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              setState(() => _erro = 'Acesso bloqueado: mensalidade vencida. Regularize seu pagamento e tente novamente.');
              return;
            }
          }
        }
      }

      // Extrai permissões (para professor/secretaria)
      final rawPerm = userData['permissoes'];
      final permissoes = rawPerm is Map
          ? Map<String, bool>.from(rawPerm.map((k, v) => MapEntry(k.toString(), v == true)))
          : <String, bool>{};

      // Múltiplos perfis (grupo familiar de alunos)
      final rawPerfis = userData['perfis'];
      final perfisLista = rawPerfis is List
          ? rawPerfis.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      // Se há múltiplos perfis, mostrar seletor
      String usuarioId = userData['usuarioId'] as String? ?? uid;
      String perfilNome = userData['perfil'] as String? ?? 'Aluno';
      String? academiaId = userData['academiaId'] as String?;
      String nomeUsuario = userData['nome'] as String? ?? '';

      if (perfisLista.length > 1 && mounted) {
        final selecionado = await _mostrarSeletorPerfil(perfisLista);
        if (!mounted) return;
        if (selecionado != null) {
          usuarioId = selecionado['usuarioId'] as String? ?? usuarioId;
          nomeUsuario = selecionado['nome'] as String? ?? nomeUsuario;
          academiaId = selecionado['academiaId'] as String? ?? academiaId;
        }
      }

      // 3. Salvar dados localmente
      await AuthStorage.save(
        uid,
        StoredUser(
          id: usuarioId,
          nome: nomeUsuario,
          email: userData['email'] as String? ?? email,
          perfil: perfilNome,
          academiaId: academiaId,
          permissoes: permissoes,
          perfis: perfisLista,
        ),
      );

      if (!mounted) return;

      // 4. Navegar conforme perfil
      switch (perfilNome) {
        case 'Admin':
        case 'Secretaria':
          context.go('/admin/dashboard');
        case 'Professor':
          context.go('/professor/turmas');
        case 'Aluno':
          context.go('/aluno/perfil');
        default:
          context.go('/login');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _erro = _mensagemFirebase(e.code));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final code = e.code;
      if (code == 'unavailable' || code == 'failed-precondition') {
        setState(() => _erro = 'Banco de dados ainda não configurado. Contate o administrador.');
      } else if (code == 'permission-denied') {
        setState(() => _erro = 'Sem permissão para acessar os dados. Contate o administrador.');
      } else {
        setState(() => _erro = 'Erro Firebase ($code): ${e.message}');
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _erro = 'Tempo esgotado. Verifique sua conexão e tente novamente.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = 'Erro inesperado: $e');
    } finally {
      _loadingTimer?.cancel();
      _loadingTimer = null;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>?> _mostrarSeletorPerfil(List<Map<String, dynamic>> perfis) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(children: [
                Icon(Icons.group_rounded, color: kPrimary, size: 22),
                const SizedBox(width: 10),
                Text('Qual perfil deseja acessar?', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
            ),
            const Divider(height: 1),
            for (final p in perfis)
              ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: kPrimary,
                  child: Text(
                    (p['nome'] as String? ?? '').split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                title: Text(p['nome'] as String? ?? '', style: TextStyle(color: kText1, fontWeight: FontWeight.w600)),
                trailing: Icon(Icons.arrow_forward_ios_rounded, color: kText2, size: 14),
                onTap: () => Navigator.of(ctx).pop(p),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _mensagemFirebase(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos. Se nunca acessou pelo app, use "Esqueci minha senha" para definir sua senha.';
      case 'user-disabled':
        return 'Esta conta está desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro ao autenticar. Verifique seus dados e tente novamente.';
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _idCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = _mode == _InputMode.telefone;
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset('assets/logo_app.png', width: 72, height: 72),
                ),
                const SizedBox(height: 14),
                const Text(
                  'SENSEI MANAGER',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Acesse sua academia',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kText2, fontSize: 13),
                ),
                const SizedBox(height: 40),
                Text('E-mail ou Telefone', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _idCtrl,
                  onChanged: _onIdChanged,
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [_SmartInputFormatter()],
                  style: TextStyle(color: kText1, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: isPhone ? '(11) 99999-0000' : 'seu@email.com',
                    hintStyle: TextStyle(color: kText2),
                    prefixIcon: Icon(
                      _mode == _InputMode.telefone
                          ? Icons.phone_outlined
                          : _mode == _InputMode.email
                              ? Icons.mail_outline
                              : Icons.person_outline,
                      color: kText2,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: kSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Senha', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _senhaCtrl,
                  obscureText: true,
                  style: TextStyle(color: kText1, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(color: kText2),
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
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _login,
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                if (_loading) ...[
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _loadingMsgs[_loadingMsgIdx],
                      key: ValueKey(_loadingMsgIdx),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kText2, fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/primeiro-acesso'),
                      child: Text('Primeiro acesso', style: TextStyle(color: kPrimary, fontSize: 13)),
                    ),
                    Text('·', style: TextStyle(color: kText2)),
                    TextButton(
                      onPressed: () => context.push('/esqueci-senha'),
                      child: Text('Esqueci minha senha', style: TextStyle(color: kText2, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/cadastrar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimary,
                    side: BorderSide(color: kPrimary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Criar conta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
