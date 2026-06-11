import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';

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

  String _rawPhone() => _idCtrl.text.replaceAll(RegExp(r'\D'), '');

  String? _validarId() {
    final v = _idCtrl.text.trim();
    if (v.isEmpty) return 'Informe seu e-mail ou telefone.';
    if (_mode == _InputMode.email) {
      if (!_emailRegex.hasMatch(v)) return 'E-mail inválido.';
    } else if (_mode == _InputMode.telefone) {
      final digits = _rawPhone();
      if (digits.length < 10 || digits.length > 11) return 'Telefone inválido. Use DDD + número.';
    }
    return null;
  }

  Future<void> _login() async {
    final erroId = _validarId();
    if (erroId != null) { setState(() => _erro = erroId); return; }
    if (_senhaCtrl.text.isEmpty) { setState(() => _erro = 'Informe sua senha.'); return; }

    setState(() { _loading = true; _erro = null; });
    try {
      final payload = _mode == _InputMode.telefone ? _rawPhone() : _idCtrl.text.trim();
      final res = await dio.post('/api/auth/login', data: {
        'emailOuTelefone': payload,
        'senha': _senhaCtrl.text,
      });
      final body = res.data as Map<String, dynamic>;
      if (body['sucesso'] == true) {
        final d = body['dados'] as Map<String, dynamic>;
        final token = d['accessToken'] as String;
        final refreshToken = d['refreshToken'] as String?;
        final id = AuthStorage.subFromJwt(token) ?? '';
        await AuthStorage.save(
          token,
          StoredUser(
            id: id,
            nome: d['nome'] ?? '',
            email: d['email'] ?? '',
            perfil: d['perfil'] ?? '',
            academiaId: d['academiaId']?.toString(),
          ),
          refreshToken: refreshToken,
        );
        if (!mounted) return;
        switch (d['perfil']) {
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
      } else {
        setState(() => _erro = body['mensagem'] ?? 'Credenciais inválidas.');
      }
    } on DioException catch (e) {
      final isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError;
      setState(() => _erro = isTimeout
          ? 'Servidor iniciando. Aguarde alguns segundos e tente novamente.'
          : (e.response?.data?['mensagem'] ?? 'Não foi possível conectar ao servidor. Verifique sua internet.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
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
                Text('E-mail ou telefone',
                    style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _idCtrl,
                  onChanged: _onIdChanged,
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [_SmartInputFormatter()],
                  style: TextStyle(color: kText1, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: isPhone ? '(11) 99999-0000' : 'seu@email.com ou telefone',
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
                  child: const Text('Criar minha academia grátis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
