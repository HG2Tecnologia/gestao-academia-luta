import 'package:cloud_functions/cloud_functions.dart';

class ResultadoGarantiaCobrancas {
  const ResultadoGarantiaCobrancas({required this.criadas, required this.ignoradas});
  final int criadas;
  final int ignoradas;
}

class ResultadoLimpezaRetroativa {
  const ResultadoLimpezaRetroativa({
    required this.desconsideradas,
    required this.ignoradas,
  });
  final int desconsideradas;
  final int ignoradas;
}

class ResultadoCorrecaoDuplicatas {
  const ResultadoCorrecaoDuplicatas({
    required this.gruposComDuplicata,
    required this.resolvidasAutomaticamente,
    required this.ignoradasRevisaoManual,
  });
  final int gruposComDuplicata;
  final int resolvidasAutomaticamente;
  final int ignoradasRevisaoManual;
}

/// Geração automática de mensalidades por competência (`YYYY-MM`) — sempre
/// via Cloud Function, nunca só no cliente. Idempotente: chamar de novo para
/// a mesma competência não duplica nem sobrescreve cobranças já existentes
/// (pagas, atrasadas ou não).
///
/// Classe (não mais `static`) de propósito: em teste, um `FakeFinanceService`
/// é atribuído à variável global [financeService] para gravar/observar as
/// chamadas sem bater na Cloud Function de verdade — foi assim que se pegou
/// (e se prova, com teste, que ficou corrigido) o bug de cobrança retroativa:
/// a tela de Financeiro chamava isso para o mês que o admin estava navegando,
/// não para o mês real de hoje.
class FinanceService {
  Future<ResultadoGarantiaCobrancas> ensureChargesForPeriod({
    required String academiaId,
    required String period,
  }) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('ensureChargesForPeriod')
        .call({'academiaId': academiaId, 'period': period});
    final data = result.data;
    final criadas = data is Map ? data['criadas'] : null;
    final ignoradas = data is Map ? data['ignoradas'] : null;
    return ResultadoGarantiaCobrancas(
      criadas: criadas is num ? criadas.toInt() : 0,
      ignoradas: ignoradas is num ? ignoradas.toInt() : 0,
    );
  }

  /// Desconsidera (nunca exclui, nunca marca como paga) toda cobrança com
  /// competência ANTERIOR a `period` (`YYYY-MM`) — usado para limpar
  /// pendências retroativas geradas por engano. Cobrança já paga ou já
  /// desconsiderada nunca é tocada.
  Future<ResultadoLimpezaRetroativa> disregardChargesBeforePeriod({
    required String academiaId,
    required String period,
  }) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('disregardChargesBeforePeriod')
        .call({'academiaId': academiaId, 'period': period});
    final data = result.data;
    final desconsideradas = data is Map ? data['desconsideradas'] : null;
    final ignoradas = data is Map ? data['ignoradas'] : null;
    return ResultadoLimpezaRetroativa(
      desconsideradas: desconsideradas is num ? desconsideradas.toInt() : 0,
      ignoradas: ignoradas is num ? ignoradas.toInt() : 0,
    );
  }

  /// Acha mensalidade duplicada (mesmo aluno + mesma competência) e resolve
  /// sozinho os casos inequívocos, sempre desconsiderando (nunca excluindo,
  /// nunca marcando como paga) os documentos extras. Grupo com 2+ pagamentos
  /// já marcados como pagos fica de fora — exige revisão manual, porque
  /// decidir sozinho ali apagaria receita real recebida.
  Future<ResultadoCorrecaoDuplicatas> mergeDuplicateCharges({
    required String academiaId,
  }) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('mergeDuplicateCharges')
        .call({'academiaId': academiaId});
    final data = result.data;
    num asNum(String key) {
      final v = data is Map ? data[key] : null;
      return v is num ? v : 0;
    }

    return ResultadoCorrecaoDuplicatas(
      gruposComDuplicata: asNum('gruposComDuplicata').toInt(),
      resolvidasAutomaticamente: asNum('resolvidasAutomaticamente').toInt(),
      ignoradasRevisaoManual: asNum('ignoradasRevisaoManual').toInt(),
    );
  }
}

/// Não é `final` de propósito — ver comentário em [FinanceService]. Nunca
/// reatribuído em código de produção, só em teste (com `tearDown` para
/// devolver a instância real).
FinanceService financeService = FinanceService();
