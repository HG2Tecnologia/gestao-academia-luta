import 'pagamento_status.dart';

/// Agregações puras do Financeiro — sem Firestore, sem widget. Fonte única para
/// os números da tela da academia e para as listas do app do aluno, de modo que
/// os dois lados nunca divirjam.

// ─── Academia: os 4 cards de resumo ─────────────────────────────────────────

class ResumoFinanceiro {
  final double totalRecebidoMes;
  final double totalPendenteMes;
  final double totalAtrasado;
  final int alunosInadimplentes;
  final int qtdRecebido;
  final int qtdPendente;
  final int qtdAtrasado;

  const ResumoFinanceiro({
    this.totalRecebidoMes = 0,
    this.totalPendenteMes = 0,
    this.totalAtrasado = 0,
    this.alunosInadimplentes = 0,
    this.qtdRecebido = 0,
    this.qtdPendente = 0,
    this.qtdAtrasado = 0,
  });

  Map<String, dynamic> toMap() => {
    'totalRecebidoMes': totalRecebidoMes,
    'totalPendenteMes': totalPendenteMes,
    'totalAtrasado': totalAtrasado,
    'alunosInadimplentes': alunosInadimplentes,
    'qtdRecebido': qtdRecebido,
    'qtdPendente': qtdPendente,
    'qtdAtrasado': qtdAtrasado,
  };
}

double _valorRecebido(Map<String, dynamic> p) {
  final pago = (p['valor_pago'] as num?)?.toDouble();
  return pago ?? (p['valor'] as num? ?? 0).toDouble();
}

DateTime? _venc(Map<String, dynamic> p) {
  final v = p['data_vencimento'] ?? p['dataVencimento'];
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

/// Resumo dos 4 cards da tela da academia. Regras (idênticas ao comportamento
/// histórico):
///  * **Recebido**: `Pago` com vencimento em [ano]/[mes].
///  * **Pendente**: `Pendente`/`Previsto` com vencimento em [ano]/[mes].
///  * **Atrasado**: `Pendente`/`Previsto` já vencido (de qualquer mês).
///  * **Inadimplentes**: alunos distintos com alguma cobrança atrasada.
///  * `Desconsiderado` é ignorado por completo — nunca entra em nenhum total.
///
/// Uma mesma cobrança pode contar em **Pendente** (vence no mês) e em
/// **Atrasado** (já passou do vencimento) ao mesmo tempo — assim como antes.
ResumoFinanceiro resumoFinanceiroAcademia(
  List<Map<String, dynamic>> pagamentos, {
  required int ano,
  required int mes,
  DateTime? hoje,
}) {
  final agora = hoje ?? DateTime.now();
  final hojeData = DateTime(agora.year, agora.month, agora.day);

  double recebido = 0, pendente = 0, atrasado = 0;
  int qRecebido = 0, qPendente = 0, qAtrasado = 0;
  final inadimplentes = <String>{};

  for (final p in pagamentos) {
    final base = pagamentoStatusFromInt(p['status']);
    if (base == PagamentoStatus.desconsiderado) continue;

    final valor = _valorRecebido(p);
    final venc = _venc(p);
    final vencNoMes = venc != null && venc.year == ano && venc.month == mes;

    if (base == PagamentoStatus.pago) {
      if (vencNoMes) {
        recebido += valor;
        qRecebido++;
      }
    } else if (base == PagamentoStatus.pendente ||
        base == PagamentoStatus.previsto) {
      if (vencNoMes) {
        pendente += valor;
        qPendente++;
      }
      if (venc != null &&
          DateTime(venc.year, venc.month, venc.day).isBefore(hojeData)) {
        atrasado += valor;
        qAtrasado++;
        final aluno = p['aluno_id']?.toString() ?? '';
        if (aluno.isNotEmpty) inadimplentes.add(aluno);
      }
    }
  }

  return ResumoFinanceiro(
    totalRecebidoMes: recebido,
    totalPendenteMes: pendente,
    totalAtrasado: atrasado,
    alunosInadimplentes: inadimplentes.length,
    qtdRecebido: qRecebido,
    qtdPendente: qPendente,
    qtdAtrasado: qAtrasado,
  );
}

// ─── App do aluno: linhas + agregações ──────────────────────────────────────

/// Uma cobrança já resolvida para exibição no app do aluno.
class CobrancaAluno {
  /// String canônica: `Pendente` | `Pago` | `Atrasado` | `Previsto` |
  /// `Desconsiderado`.
  final String status;

  /// Mês de referência `YYYY-MM`.
  final String mesRef;

  final num valor;

  /// Documento original (para a UI ler `tipo`, `data_vencimento`, etc.).
  final Map<String, dynamic> raw;

  const CobrancaAluno({
    required this.status,
    required this.mesRef,
    required this.valor,
    required this.raw,
  });
}

String _statusString(PagamentoStatus s) {
  switch (s) {
    case PagamentoStatus.pago:
      return 'Pago';
    case PagamentoStatus.atrasado:
      return 'Atrasado';
    case PagamentoStatus.previsto:
      return 'Previsto';
    case PagamentoStatus.desconsiderado:
      return 'Desconsiderado';
    case PagamentoStatus.pendente:
      return 'Pendente';
  }
}

/// Converte os documentos crus de `pagamentos` nas linhas do app do aluno,
/// já com o status efetivo (vencido → Atrasado) e o mês de referência.
List<CobrancaAluno> montarCobrancasAluno(
  List<Map<String, dynamic>> pagamentos, {
  DateTime? hoje,
}) {
  return pagamentos.map((p) {
    final st = pagamentoStatusEfetivo(
      rawStatus: p['status'],
      dataVencimento: p['data_vencimento'] ?? p['dataVencimento'],
      hoje: hoje,
    );
    return CobrancaAluno(
      status: _statusString(st),
      mesRef: pagamentoMesReferencia(p),
      valor: (p['valor'] as num?) ?? 0,
      raw: p,
    );
  }).toList();
}

int _cmpVenc(CobrancaAluno a, CobrancaAluno b) =>
    (a.raw['data_vencimento'] ?? '').toString().compareTo(
      (b.raw['data_vencimento'] ?? '').toString(),
    );

/// Total em aberto (Pendente + Atrasado) somando **todos os meses**.
/// `Previsto` e `Desconsiderado` não entram.
num totalEmAbertoAluno(List<CobrancaAluno> cobrancas) => cobrancas
    .where((c) => c.status == 'Pendente' || c.status == 'Atrasado')
    .fold<num>(0, (soma, c) => soma + c.valor);

/// Quantas cobranças têm exatamente [status], em todos os meses.
int contarStatusAluno(List<CobrancaAluno> cobrancas, String status) =>
    cobrancas.where((c) => c.status == status).length;

/// Todas as atrasadas de qualquer mês, ordenadas por vencimento.
List<CobrancaAluno> atrasadasAluno(List<CobrancaAluno> cobrancas) =>
    cobrancas.where((c) => c.status == 'Atrasado').toList()..sort(_cmpVenc);

/// Cobranças de um mês `YYYY-MM`, ordenadas por vencimento.
List<CobrancaAluno> cobrancasDoMesAluno(
  List<CobrancaAluno> cobrancas,
  String mesRef,
) => cobrancas.where((c) => c.mesRef == mesRef).toList()..sort(_cmpVenc);
