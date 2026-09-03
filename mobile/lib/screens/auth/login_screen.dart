import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firebase_identity_service.dart';
import '../../core/firestore_service.dart';
import '../../core/phone_normalizer.dart';
import '../../core/push_service.dart';

class _SmartInputFormatter extends TextInputFormatter {
  static final _onlyDigits = RegExp(r'\D');
  static final _hasLetter = RegExp(r'[a-zA-Z@]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
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
  /// 'aluno' ou 'academia'. Controla o texto e os atalhos exibidos.
  /// Nulo (acesso direto/legado) redireciona para a tela de escolha.
  final String? contexto;

  const LoginScreen({super.key, this.contexto});

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

  bool get _isAcademia => widget.contexto == 'academia';

  @override
  void initState() {
    super.initState();
    // Acesso direto sem contexto (deep link/bookmark antigo): manda para a
    // tela de escolha para não expor "Criar uma academia" a quem é aluno.
    if (widget.contexto == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement('/boas-vindas');
      });
    }
  }

  void _onIdChanged(String v) {
    if (v.isEmpty) {
      if (_mode != _InputMode.indefinido) {
        setState(() => _mode = _InputMode.indefinido);
      }
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

  Future<UserCredential> _autenticar(String senha) async {
    if (_mode != _InputMode.telefone) {
      return FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _idCtrl.text.trim().toLowerCase(),
        password: senha,
      );
    }

    final rawDigits = _idCtrl.text.replaceAll(RegExp(r'\D'), '');
    final canonicalDigits = PhoneNormalizer.digits(_idCtrl.text);
    final candidates = <String>{
      if (rawDigits.isNotEmpty) '$rawDigits@sensei.app',
      if (canonicalDigits != null) '$canonicalDigits@sensei.app',
    };
    FirebaseAuthException? lastError;
    for (final email in candidates) {
      try {
        return await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: senha,
        );
      } on FirebaseAuthException catch (error) {
        lastError = error;
        if (!const {
          'invalid-credential',
          'user-not-found',
          'wrong-password',
        }.contains(error.code)) {
          rethrow;
        }
      }
    }
    throw lastError ?? FirebaseAuthException(code: 'invalid-credential');
  }

  Future<String?> _validarAcessoAluno(String academiaId, String alunoId) async {
    final alunoDoc = await firestoreService.getUsuario(academiaId, alunoId);
    if (alunoDoc == null) return 'Perfil de aluno não encontrado.';
    if (alunoDoc['ativo'] == false) {
      return 'Seu cadastro está inativo. Entre em contato com a secretaria.';
    }
    if (alunoDoc['acesso_app_bloqueado'] == true) {
      return 'Seu acesso ao app está suspenso. Entre em contato com a secretaria.';
    }
    final motivoMensalidade = await firestoreService.motivoBloqueioCheckin(
      academiaId,
      alunoId,
    );
    if (motivoMensalidade != null) {
      return 'Acesso bloqueado: mensalidade vencida. Regularize seu pagamento e tente novamente.';
    }
    return null;
  }

  Future<void> _login() async {
    final erroId = _validarId();
    if (erroId != null) {
      setState(() => _erro = erroId);
      return;
    }
    if (_senhaCtrl.text.isEmpty) {
      setState(() => _erro = 'Informe sua senha.');
      return;
    }

    setState(() {
      _loading = true;
      _erro = null;
      _loadingMsgIdx = 0;
    });
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) {
        setState(
          () => _loadingMsgIdx = (_loadingMsgIdx + 1) % _loadingMsgs.length,
        );
      }
    });

    try {
      final senha = _senhaCtrl.text;

      // 1. Autenticar com Firebase (sem backend, instantâneo)
      final credential = await _autenticar(
        senha,
      ).timeout(const Duration(seconds: 15));

      final uid = credential.user!.uid;

      // Atualiza o schema da conta e inclui irmãos/perfis cadastrados depois
      // do primeiro acesso. Mantém compatibilidade se a Function estiver
      // temporariamente indisponível durante o rollout.
      try {
        await firebaseIdentityService.refreshAccount();
      } catch (_) {}

      // 2. Buscar dados do usuário no Firestore (sem backend, sem cold start)
      final userData = await firestoreService.getUserByFirebaseUid(uid);
      if (userData == null) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(
          () => _erro =
              'Usuário não encontrado no sistema. Contate o administrador.',
        );
        return;
      }

      // Extrai permissões (para professor/secretaria)
      final rawPerm = userData['permissoes'];
      var permissoes = rawPerm is Map
          ? Map<String, bool>.from(
              rawPerm.map((k, v) => MapEntry(k.toString(), v == true)),
            )
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
        // Já veio de um card "Sou aluno/responsável" ou "Sou uma academia" —
        // filtra os perfis compatíveis com esse contexto antes de perguntar.
        // Se sobrar só um, nem mostra o seletor; se sobrar mais de um (ex:
        // duas academias diferentes), mostra só os compatíveis, com badge.
        final candidatos = _perfisParaContexto(perfisLista);
        final selecionado = candidatos.length == 1
            ? candidatos.first
            : await _mostrarSeletorPerfil(candidatos);
        if (!mounted) return;
        if (selecionado != null) {
          usuarioId = selecionado['usuarioId'] as String? ?? usuarioId;
          nomeUsuario = selecionado['nome'] as String? ?? nomeUsuario;
          academiaId = selecionado['academiaId'] as String? ?? academiaId;
          // Perfil escolhido pode ser de um tipo diferente do vinculado ao
          // login (ex: Professor que também é Aluno em outra modalidade) —
          // sem isso o app continuava navegando/aplicando permissões do
          // perfil original, ignorando a escolha do usuário.
          final colecaoSel = selecionado['colecao'] as String? ?? 'usuarios';
          perfilNome = selecionado['perfil_nome'] as String? ?? perfilNome;
          if (colecaoSel == 'funcionarios' && academiaId != null) {
            final func = await firestoreService.getFuncionario(
              academiaId,
              usuarioId,
            );
            final rawPermSel = func?['permissoes'];
            permissoes = rawPermSel is Map
                ? Map<String, bool>.from(
                    rawPermSel.map((k, v) => MapEntry(k.toString(), v == true)),
                  )
                : <String, bool>{};
          } else {
            permissoes = <String, bool>{};
          }
        }
      }

      // O bloqueio é avaliado no perfil efetivamente escolhido, nunca no
      // perfil primário da conta. Isso evita bloquear um Admin que também é
      // aluno e evita liberar um aluno bloqueado quando o primário é outro.
      if (perfilNome == 'Aluno' && academiaId != null) {
        final motivoBloqueio = await _validarAcessoAluno(academiaId, usuarioId);
        if (motivoBloqueio != null) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          setState(() => _erro = motivoBloqueio);
          return;
        }
      }

      // 3. Salvar dados localmente
      await AuthStorage.save(
        uid,
        StoredUser(
          id: usuarioId,
          nome: nomeUsuario,
          email: userData['email'] as String? ?? credential.user?.email ?? '',
          perfil: perfilNome,
          academiaId: academiaId,
          permissoes: permissoes,
          perfis: perfisLista,
          mustChangePassword: userData['must_change_password'] == true,
        ),
      );

      if (!mounted) return;

      // Registra o token de push (silencioso) para quem pode ver o financeiro,
      // para receber alertas de vencimento das Contas da Academia.
      if (perfilNome == 'Admin' || perfilNome == 'Secretaria') {
        PushService.init();
      }

      // Uma redefinição administrativa de senha bloqueia a navegação normal
      // até a pessoa trocar pela senha definitiva dela.
      if (userData['must_change_password'] == true) {
        context.go('/troca-senha-obrigatoria');
        return;
      }

      // 4. Navegar conforme perfil
      switch (perfilNome) {
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
      setState(() => _erro = _mensagemFirebase(e.code));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final code = e.code;
      if (code == 'unavailable' || code == 'failed-precondition') {
        setState(
          () => _erro =
              'Banco de dados ainda não configurado. Contate o administrador.',
        );
      } else if (code == 'permission-denied') {
        setState(
          () => _erro =
              'Sem permissão para acessar os dados. Contate o administrador.',
        );
      } else {
        setState(() => _erro = 'Erro Firebase ($code): ${e.message}');
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(
        () =>
            _erro = 'Tempo esgotado. Verifique sua conexão e tente novamente.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = 'Erro inesperado: $e');
    } finally {
      _loadingTimer?.cancel();
      _loadingTimer = null;
      if (mounted) setState(() => _loading = false);
    }
  }

  static bool _ehPerfilStaff(Map<String, dynamic> p) {
    final nome = p['perfil_nome'] as String?;
    return nome == 'Admin' || nome == 'Secretaria' || nome == 'Professor';
  }

  /// Filtra os perfis compatíveis com o contexto escolhido na entrada do
  /// app ("Sou aluno/responsável" ou "Sou uma academia"). Se o filtro
  /// zerar a lista (conta sem nenhum perfil desse tipo), devolve a lista
  /// original em vez de travar o login.
  List<Map<String, dynamic>> _perfisParaContexto(
    List<Map<String, dynamic>> perfis,
  ) {
    final filtrados = _isAcademia
        ? perfis.where(_ehPerfilStaff).toList()
        : perfis.where((p) => !_ehPerfilStaff(p)).toList();
    return filtrados.isNotEmpty ? filtrados : perfis;
  }

  Future<Map<String, dynamic>?> _mostrarSeletorPerfil(
    List<Map<String, dynamic>> perfis,
  ) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.group_rounded, color: kPrimary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Qual perfil deseja acessar?',
                    style: TextStyle(
                      color: kText1,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final p in perfis)
              ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: kPrimary,
                  child: Text(
                    (p['nome'] as String? ?? '')
                        .split(' ')
                        .take(2)
                        .map((w) => w.isNotEmpty ? w[0] : '')
                        .join()
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  p['nome'] as String? ?? '',
                  style: TextStyle(color: kText1, fontWeight: FontWeight.w600),
                ),
                subtitle: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (p['perfil_nome'] as String?) ?? 'Aluno',
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: kText2,
                  size: 14,
                ),
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
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/logo_app.png',
                        width: 72,
                        height: 72,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'SENSEI MANAGER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isAcademia
                          ? 'Acesse o painel da sua academia'
                          : 'Acesse sua conta de aluno ou responsável',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kText2, fontSize: 13),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'E-mail ou Telefone',
                      style: TextStyle(
                        color: kText2,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Senha',
                      style: TextStyle(
                        color: kText2,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                        child: Text(
                          _erro!,
                          style: TextStyle(color: kDanger, fontSize: 13),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
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
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    if (_loading) ...[
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(anim),
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
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.push(
                        '/primeiro-acesso',
                        extra: {'contexto': widget.contexto},
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimary,
                        side: BorderSide(
                          color: kPrimary.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Acessando o app pela primeira vez',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.push(
                        '/esqueci-senha',
                        extra: {'contexto': widget.contexto},
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kText2,
                        side: BorderSide(color: kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Esqueci minha senha',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Criar uma academia é uma ação empresarial: some do fluxo
                    // de aluno/responsável, que nunca deveria ver essa opção.
                    if (_isAcademia) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.push('/cadastrar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimary,
                          side: BorderSide(
                            color: kPrimary.withValues(alpha: 0.4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Criar uma academia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.contexto != null)
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/boas-vindas'),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Voltar',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
