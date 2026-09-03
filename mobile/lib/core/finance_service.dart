import 'package:cloud_functions/cloud_functions.dart';

class ResultadoGarantiaCobrancas {
  const ResultadoGarantiaCobrancas({required this.criadas, required this.ignoradas});
  final int criadas;
  final int ignoradas;
}

/// Geração automática de mensalidades por competência (`YYYY-MM`) — sempre
/// via Cloud Function, nunca só no cliente. Idempotente: chamar de novo para
/// a mesma competência não duplica nem sobrescreve cobranças já existentes
/// (pagas, atrasadas ou não).
abstract final class FinanceService {
  static Future<ResultadoGarantiaCobrancas> ensureChargesForPeriod({
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
}
