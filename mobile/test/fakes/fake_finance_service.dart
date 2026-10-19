import 'package:tatame/core/finance_service.dart';

/// Substituto de teste para [FinanceService] — nunca bate na Cloud Function
/// de verdade. Grava toda chamada recebida para o teste poder afirmar QUAL
/// competência foi pedida (isso é o que prova, ou não, o bug de cobrança
/// retroativa: a tela não pode chamar `ensureChargesForPeriod` para o mês
/// que o admin está navegando, só para o mês real de hoje).
///
/// Uso: `financeService = FakeFinanceService();` antes de montar a tela, e
/// `financeService = FinanceService();` no tearDown.
class FakeFinanceService extends FinanceService {
  final List<String> ensureChargesForPeriodCalls = [];
  final List<String> disregardChargesBeforePeriodCalls = [];
  final List<String> mergeDuplicateChargesCalls = [];

  @override
  Future<ResultadoGarantiaCobrancas> ensureChargesForPeriod({
    required String academiaId,
    required String period,
  }) async {
    ensureChargesForPeriodCalls.add(period);
    return const ResultadoGarantiaCobrancas(criadas: 0, ignoradas: 0);
  }

  @override
  Future<ResultadoLimpezaRetroativa> disregardChargesBeforePeriod({
    required String academiaId,
    required String period,
  }) async {
    disregardChargesBeforePeriodCalls.add(period);
    return const ResultadoLimpezaRetroativa(desconsideradas: 0, ignoradas: 0);
  }

  @override
  Future<ResultadoCorrecaoDuplicatas> mergeDuplicateCharges({
    required String academiaId,
  }) async {
    mergeDuplicateChargesCalls.add(academiaId);
    return const ResultadoCorrecaoDuplicatas(
      gruposComDuplicata: 0,
      resolvidasAutomaticamente: 0,
      ignoradasRevisaoManual: 0,
    );
  }
}
