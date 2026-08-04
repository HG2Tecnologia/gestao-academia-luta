import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';

// ─── Formatter de telefone ────────────────────────────────────────────────────

class _PhoneFormatter extends TextInputFormatter {
  static final _onlyDigits = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final text = next.text;
    if (text.isEmpty) return next;
    if (RegExp(r'[a-zA-Z@]').hasMatch(text)) return next;

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

// ─── Etapas ───────────────────────────────────────────────────────────────────

enum _Etapa { busca, escolherPerfil, criaSenha, sucesso }

// ─── Tela ─────────────────────────────────────────────────────────────────────

class PrimeiroAcessoScreen extends StatefulWidget {
  const PrimeiroAcessoScreen({super.key});

  @override
  State<PrimeiroAcessoScreen> createState() => _PrimeiroAcessoScreenState();
}

class _PrimeiroAcessoScreenState extends State<PrimeiroAcessoScreen> {
  final _buscaCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  _Etapa _etapa = _Etapa.busca;
  bool _loading = false;
  String? _erro;
  bool _senhaVisivel = false;
  bool _confirmVisivel = false;

  List<Map<String, dynamic>> _todosUsuarios = [];
  Map<String, dynamic>? _usuarioSelecionado;

  static final _emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
  bool get _isEmail => _buscaCtrl.text.contains('@');

  Future<void> _buscar() async {
    final valor = _buscaCtrl.text.trim();
    if (valor.isEmpty) {
      setState(() => _erro = 'Informe seu e-mail ou telefone.');
      return;
    }
    if (_isEmail && !_emailRegex.hasMatch(valor)) {
      setState(() => _erro = 'E-mail inválido.');
      return;
    }
    final digits = valor.replaceAll(RegExp(r'\D'), '');
    if (!_isEmail && digits.length < 10) {
      setState(() => _erro = 'Telefone inválido. Ex: (11) 99999-0000');
      return;
    }

    setState(() { _loading = true; _erro = null; });
    try {
      // Login anônimo temporário: as regras do Firestore exigem autenticação
      // mesmo para a busca de cadastro. A sessão anônima é encerrada logo
      // após a busca; a conta real é criada em _criarConta().
      await FirebaseAuth.instance.signInAnonymously();
      final anon = FirebaseAuth.instance.currentUser;

      final usuarios = await firestoreService.buscarUsuariosPorEmailOuTelefone(valor);

      try {
        await anon?.delete();
      } catch (_) {
        await FirebaseAuth.instance.signOut();
      }

      if (!mounted) return;
      if (usuarios.isEmpty) {
        setState(() {
          _erro = 'Nenhum cadastro encontrado com esse ${_isEmail ? 'e-mail' : 'telefone'}.\n'
              'Verifique os dados ou contate o administrador da sua academia.';
          _loading = false;
        });
        return;
      }

      // Filtra cadastros inativos — aluno bloqueado não pode criar conta
      final ativos = usuarios.where((u) => u['ativo'] != false).toList();
      if (ativos.isEmpty) {
        setState(() {
          _erro = 'Seu cadastro está inativo. Entre em contato com a secretaria da sua academia.';
          _loading = false;
        });
        return;
      }

      _todosUsuarios = ativos;

      if (usuarios.length == 1) {
        // Apenas 1 perfil → pula seleção
        _usuarioSelecionado = usuarios.first;
        setState(() { _etapa = _Etapa.criaSenha; _loading = false; });
      } else {
        // Múltiplos perfis (grupo familiar ou professor + aluno)
        setState(() { _etapa = _Etapa.escolherPerfil; _loading = false; });
      }
    } catch (e) {
      await FirebaseAuth.instance.signOut().catchError((_) {});
      if (mounted) setState(() { _erro = 'Erro ao buscar cadastro: $e'; _loading = false; });
    }
  }

