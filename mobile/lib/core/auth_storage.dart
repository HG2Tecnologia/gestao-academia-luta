import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StoredUser {
  final String id;
  final String nome;
  final String email;
  final String perfil;
  final String? academiaId;
  final Map<String, bool> permissoes;
  // Lista de perfis para grupo familiar (alunos com mesmo e-mail/telefone)
  final List<Map<String, dynamic>> perfis;

  const StoredUser({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    this.academiaId,
    this.permissoes = const {},
    this.perfis = const [],
  });

  factory StoredUser.fromJson(Map<String, dynamic> j) => StoredUser(
        id: j['id'] ?? '',
        nome: j['nome'] ?? '',
        email: j['email'] ?? '',
        perfil: j['perfil'] ?? '',
        academiaId: j['academiaId'],
        permissoes: (j['permissoes'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v == true)),
        perfis: (j['perfis'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'perfil': perfil,
        'academiaId': academiaId,
        'permissoes': permissoes,
        'perfis': perfis,
      };

  bool temPermissao(String chave) {
    // Admin sempre tem tudo
    if (perfil == 'Admin') return true;
    return permissoes[chave] ?? false;
  }
}

abstract class AuthStorage {
  static const _tokenKey = '@tatame:token';
  static const _refreshKey = '@tatame:refresh';
  static const _userKey = '@tatame:user';

  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_refreshKey);
  }

  static Future<StoredUser?> getUser() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_userKey);
    if (raw == null) return null;
    try {
      return StoredUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String token, StoredUser user, {String? refreshToken}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, token);
    await p.setString(_userKey, jsonEncode(user.toJson()));
    if (refreshToken != null) await p.setString(_refreshKey, refreshToken);
  }

  static Future<void> saveUser(StoredUser user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<void> updateToken(String token, {String? refreshToken}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, token);
    if (refreshToken != null) await p.setString(_refreshKey, refreshToken);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_tokenKey);
    await p.remove(_refreshKey);
    await p.remove(_userKey);
  }

  static String? subFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
      return json['sub'] as String?;
    } catch (_) {
      return null;
    }
  }
}
