import 'package:cloud_functions/cloud_functions.dart';

class ConflitoGraduacao {
  const ConflitoGraduacao({required this.mensagem});
  final String mensagem;
}

class ResultadoEdicaoGraduacao {
  const ResultadoEdicaoGraduacao({this.conflito});
  final ConflitoGraduacao? conflito;
}

/// Edição administrativa de graduação: transação server-side (before/after,
/// operador, timestamp) via Cloud Function — nunca escrita direta pelo
/// cliente, para manter a trilha de auditoria confiável.
abstract final class GraduacaoService {
  static Future<ResultadoEdicaoGraduacao> editarGraduacao({
    required String academiaId,
    required String graduacaoId,
    required String faixaId,
    required int grau,
    required String dataExame,
    String observacoes = '',
  }) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('editarGraduacao')
        .call({
          'academiaId': academiaId,
          'graduacaoId': graduacaoId,
          'faixaId': faixaId,
          'grau': grau,
          'dataExame': dataExame,
          'observacoes': observacoes,
        });
    final data = result.data;
    final conflitoRaw = data is Map ? data['conflito'] : null;
    final conflito = conflitoRaw is Map
        ? ConflitoGraduacao(
            mensagem: conflitoRaw['mensagem']?.toString() ?? '',
          )
        : null;
    return ResultadoEdicaoGraduacao(conflito: conflito);
  }
}