  Future<void> _criarConta() async {
    final senha = _senhaCtrl.text;
    final confirm = _confirmCtrl.text;

    if (senha.length < 6) {
      setState(() => _erro = 'A senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (senha != confirm) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }

    final usuario = _usuarioSelecionado!;
    var email = (usuario['email'] as String? ?? '').trim().toLowerCase();

    if (email.isEmpty) {
      // Cadastro sem e-mail: usa telefone como chave sintética no Firebase Auth
      final digits = (usuario['telefone'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) {
        setState(() => _erro = 'Seu cadastro não possui e-mail nem telefone. Contate o administrador.');
        return;
      }
      email = '$digits@sensei.app';
    }

    setState(() { _loading = true; _erro = null; });
    try {
      UserCredential credential;
      try {
        credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: senha);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          credential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: senha);
        } else {
          rethrow;
        }
      }

      final uid = credential.user!.uid;

      // Demais perfis com o mesmo e-mail (grupo familiar)
      final outrosPerfis = _todosUsuarios
          .where((u) => u['usuarioId'] != usuario['usuarioId'])
          .toList();

      await firestoreService.ativarContaUsuario(
        firebaseUid: uid,
        academiaId: usuario['academiaId'] as String,
        usuarioId: usuario['usuarioId'] as String,
        dadosUsuario: usuario,
        outrosPerfis: outrosPerfis.isNotEmpty ? outrosPerfis : null,
      );

      final perfilNome = usuario['perfil_nome'] as String? ?? 'Aluno';
      final dadosAtivados = await firestoreService.getUserByFirebaseUid(uid);
      final rawPermissoes = dadosAtivados?['permissoes'] ?? usuario['permissoes'];
      final permissoes = rawPermissoes is Map
          ? rawPermissoes.map<String, bool>((k, v) => MapEntry(k.toString(), v == true))
          : <String, bool>{};

      // Monta lista de perfis para armazenar localmente (grupo familiar)
      final perfisLocais = _todosUsuarios.map((u) => {
        'id': u['usuarioId'],
        'nome': u['nome'] ?? '',
        'academiaId': u['academiaId'],
        'colecao': u['_colecao'] ?? 'usuarios',
      }).toList();

      await AuthStorage.save(
        uid,
        StoredUser(
          id: usuario['usuarioId'] as String? ?? uid,
          nome: usuario['nome'] as String? ?? '',
          email: email,
          perfil: perfilNome,
          academiaId: usuario['academiaId'] as String?,
          permissoes: permissoes,
          perfis: perfisLocais.length > 1 ? perfisLocais : [],
        ),
      );

      if (!mounted) return;
      setState(() { _etapa = _Etapa.sucesso; _loading = false; });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Já existe uma conta com esse e-mail. Use "Esqueci minha senha" para recuperar o acesso.';
        case 'weak-password':
          msg = 'Senha muito fraca. Use pelo menos 6 caracteres.';
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Senha incorreta para essa conta existente. Use "Esqueci minha senha".';
        case 'network-request-failed':
          msg = 'Sem conexão com a internet.';
        default:
          msg = 'Erro ao criar conta (${e.code}). Tente novamente.';
      }
      setState(() { _erro = msg; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = 'Erro inesperado: $e'; _loading = false; });
    }
  }

