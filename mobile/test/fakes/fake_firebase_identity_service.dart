import 'package:tatame/core/firebase_identity_service.dart';

/// Substituto de teste para [FirebaseIdentityService] — nunca bate na Cloud
/// Function de verdade. [verificarStatus] é o que o modo `verificar` sempre
/// devolve (simula a resposta do servidor sobre o telefone novo: `livre`,
/// `conflito`, `compartilhada`, `sem_acesso` ou `sem_mudanca`); `aplicar` e
/// `vincular` sempre "funcionam" (devolvem `atualizado`), a menos que
/// [falharAoAplicar] seja `true` — simula o servidor aceitar o diagnóstico mas
/// falhar ao gravar, caminho que a tela trata com um aviso em vez de erro.
///
/// Uso: `firebaseIdentityService = FakeFirebaseIdentityService(...);` antes
/// de montar a tela, e `firebaseIdentityService = FirebaseIdentityService();`
/// no tearDown.
class FakeFirebaseIdentityService extends FirebaseIdentityService {
  FakeFirebaseIdentityService({
    required this.verificarStatus,
    this.falharAoAplicar = false,
  });

  final String verificarStatus;
  final bool falharAoAplicar;

  final List<({String telefone, String modo})> chamadas = [];

  @override
  Future<({String status, int contas})> atualizarTelefoneAcessoAluno({
    required String academiaId,
    required String usuarioId,
    required String telefone,
    required String modo,
  }) async {
    chamadas.add((telefone: telefone, modo: modo));
    if (modo == 'verificar') {
      return (
        status: verificarStatus,
        contas: verificarStatus == 'conflito' ? 1 : 0,
      );
    }
    if (falharAoAplicar) {
      throw Exception('falha simulada ao $modo');
    }
    return (status: 'atualizado', contas: 0);
  }
}
