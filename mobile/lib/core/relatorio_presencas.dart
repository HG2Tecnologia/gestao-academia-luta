String _idAluno(Map<String, dynamic> item) {
  return (item['aluno_id'] ?? item['alunoId'] ?? '').toString();
}

String _nomeAluno(Map<String, dynamic> item) {
  return (item['nome'] ?? item['nome_aluno'] ?? item['nomeAluno'] ?? '')
      .toString()
      .trim();
}

String _dataPresenca(Map<String, dynamic> presenca) {
  return (presenca['data'] ?? presenca['data_presenca'] ?? '').toString();
}

/// Consolida presenças com as matrículas e os cadastros de alunos da turma.
/// Não altera os dados de origem e conta no máximo uma presença por aluno/dia.
Map<String, dynamic> montarRelatorioPresencas({
  required List<Map<String, dynamic>> presencas,
  required List<Map<String, dynamic>> matriculas,
  required List<Map<String, dynamic>> alunos,
}) {
  final alunosPorId = <String, Map<String, dynamic>>{
    for (final aluno in alunos)
      if ((aluno['id'] ?? '').toString().isNotEmpty)
        (aluno['id'] ?? '').toString(): aluno,
  };

  final datasAulas = presencas
      .map(_dataPresenca)
      .where((data) => data.isNotEmpty)
      .toSet();
  final totalAulas = datasAulas.length;

  final presencasPorAluno = <String, Set<String>>{};
  final nomesPorAluno = <String, String>{};

  // Inclui quem está matriculado mesmo quando não teve presença no período.
  for (final matricula in matriculas) {
    if (matricula['ativo'] == false) continue;
    final alunoId = _idAluno(matricula);
    if (alunoId.isEmpty) continue;
    final aluno = alunosPorId[alunoId];
    if (aluno?['ativo'] == false) continue;
    presencasPorAluno.putIfAbsent(alunoId, () => <String>{});
    nomesPorAluno[alunoId] = _nomeAluno(aluno ?? matricula);
  }

  // Mantém no relatório presenças históricas mesmo se a matrícula foi encerrada.
  for (final presenca in presencas) {
    final alunoId = _idAluno(presenca);
    final data = _dataPresenca(presenca);
    if (alunoId.isEmpty || data.isEmpty) continue;
    presencasPorAluno.putIfAbsent(alunoId, () => <String>{}).add(data);
    if ((nomesPorAluno[alunoId] ?? '').isEmpty) {
      nomesPorAluno[alunoId] = _nomeAluno(alunosPorId[alunoId] ?? presenca);
    }
  }

  final alunosRelatorio = presencasPorAluno.entries.map((entry) {
    final totalPresencas = entry.value.length;
    final faltas = totalAulas > totalPresencas
        ? totalAulas - totalPresencas
        : 0;
    final percentual = totalAulas == 0
        ? 0.0
        : totalPresencas / totalAulas * 100;
    final nome = nomesPorAluno[entry.key] ?? '';
    return <String, dynamic>{
      'alunoId': entry.key,
      'nomeAluno': nome.isEmpty ? 'Aluno não identificado' : nome,
      'presencas': totalPresencas,
      'faltas': faltas,
      'percentual': percentual,
    };
  }).toList()
    ..sort((a, b) {
      final percentual = (b['percentual'] as num)
          .compareTo(a['percentual'] as num);
      if (percentual != 0) return percentual;
      return (a['nomeAluno'] as String)
          .toLowerCase()
          .compareTo((b['nomeAluno'] as String).toLowerCase());
    });

  final mediaFrequencia = alunosRelatorio.isEmpty
      ? 0.0
      : alunosRelatorio.fold<double>(
            0,
            (soma, aluno) =>
                soma + (aluno['percentual'] as num).toDouble(),
          ) /
          alunosRelatorio.length;

  return <String, dynamic>{
    'totalAulas': totalAulas,
    'mediaFrequencia': mediaFrequencia,
    'alunos': alunosRelatorio,
  };
}
