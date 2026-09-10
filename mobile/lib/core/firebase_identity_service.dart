import 'package:cloud_functions/cloud_functions.dart';

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
  /// A senha só existe nesta resposta — nunca é persistida em texto claro e
  /// deve ser exibida uma única vez. `loginHint` diz como a pessoa deve entrar
  /// ("telefone (11) ...", "e-mail x@y.com").
  Future<({String senha, String nome, String loginHint, int contas})>
  adminResetPassword({
    required String academiaId,
    required String colecao,
    required String usuarioId,
    String motivo = 'redefinicao',
  }) async {
    final result = await _functions.httpsCallable('adminResetPassword').call({
      'academiaId': academiaId,
      'colecao': colecao,
      'usuarioId': usuarioId,
      'motivo': motivo,
    });
    final data = _asMap(result.data);
    return (
      senha: data['temporaryPassword'] as String? ?? '',
      nome: data['nome'] as String? ?? '',
      loginHint: data['loginHint'] as String? ?? 'telefone ou e-mail cadastrado',
      contas: (data['contas'] as num?)?.toInt() ?? 1,
    );
  }

  /// Encerra o fluxo de troca obrigatória de senha: limpa a flag no
  /// servidor depois que a pessoa já definiu a nova senha no Firebase Auth.
  Future<void> completeMandatoryPasswordChange() async {
    await _functions.httpsCallable('completeMandatoryPasswordChange').call();
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}

final firebaseIdentityService = FirebaseIdentityService();
