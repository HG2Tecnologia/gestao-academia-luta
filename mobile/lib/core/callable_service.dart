import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallableError implements Exception {
  final String code;
  final String message;
  CallableError(this.code, this.message);
  @override
  String toString() => message;
}

class CallableService {
  static const _baseUrl = 'https://sensei-manager-d64c0.web.app/api';
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static Future<Map<String, dynamic>> call(
    String function,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw CallableError('unauthenticated', 'Sessão expirada. Faça login novamente.');
    final token = await user.getIdToken(true);

    try {
      final response = await _dio.post(
        '$_baseUrl/$function',
        data: {'data': data},
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }),
      );

      final body = response.data as Map<String, dynamic>;
      if (body['error'] != null) {
        final err = body['error'] as Map;
        throw CallableError(
          err['status']?.toString().toLowerCase() ?? 'internal',
          err['message']?.toString() ?? 'Erro interno.',
        );
      }
      return (body['result'] as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['error'] != null) {
        final err = body['error'] as Map;
        throw CallableError(
          err['status']?.toString().toLowerCase() ?? 'internal',
          err['message']?.toString() ?? 'Erro ao processar requisição.',
        );
      }
      throw CallableError('unavailable', 'Erro de conexão. Verifique sua internet.');
    }
  }
}
