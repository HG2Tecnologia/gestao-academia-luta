import 'package:tatame/core/firestore_service.dart';

/// Substituto de teste para [FirestoreService]. Sobrescreve só os métodos que
/// as telas de Financeiro chamam ao carregar — o resto herda da classe real,
/// mas nunca é exercitado nestes testes.
///
/// Uso: `firestoreService = FakeFirestoreService(pagamentos: [...]);` antes de
/// montar a tela, e `firestoreService = FirestoreService();` no tearDown.
class FakeFirestoreService extends FirestoreService {
  FakeFirestoreService({this.pagamentos = const [], this.academia = const {}});

  List<Map<String, dynamic>> pagamentos;
  Map<String, dynamic> academia;

  @override
  Future<List<Map<String, dynamic>>> getPagamentos(
    String academiaId, {
    String? alunoId,
  }) async {
    if (alunoId == null) return pagamentos;
    return pagamentos.where((p) => p['aluno_id'] == alunoId).toList();
  }

  @override
  Future<Map<String, dynamic>?> getAcademia(String academiaId) async =>
      academia;
}
