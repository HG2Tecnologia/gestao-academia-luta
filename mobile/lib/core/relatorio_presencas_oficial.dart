/// Relatório oficial de presenças/faltas — pensado para emissão mensal/anual
/// (ex.: academias de projeto social que precisam prestar contas a um órgão
/// público). Separado de `relatorio_presencas.dart` (usado pela tela de
/// insight interna) porque aquele calcula falta de forma ingênua (dias que
/// alguém da turma treinou − dias que o aluno veio, sem olhar data de
/// matrícula). Este reaproveita [calcularFrequencia], que já é
/// schedule-aware e testada.
library;

import 'frequencia_treino.dart';

/// Recorte de tempo do relatório. [personalizado] pode cruzar virada de ano —
/// a função principal já lida com isso internamente.
enum TipoPeriodoRelatorio { mes, ano, personalizado }

class LinhaRelatorioPresenca {
  final String alunoId;
  final String nomeAluno;
  final String telefone;
  final bool ativo;
  final String turmaId;
  final String nomeTurma;
  final String faixaNome;
  final int presencas;
  final int faltas;
  final int totalAulas;

  const LinhaRelatorioPresenca({
    required this.alunoId,
    required this.nomeAluno,
    required this.telefone,
    required this.ativo,
    required this.turmaId,
    required this.nomeTurma,
    required this.faixaNome,
    required this.presencas,
    required this.faltas,
    required this.totalAulas,
  });

  double get percentual => totalAulas == 0 ? 0.0 : presencas / totalAulas * 100;
}

String _str(Map<String, dynamic> m, String chave) => (m[chave] ?? '').toString();

/// Monta o relatório: uma linha por par (aluno, turma matriculada). Um aluno
/// em 2 turmas gera 2 linhas, porque presenças/faltas/total de aulas são por
/// turma (cada turma tem seu próprio horário).
///
/// [turmaId] filtra pra uma turma só; `null` = todas as turmas visíveis pra
/// quem está gerando o relatório (a tela já filtra turmas por permissão
/// antes de chamar esta função).
///
/// [limitesPorTurmaPorAluno] (opcional) é `alunoId -> (turmaId -> limite
/// semanal do plano)` — mesmo formato usado por
/// `FirestoreService.getLimitesDiasSemanaPorTurma`, resolvido pela tela
/// (que faz I/O) e passado pronto aqui pra manter esta função pura/testável.
List<LinhaRelatorioPresenca> montarRelatorioPresencasOficial({
  required List<Map<String, dynamic>> alunos,
  required List<Map<String, dynamic>> matriculas,
  required List<Map<String, dynamic>> presencas,
  required List<Map<String, dynamic>> horarios,
  required List<Map<String, dynamic>> turmas,
  required List<Map<String, dynamic>> graduacoesDetalhadas,
  required DateTime de,
  required DateTime ate,
  String? turmaId,
  bool contabilizarFaltaAutomatica = true,
  Map<String, Map<String, int>> limitesPorTurmaPorAluno = const {},
}) {
  final alunosPorId = <String, Map<String, dynamic>>{
    for (final a in alunos)
      if (_str(a, 'id').isNotEmpty) _str(a, 'id'): a,
  };
  final turmasPorId = <String, Map<String, dynamic>>{
    for (final t in turmas)
      if (_str(t, 'id').isNotEmpty) _str(t, 'id'): t,
  };
  final horariosPorTurma = <String, List<Map<String, dynamic>>>{};
  for (final h in horarios) {
    final tid = _str(h, 'turma_id');
    if (tid.isEmpty) continue;
    horariosPorTurma.putIfAbsent(tid, () => []).add(h);
  }

  // Faixa aprovada de maior ordem/grau por (aluno, modalidade).
  final faixaPorAlunoModalidade = <String, Map<String, dynamic>>{};
  for (final g in graduacoesDetalhadas) {
    if (g['aprovado'] != true) continue;
    final alunoId = _str(g, 'aluno_id');
    final modalidadeId = _str(g, 'modalidadeId');
    if (alunoId.isEmpty || modalidadeId.isEmpty) continue;
    final chave = '$alunoId|$modalidadeId';
    final ordem = (g['faixaOrdem'] as num?)?.toInt() ?? 0;
    final grau = (g['grau'] as num?)?.toInt() ?? 0;
    final atual = faixaPorAlunoModalidade[chave];
    final ordemAtual = atual == null ? -1 : (atual['faixaOrdem'] as num?)?.toInt() ?? -1;
    final grauAtual = atual == null ? -1 : (atual['grau'] as num?)?.toInt() ?? -1;
    if (atual == null || ordem > ordemAtual || (ordem == ordemAtual && grau > grauAtual)) {
      faixaPorAlunoModalidade[chave] = g;
    }
  }

  final matriculasRelevantes = matriculas.where((m) {
    if (m['ativo'] == false) return false;
    if (turmaId != null && _str(m, 'turma_id') != turmaId) return false;
    return _str(m, 'turma_id').isNotEmpty && _str(m, 'aluno_id').isNotEmpty;
  }).toList();

  final linhas = <LinhaRelatorioPresenca>[];
  for (final m in matriculasRelevantes) {
    final alunoId = _str(m, 'aluno_id');
    final turmaIdDaLinha = _str(m, 'turma_id');
    final aluno = alunosPorId[alunoId];
    if (aluno == null) continue;
    final turma = turmasPorId[turmaIdDaLinha];

    final presencasDoPar = presencas
        .where((p) => _str(p, 'aluno_id') == alunoId && _str(p, 'turma_id') == turmaIdDaLinha)
        .toList();
    final horariosDaTurma = horariosPorTurma[turmaIdDaLinha] ?? const [];
    final limiteSemanal = limitesPorTurmaPorAluno[alunoId]?[turmaIdDaLinha];

    final resumo = _calcularNoIntervalo(
      presencas: presencasDoPar,
      matriculas: [m],
      horarios: horariosDaTurma,
      limitesPorTurma: limiteSemanal == null ? const {} : {turmaIdDaLinha: limiteSemanal},
      contabilizarFaltaAutomatica: contabilizarFaltaAutomatica,
      de: de,
      ate: ate,
    );

    final modalidadeId = (turma?['modalidadeId'] ?? turma?['modalidade_id'])?.toString() ?? '';
    final faixa = faixaPorAlunoModalidade['$alunoId|$modalidadeId'];

    linhas.add(
      LinhaRelatorioPresenca(
        alunoId: alunoId,
        nomeAluno: _str(aluno, 'nome'),
        telefone: _str(aluno, 'telefone'),
        ativo: aluno['ativo'] != false,
        turmaId: turmaIdDaLinha,
        nomeTurma: _str(turma ?? const {}, 'nome'),
        faixaNome: faixa == null ? '' : _str(faixa, 'nomeFaixa'),
        presencas: resumo.totalPresencas,
        faltas: resumo.totalFaltas,
        totalAulas: resumo.totalPresencas + resumo.totalFaltas,
      ),
    );
  }

  linhas.sort((a, b) {
    final nome = a.nomeAluno.toLowerCase().compareTo(b.nomeAluno.toLowerCase());
    return nome != 0 ? nome : a.nomeTurma.toLowerCase().compareTo(b.nomeTurma.toLowerCase());
  });
  return linhas;
}

