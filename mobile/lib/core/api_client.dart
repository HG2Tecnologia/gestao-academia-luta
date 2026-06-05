import 'package:dio/dio.dart';
import 'auth_storage.dart';
import 'constants.dart';

final dio = Dio(BaseOptions(
  baseUrl: kApiUrl,
  connectTimeout: const Duration(seconds: 20),
  receiveTimeout: const Duration(seconds: 25),
));

bool _refreshing = false;

void setupDio() {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AuthStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_refreshing) {
          final refreshToken = await AuthStorage.getRefreshToken();
          if (refreshToken == null) {
            await AuthStorage.clear();
            handler.next(error);
            return;
          }

          _refreshing = true;
          try {
            final refreshRes = await Dio(BaseOptions(baseUrl: kApiUrl))
                .post('/api/auth/refresh', data: {'refreshToken': refreshToken});
            final body = refreshRes.data as Map<String, dynamic>;
            if (body['sucesso'] == true) {
              final dados = body['dados'] as Map<String, dynamic>;
              final newToken = dados['accessToken'] as String;
              final newRefresh = dados['refreshToken'] as String?;
              await AuthStorage.updateToken(newToken, refreshToken: newRefresh);

              final retryOpts = error.requestOptions;
              retryOpts.headers['Authorization'] = 'Bearer $newToken';
              final retryRes = await dio.fetch(retryOpts);
              handler.resolve(retryRes);
              return;
            }
          } catch (_) {
            // refresh falhou
          } finally {
            _refreshing = false;
          }

          await AuthStorage.clear();
        }
        handler.next(error);
      },
    ),
  );
}
