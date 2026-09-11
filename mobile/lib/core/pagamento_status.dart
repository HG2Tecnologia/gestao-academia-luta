import 'billing_period.dart';

/// Adaptador entre o documento cru de `pagamentos` (Firestore) e o modelo de
/// domínio [EffectiveChargeStatus] de `billing_period.dart`.
///
/// Aluno e academia leem/escrevem a MESMA coleção `pagamentos`. O status é
/// gravado como `int`:
///
/// | int | status         |
/// |-----|----------------|
/// | 0   | Pendente       |
/// | 1   | Pago           |
/// | 2   | Atrasado *(nunca é gravado — sempre derivado de um Pendente vencido)* |
/// | 3   | Previsto       |
/// | 4   | Desconsiderado |
///
/// A regra de "vencido → Atrasado" NÃO é reimplementada aqui: delega para
/// [resolveChargeStatus], a mesma função usada/coberta por testes do domínio.
/// Regras que não podem divergir entre as telas:
///  * `Pago` e `Desconsiderado` nunca viram Atrasado.
///  * Só `Pago` conta como receita para a academia.
///  * `Desconsiderado` não é pendência do aluno nem receita da academia.

enum PagamentoStatus { pendente, pago, atrasado, previsto, desconsiderado }

/// Converte o valor cru do campo `status` (int, string numérica ou nulo).
/// Qualquer coisa inesperada cai em [PagamentoStatus.pendente].
PagamentoStatus pagamentoStatusFromInt(dynamic raw) {
  final i = raw is int ? raw : int.tryParse('${raw ?? ''}'.trim());
  switch (i) {
    case 1:
      return PagamentoStatus.pago;
    case 2:
      return PagamentoStatus.atrasado;
    case 3:
      return PagamentoStatus.previsto;
    case 4:
      return PagamentoStatus.desconsiderado;
    case 0:
    default:
      return PagamentoStatus.pendente;
  }
}

/// Inteiro persistível para cada status. `atrasado` volta como `0` (Pendente),
/// porque "atrasado" é sempre derivado, nunca gravado.
int pagamentoStatusToInt(PagamentoStatus s) {
  switch (s) {
    case PagamentoStatus.pendente:
      return 0;
    case PagamentoStatus.pago:
      return 1;
    case PagamentoStatus.atrasado:
      return 0;
    case PagamentoStatus.previsto:
      return 3;
    case PagamentoStatus.desconsiderado:
      return 4;
  }
}

DateTime? _parseVenc(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) {
    final ms = v > 100000000000 ? v : v * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  return DateTime.tryParse(v.toString());
}

/// Status efetivo para exibição: um Pendente/Previsto **vencido** vira
/// [PagamentoStatus.atrasado] (regra de [resolveChargeStatus]). `Pago` e
/// `Desconsiderado` passam intactos. Sem data de vencimento, mantém o status
/// base. [hoje] permite testar.
PagamentoStatus pagamentoStatusEfetivo({
  required dynamic rawStatus,
  required dynamic dataVencimento,
  DateTime? hoje,
}) {
  final base = pagamentoStatusFromInt(rawStatus);
  if (base == PagamentoStatus.pago ||
      base == PagamentoStatus.desconsiderado) {
    return base;
  }
  final venc = _parseVenc(dataVencimento);
  if (venc == null) return base;
  final ef = resolveChargeStatus(
    dueDate: venc,
    today: hoje ?? DateTime.now(),
    paid: false,
  );
  // pending → preserva o rótulo original (pendente OU previsto).
  return ef == EffectiveChargeStatus.overdue
      ? PagamentoStatus.atrasado
      : base;
}

/// Só `Pago` entra como valor recebido para a academia.
bool pagamentoContaComoReceita(PagamentoStatus s) => s == PagamentoStatus.pago;

/// Pendência aberta do ponto de vista do aluno: Pendente ou Atrasado.
/// `Previsto` (mês futuro) e `Desconsiderado` NÃO são pendência.
bool pagamentoEhPendenciaAberta(PagamentoStatus s) =>
    s == PagamentoStatus.pendente || s == PagamentoStatus.atrasado;

/// Mês de referência "YYYY-MM" de uma cobrança: usa `mes_referencia` se houver,
/// senão deriva do `data_vencimento`, senão string vazia.
String pagamentoMesReferencia(Map<String, dynamic> p) {
  final mr = (p['mes_referencia'] ?? p['mesReferencia'])?.toString().trim();
  if (mr != null && RegExp(r'^\d{4}-\d{2}').hasMatch(mr)) {
    return mr.substring(0, 7);
  }
  final venc = _parseVenc(p['data_vencimento'] ?? p['dataVencimento']);
  if (venc == null) return '';
  return '${venc.year.toString().padLeft(4, '0')}-'
      '${venc.month.toString().padLeft(2, '0')}';
}
