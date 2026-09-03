import 'package:firebase_auth/firebase_auth.dart';
import 'auth_storage.dart';
import 'firestore_service.dart';
import 'firebase_identity_service.dart';

abstract class ProfileSessionService {
  /// Atualiza os vínculos da sessão sem exigir novo login/Primeiro Acesso.
  /// Preserva o perfil atualmente selecionado quando ele continua disponível.
  static Future<StoredUser?> refresh() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final local = await AuthStorage.getUser();
    if (firebaseUser == null) return local;

    // A Function é idempotente e inclui perfis cadastrados depois do primeiro
    // acesso. Falhas de rede não invalidam a sessão local existente.
    try {
      await firebaseIdentityService.refreshAccount();
    } catch (_) {}

    final remoto = await firestoreService.getUserByFirebaseUid(
      firebaseUser.uid,
    );
    if (remoto == null) return local;

    final rawPerfis = remoto['perfis'];
    final perfis = rawPerfis is List
        ? rawPerfis.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    Map<String, dynamic>? selecionado;
    if (local != null) {
      for (final perfil in perfis) {
        if (perfil['usuarioId']?.toString() == local.id &&
            perfil['academiaId']?.toString() == local.academiaId) {
          selecionado = perfil;
          break;
        }
      }
    }

    final id =
        selecionado?['usuarioId']?.toString() ??
        remoto['usuarioId']?.toString() ??
        firebaseUser.uid;
    final academiaId =
        selecionado?['academiaId']?.toString() ??
        remoto['academiaId']?.toString();
    final perfil =
        selecionado?['perfil_nome']?.toString() ??
        remoto['perfil']?.toString() ??
        'Aluno';
    final colecao =
        selecionado?['colecao']?.toString() ??
        remoto['colecao']?.toString() ??
        'usuarios';

    var permissoes = <String, bool>{};
    if (colecao == 'funcionarios' && academiaId != null) {
      final funcionario = await firestoreService.getFuncionario(academiaId, id);
      final rawPermissoes = funcionario?['permissoes'];
      if (rawPermissoes is Map) {
        permissoes = rawPermissoes.map(
          (key, value) => MapEntry(key.toString(), value == true),
        );
      }
    } else if (selecionado == null) {
      final rawPermissoes = remoto['permissoes'];
      if (rawPermissoes is Map) {
        permissoes = rawPermissoes.map(
          (key, value) => MapEntry(key.toString(), value == true),
        );
      }
    }

    final atualizado = StoredUser(
      id: id,
      nome:
          selecionado?['nome']?.toString() ??
          remoto['nome']?.toString() ??
          local?.nome ??
          '',
      email: remoto['email']?.toString() ?? local?.email ?? '',
      perfil: perfil,
      academiaId: academiaId,
      permissoes: permissoes,
      perfis: perfis,
      mustChangePassword: remoto['must_change_password'] == true,
    );

    if (local == null) {
      await AuthStorage.save(firebaseUser.uid, atualizado);
    } else {
      await AuthStorage.saveUser(atualizado);
    }
    return atualizado;
  }
}
