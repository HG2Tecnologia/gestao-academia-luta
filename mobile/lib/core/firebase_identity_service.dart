import 'package:cloud_functions/cloud_functions.dart';

/// O provisionamento automático (criação/edição de aluno) encontrou outra
/// conta com o mesmo telefone/e-mail que JÁ teve o primeiro acesso completo
/// (a pessoa já definiu a própria senha) — o servidor recusou sobrescrever
/// sem confirmação. `contas` é quantas contas estão nesse grupo.
class SenhaJaDefinidaException implements Exception {
  const SenhaJaDefinidaException(this.contas);
  final int contas;
}

class AccessDiscovery {
  const AccessDiscovery({required this.profiles, required this.accountExists});

  final List<Map<String, dynamic>> profiles;
  final bool accountExists;
}

class FirebaseIdentityService {
  FirebaseIdentityService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<AccessDiscovery> discoverProfiles(String identifier) async {
    final result = await _functions
        .httpsCallable('discoverAccessProfiles')
        .call({'identifier': identifier});
    final data = _asMap(result.data);
    final profiles = (data['profiles'] as List<dynamic>? ?? const [])
        .map((profile) => _asMap(profile))
        .toList();
    return AccessDiscovery(
      profiles: profiles,
      accountExists: data['accountExists'] == true,
    );
  }

  Future<Map<String, dynamic>> activateAccount({
    required String identifier,
    required String primaryProfileKey,
  }) async {
    final result = await _functions.httpsCallable('activateAccessAccount').call(
      {'identifier': identifier, 'primaryProfileKey': primaryProfileKey},
    );
    return _asMap(_asMap(result.data)['account']);
  }

  Future<Map<String, dynamic>> refreshAccount() async {
    final result = await _functions
        .httpsCallable('refreshAccessAccount')
        .call();
    return _asMap(_asMap(result.data)['account']);
  }

  /// Admin/Secretaria redefine (ou provisiona) a senha de acesso ao app de
  /// outro perfil da mesma academia.
  ///
  /// O servidor aplica a MESMA senha temporária em todas as contas do
  /// Firebase Auth alcançáveis pelo telefone/e-mail do cadastro (a pessoa pode
  /// logar por qualquer um) e, se ainda não houver conta nenhuma, cria/vincula
  /// uma. `motivo` só alimenta a auditoria: `redefinicao` (padrão),
  /// `provisao_criacao` ou `provisao_edicao`.
  ///
  /// Quando o provisionamento automático (criação/edição) encontra outra
  /// conta com o mesmo telefone/e-mail que já definiu senha própria, o
  /// servidor recusa sobrescrever e lança [SenhaJaDefinidaException] — a
  /// chamada deve ser repetida com `apenasVincular: true` (mantém a senha
  /// atual, só vincula o novo perfil) ou `confirmarSobrescrita: true` (gera
  /// nova senha temporária, derrubando a que já existia). Um clique explícito
  /// em "Redefinir senha" (`motivo: 'redefinicao'`) nunca bloqueia — já é uma
  /// decisão intencional da academia sobre aquele perfil.
  ///
  /// A senha só existe nesta resposta — nunca é persistida em texto claro e
  /// deve ser exibida uma única vez. `loginHint` diz como a pessoa deve entrar
  /// ("telefone (11) ...", "e-mail x@y.com"). Se `vinculadoSemSenha` vier
  /// `true`, nenhuma senha foi gerada (o perfil passou a compartilhar a conta
  /// existente) e `senha` vem vazia.
  Future<
    ({
      String senha,
      String nome,
      String loginHint,
      int contas,
      bool vinculadoSemSenha,
    })
  >
  adminResetPassword({
    required String academiaId,
    required String colecao,
    required String usuarioId,
    String motivo = 'redefinicao',
    bool confirmarSobrescrita = false,
    bool apenasVincular = false,
  }) async {
    try {
      final result = await _functions.httpsCallable('adminResetPassword').call({
        'academiaId': academiaId,
        'colecao': colecao,
        'usuarioId': usuarioId,
        'motivo': motivo,
        'confirmarSobrescrita': confirmarSobrescrita,
        'apenasVincular': apenasVincular,
      });
      final data = _asMap(result.data);
      return (
        senha: data['temporaryPassword'] as String? ?? '',
        nome: data['nome'] as String? ?? '',
        loginHint:
            data['loginHint'] as String? ?? 'telefone ou e-mail cadastrado',
        contas: (data['contas'] as num?)?.toInt() ?? 1,
        vinculadoSemSenha: data['vinculadoSemSenha'] == true,
      );
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      if (e.code == 'failed-precondition' &&
          details is Map &&
          details['code'] == 'senha_ja_definida') {
        throw SenhaJaDefinidaException(
          (details['contas'] as num?)?.toInt() ?? 1,
        );
      }
      rethrow;
    }
  }

  /// Encerra o fluxo de troca obrigatória de senha: limpa a flag no
  /// servidor depois que a pessoa já definiu a nova senha no Firebase Auth.
  Future<void> completeMandatoryPasswordChange() async {
    await _functions.httpsCallable('completeMandatoryPasswordChange').call();
  }

  /// Checagem PRÉVIA (sem criar nada) usada antes de cadastrar um aluno: diz
  /// se o telefone/e-mail informado já pertence a outra conta que já definiu
  /// senha própria — pra academia decidir ANTES de o cadastro existir.
  /// Cancelar nesse ponto não deixa rastro nenhum, diferente de decidir
  /// depois que o aluno já foi criado no banco.
  Future<({bool conflito, int contas})> checkContatoCompartilhado({
    required String academiaId,
    String? telefone,
    String? email,
  }) async {
    final result = await _functions
        .httpsCallable('checkContatoCompartilhado')
        .call({
          'academiaId': academiaId,
          'telefone': telefone ?? '',
          'email': email ?? '',
        });
    final data = _asMap(result.data);
    return (
      conflito: data['conflito'] == true,
      contas: (data['contas'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}

final firebaseIdentityService = FirebaseIdentityService();
