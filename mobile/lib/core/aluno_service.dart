import 'package:cloud_functions/cloud_functions.dart';

/// Exclusão administrativa de aluno: definitiva (hard delete), feita
/// server-side numa única Cloud Function — apaga matrículas, mensalidades,
/// presenças, graduações, notificações e afins, desvincula de grupo
/// familiar, e remove só o perfil desse aluno de uma conta de acesso
/// compartilhada (telefone/e-mail em comum com outro aluno), sem afetar
/// quem mais usa essa mesma conta.
abstract final class AlunoService {
  static Future<void> excluirAluno({
    required String academiaId,
    required String alunoId,
  }) async {
    await FirebaseFunctions.instance
        .httpsCallable('excluirAluno')
        .call({'academiaId': academiaId, 'alunoId': alunoId});
  }
}
