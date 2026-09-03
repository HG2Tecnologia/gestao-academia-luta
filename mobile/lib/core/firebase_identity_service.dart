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

  /// Admin/Secretaria redefine a senha de outro perfil da mesma academia.
  /// Retorna a senha temporária gerada — ela só existe nesta resposta e
  /// nunca é persistida em texto claro; deve ser exibida uma única vez.
  Future<({String senha, String nome})> adminResetPassword({
    required String academiaId,
    required String colecao,
    required String usuarioId,
  }) async {
    final result = await _functions.httpsCallable('adminResetPassword').call({
      'academiaId': academiaId,
      'colecao': colecao,
      'usuarioId': usuarioId,
    });
    final data = _asMap(result.data);
    return (
      senha: data['temporaryPassword'] as String? ?? '',
      nome: data['nome'] as String? ?? '',
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