  void _entrar() {
    final perfil = _usuarioSelecionado?['perfil_nome'] as String? ?? 'Aluno';
    switch (perfil) {
      case 'Admin':
      case 'Secretaria':
        context.go('/admin/dashboard');
      case 'Professor':
        context.go('/professor/turmas');
      default:
        context.go('/aluno/perfil');
    }
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        foregroundColor: kText1,
        title: const Text('Primeiro Acesso'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_etapa == _Etapa.criaSenha) {
              setState(() {
                _etapa = _todosUsuarios.length > 1 ? _Etapa.escolherPerfil : _Etapa.busca;
                _erro = null;
              });
            } else if (_etapa == _Etapa.escolherPerfil) {
              setState(() { _etapa = _Etapa.busca; _erro = null; });
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: switch (_etapa) {
            _Etapa.busca => _buildBusca(),
            _Etapa.escolherPerfil => _buildEscolherPerfil(),
            _Etapa.criaSenha => _buildCriaSenha(),
            _Etapa.sucesso => _buildSucesso(),
          },
        ),
      ),
    );
  }

  // ─── Etapa 1: busca ────────────────────────────────────────────────────────

  Widget _buildBusca() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text('Configurar acesso',
            style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Informe o e-mail ou telefone cadastrado pelo seu administrador.',
          style: TextStyle(color: kText2, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        Text('E-mail ou Telefone',
            style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _buscaCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          inputFormatters: [_PhoneFormatter()],
          onSubmitted: (_) => _loading ? null : _buscar(),
          style: TextStyle(color: kText1, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'seu@email.com  ou  (11) 99999-0000',
            hintStyle: TextStyle(color: kText2),
            prefixIcon: Icon(Icons.person_search_outlined, color: kText2, size: 20),
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
          _erroWidget(_erro!),
        ],
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _loading ? null : _buscar,
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Verificar cadastro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  // ─── Etapa 1b: escolher perfil (grupo familiar) ───────────────────────────

  Widget _buildEscolherPerfil() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimary.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(Icons.group_rounded, color: kPrimary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Encontramos ${_todosUsuarios.length} perfis com esse contato.\nQual é o seu?',
                style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        Text('Selecione seu perfil',
            style: TextStyle(color: kText1, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Se houver mais de um, escolha o seu nome.',
            style: TextStyle(color: kText2, fontSize: 13)),
        const SizedBox(height: 20),
        for (final u in _todosUsuarios) ...[
          _perfilTile(u),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _perfilTile(Map<String, dynamic> u) {
    final nome = u['nome'] as String? ?? '';
    final perfil = u['perfil_nome'] as String? ?? 'Aluno';
    final initials = nome.trim().split(RegExp(r'\s+')).take(2)
        .map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return GestureDetector(
      onTap: () {
        setState(() { _usuarioSelecionado = u; _etapa = _Etapa.criaSenha; _erro = null; });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: kPrimary,
            child: Text(initials.isEmpty ? '?' : initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nome, style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
            Text(perfil, style: TextStyle(color: kText2, fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: kText2, size: 16),
        ]),
      ),
    );
  }

  // ─── Etapa 2: criar senha ──────────────────────────────────────────────────

  Widget _buildCriaSenha() {
    final nome = _usuarioSelecionado?['nome'] as String? ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSuccess.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kSuccess.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: kSuccess, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Cadastro encontrado! Olá, $nome',
                    style: TextStyle(color: kSuccess, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Crie sua senha',
            style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Defina a senha que você usará para acessar o aplicativo.',
          style: TextStyle(color: kText2, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 28),
        Text('Nova senha', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _senhaCtrl,
          obscureText: !_senhaVisivel,
          style: TextStyle(color: kText1, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Mínimo 6 caracteres',
            hintStyle: TextStyle(color: kText2),
            prefixIcon: Icon(Icons.lock_outline, color: kText2, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kText2, size: 20),
              onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
            ),
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Confirmar senha', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmCtrl,
          obscureText: !_confirmVisivel,
          onSubmitted: (_) => _loading ? null : _criarConta(),
          style: TextStyle(color: kText1, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Repita a senha',
            hintStyle: TextStyle(color: kText2),
            prefixIcon: Icon(Icons.lock_outline, color: kText2, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_confirmVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kText2, size: 20),
              onPressed: () => setState(() => _confirmVisivel = !_confirmVisivel),
            ),
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
          _erroWidget(_erro!),
        ],
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _loading ? null : _criarConta,
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Criar senha e entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  // ─── Etapa 3: sucesso ──────────────────────────────────────────────────────

  Widget _buildSucesso() {
    final nome = _usuarioSelecionado?['nome'] as String? ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: kSuccess.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline, color: kSuccess, size: 52),
          ),
        ),
        const SizedBox(height: 28),
        Text('Tudo certo, $nome!',
            textAlign: TextAlign.center,
            style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text(
          'Sua senha foi criada com sucesso. Agora você já pode acessar o app.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kText2, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 40),
        FilledButton(
          onPressed: _entrar,
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Entrar agora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  // ─── Widget de erro ────────────────────────────────────────────────────────

  Widget _erroWidget(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kDanger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(msg, style: TextStyle(color: kDanger, fontSize: 13)),
    );
  }
}