/// `calcularFrequencia` sempre conta "no ano de `agora`" (1/jan até `agora`).
/// Pra cobrir qualquer [de]..[ate] (inclusive cruzando virada de ano), roda a
/// função uma vez por ano do intervalo (com `agora` = fim daquele ano ou fim
/// do intervalo, o que vier primeiro) e junta os resultados, recortando pro
/// intervalo exato no fim.
ResumoFrequencia _calcularNoIntervalo({
  required List<Map<String, dynamic>> presencas,
  required List<Map<String, dynamic>> matriculas,
  required List<Map<String, dynamic>> horarios,
  required Map<String, int> limitesPorTurma,
  required bool contabilizarFaltaAutomatica,
  required DateTime de,
  required DateTime ate,
}) {
  final presencasTotal = <Map<String, dynamic>>[];
  final faltasTotal = <Map<String, dynamic>>[];
  var totalTreinos = 0;

  for (var ano = de.year; ano <= ate.year; ano++) {
    final fimDoAno = DateTime(ano, 12, 31, 23, 59, 59);
    final agora = fimDoAno.isBefore(ate) ? fimDoAno : ate;

    final resumoAno = calcularFrequencia(
      presencas: presencas,
      matriculas: matriculas,
      horarios: horarios,
      limitesPorTurma: limitesPorTurma,
      contabilizarFaltaAutomatica: contabilizarFaltaAutomatica,
      agora: agora,
    );

    bool noIntervalo(String? dataIso) {
      if (dataIso == null || dataIso.length < 10) return false;
      final d = DateTime.tryParse(dataIso.substring(0, 10));
      if (d == null) return false;
      final diaDe = DateTime(de.year, de.month, de.day);
      final diaAte = DateTime(ate.year, ate.month, ate.day);
      return !d.isBefore(diaDe) && !d.isAfter(diaAte);
    }

    presencasTotal.addAll(
      resumoAno.presencas.where((p) => noIntervalo(p['data']?.toString())),
    );
    faltasTotal.addAll(
      resumoAno.faltas.where((f) => noIntervalo(f['dia']?.toString())),
    );
    // totalTreinos do ano já é "sessões + presenças órfãs" até `agora`; como
    // só nos interessa a fatia dentro do intervalo, recompomos a partir das
    // listas recortadas abaixo (mais simples e sempre consistente).
  }

  totalTreinos = presencasTotal.length + faltasTotal.length;

  return ResumoFrequencia(
    totalTreinos: totalTreinos,
    presencas: presencasTotal,
    faltas: faltasTotal,
  );
}
