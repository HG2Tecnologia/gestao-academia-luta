import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';

class _PhoneMaskFormatter extends TextInputFormatter {
  static final _onlyDigits = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final raw = next.text.replaceAll(_onlyDigits, '');
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
    return next.copyWith(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  final _nomeAcademiaCtrl = TextEditingController();
  final _subdominioCtrl = TextEditingController();

  bool _loading = false;
  bool _obscureSenha = true;
  bool _obscureConfirmar = true;
  String? _erro;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    _nomeAcademiaCtrl.dispose();
    _subdominioCtrl.dispose();
    super.dispose();
  }

  String _gerarSubdominio(String nome) {
    return nome
        .toLowerCase()
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _erro = null; });

    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;

    try {
      // 1. Criar academia + usuário no backend
      final res = await dio.post('/api/auth/register', data: {
        'nome': _nomeCtrl.text.trim(),
        'email': email,
        'senha': senha,
        'nomeAcademia': _nomeAcademiaCtrl.text.trim(),
        'subdominio': _subdominioCtrl.text.trim(),
        if (_telefoneCtrl.text.trim().isNotEmpty) 'telefone': _telefoneCtrl.text.trim(),
      });

      final body = res.data as Map<String, dynamic>;
      if (body['sucesso'] != true) {
        setState(() => _erro = body['mensagem'] ?? 'Erro ao criar conta.');
        return;
      }

      // 2. Criar usuário no Firebase com o mesmo email/senha
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: senha,
        );
      } on FirebaseAuthException catch (e) {
        // Se já existe no Firebase (conta anterior), tenta só logar
        if (e.code != 'email-already-in-use') rethrow;
      }

      // 3. Salvar sessão com o JWT retornado pelo backend
      final d = body['dados'] as Map<String, dynamic>;
      final token = d['accessToken'] as String? ?? '';
      final refreshToken = d['refreshToken'] as String?;
      if (token.isNotEmpty) {
        final id = AuthStorage.subFromJwt(token) ?? '';
        await AuthStorage.save(
          token,
          StoredUser(
            id: id,
            nome: d['nome'] ?? _nomeCtrl.text.trim(),
            email: d['email'] ?? email,
            perfil: d['perfil'] ?? 'Admin',
            academiaId: d['academiaId']?.toString(),
          ),
          refreshToken: refreshToken,
        );
        if (mounted) context.go('/admin/dashboard');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Conta criada! Faça login para continuar.'),
              backgroundColor: kSuccess,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/login');
        }
      }
    } on DioException catch (e) {
      setState(() => _erro = e.response?.data?['mensagem'] ?? 'Erro de conexão. Verifique sua internet.');
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = 'Conta criada, mas houve um problema ao configurar o acesso (${e.code}). Faça login normalmente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Row(children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back, color: kText1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text('Criar conta', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Text('Configure sua academia em minutos', style: TextStyle(color: kText2, fontSize: 13)),
                ),
                const SizedBox(height: 28),

                _label('Sobre você'),
                const SizedBox(height: 8),
                _field(
                  controller: _nomeCtrl,
                  hint: 'Seu nome completo',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 10),
                _field(
                  controller: _emailCtrl,
                  hint: 'Seu e-mail',
                  icon: Icons.mail_outline_rounded,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Obrigatório';
                    if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _field(
                  controller: _telefoneCtrl,
                  hint: 'Telefone (opcional)',
                  icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  inputFormatters: [_PhoneMaskFormatter()],
                ),
                const SizedBox(height: 20),

                _label('Senha de acesso'),
                const SizedBox(height: 8),
                _fieldSenha(
                  controller: _senhaCtrl,
                  hint: 'Crie uma senha',
                  obscure: _obscureSenha,
                  onToggle: () => setState(() => _obscureSenha = !_obscureSenha),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obrigatório';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _fieldSenha(
                  controller: _confirmarCtrl,
                  hint: 'Confirme a senha',
                  obscure: _obscureConfirmar,
                  onToggle: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obrigatório';
                    if (v != _senhaCtrl.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _label('Sua academia'),
                const SizedBox(height: 8),
                _field(
                  controller: _nomeAcademiaCtrl,
                  hint: 'Nome da academia',
                  icon: Icons.sports_martial_arts_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  onChanged: (v) {
                    final sub = _gerarSubdominio(v);
                    _subdominioCtrl.text = sub;
                  },
                ),
                const SizedBox(height: 10),
                _field(
                  controller: _subdominioCtrl,
                  hint: 'Identificador único (ex: minha-academia)',
                  icon: Icons.link_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Obrigatório';
                    if (!RegExp(r'^[a-z0-9\-]{3,}$').hasMatch(v.trim())) {
                      return 'Use apenas letras minúsculas, números e hífens (mín. 3 caracteres)';
                    }
                    return null;
                  },
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Este identificador é usado para acessar o sistema web',
                    style: TextStyle(color: kText2, fontSize: 11),
                  ),
                ),

                if (_erro != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kDanger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_erro!, style: TextStyle(color: kDanger, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _cadastrar,
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Criar minha academia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text('Já tenho conta · Entrar', style: TextStyle(color: kText2, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: onChanged,
        style: TextStyle(color: kText1, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: kText2),
          prefixIcon: Icon(icon, color: kText2, size: 20),
          filled: true,
          fillColor: kSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
        ),
      );

  Widget _fieldSenha({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: TextStyle(color: kText1, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: kText2),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: kText2, size: 20),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: kText2, size: 20),
          ),
          filled: true,
          fillColor: kSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
        ),
      );
}
