import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firestore_service.dart';

/// Handler de mensagens em background/terminado. Precisa ser uma função
/// top-level (fora de qualquer classe) para o plugin conseguir registrá-la
/// como entry point isolado.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nada a fazer aqui: quando o payload tem `notification`, o próprio
  // sistema operacional já exibe a notificação. Este handler existe só
  // para permitir processar dados customizados no futuro, se necessário.
}

/// Pede permissão de notificação e mantém o token FCM do dispositivo
/// salvo no Firestore, para que a Cloud Function de vencimentos de
/// "Contas da Academia" consiga notificar quem tem acesso ao financeiro
/// (Admin/Secretaria).
abstract class PushService {
  static String? _tokenAtual;

  static Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) await _salvarToken(token);

      messaging.onTokenRefresh.listen(_salvarToken);
    } catch (_) {
      // Sem permissão ou ambiente sem suporte a push (ex: alguns simuladores) — segue sem quebrar o app.
    }
  }

  static Future<void> _salvarToken(String token) async {
    if (_tokenAtual == token) return;
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;
      final remoto = await firestoreService.getUserByFirebaseUid(firebaseUser.uid);
      if (remoto == null) return;
      final academiaId = remoto['academiaId'] as String?;
      final usuarioId = remoto['usuarioId'] as String?;
      final colecao = remoto['colecao'] as String? ?? 'funcionarios';
      if (academiaId == null || usuarioId == null) return;

      await firestoreService.salvarFcmToken(
        academiaId: academiaId,
        usuarioId: usuarioId,
        colecao: colecao,
        token: token,
      );
      _tokenAtual = token;
    } catch (_) {}
  }
}
