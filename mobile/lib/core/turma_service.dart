import 'package:cloud_functions/cloud_functions.dart';

class ResultadoExclusaoTurma {
  const ResultadoExclusaoTurma({required this.matriculasEncerradas});
  final int matriculasEncerradas;
}

/// Exclusão administrativa de turma: sempre lógica (soft delete) via
/// transação server-side — nunca apaga o documento nem o histórico
/// (presenças, graduações, horários continuam resolvendo pelo turma_id).
abstract final class TurmaService {
  static bool estaExcluida(Map<String, dynamic> turma) =>
      turma['deleted_at'] != null;

  static Future<ResultadoExclusaoTurma> arquivarTurma({
    required String academiaId,
    required String turmaId,
  }) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('arquivarTurma')
        .call({'academiaId': academiaId, 'turmaId': turmaId});
    final data = result.data;
    final matriculas = data is Map ? data['matriculasEncerradas'] : null;
    return ResultadoExclusaoTurma(
      matriculasEncerradas: matriculas is num ? matriculas.toInt() : 0,
    );
  }
}
