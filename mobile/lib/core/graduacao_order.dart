DateTime? _graduacaoDateTime(dynamic value) {
  if (value is DateTime) return value;
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

int _graduacaoInt(Map<String, dynamic> graduacao, String key) {
  final value = graduacao[key];
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _graduacaoModalidade(Map<String, dynamic> graduacao) {
  return (graduacao['modalidadeId'] ??
          graduacao['modalidade_id'] ??
          graduacao['nomeModalidade'] ??
          '')
      .toString();
}

/// Ordena o histórico do registro mais antigo para o mais novo.
///
/// Graduações novas usam o instante exato de criação. Para registros antigos
/// que só possuem a data do exame, a ordem configurada da faixa e o grau
/// garantem uma sequência determinística dentro de cada modalidade.
int compararGraduacoesCronologicamente(
  Map<String, dynamic> a,
  Map<String, dynamic> b,
) {
  final dataA = _graduacaoDateTime(a['dataExame'] ?? a['data_exame']);
  final dataB = _graduacaoDateTime(b['dataExame'] ?? b['data_exame']);
  if (dataA != null && dataB != null) {
    final comparacaoData = dataA.compareTo(dataB);
    if (comparacaoData != 0) return comparacaoData;
  } else if (dataA != null) {
    return -1;
  } else if (dataB != null) {
    return 1;
  }

  final criadoA = _graduacaoDateTime(a['criadoEm'] ?? a['criado_em']);
  final criadoB = _graduacaoDateTime(b['criadoEm'] ?? b['criado_em']);
  if (criadoA != null && criadoB != null) {
    final comparacaoCriacao = criadoA.compareTo(criadoB);
    if (comparacaoCriacao != 0) return comparacaoCriacao;
  } else if (criadoA != null) {
    // Mantém o bloco legado (sem horário) antes dos registros timestampados.
    return 1;
  } else if (criadoB != null) {
    return -1;
  }

  final comparacaoModalidade =
      _graduacaoModalidade(a).compareTo(_graduacaoModalidade(b));
  if (comparacaoModalidade != 0) return comparacaoModalidade;

  final comparacaoFaixa = _graduacaoInt(a, 'faixaOrdem')
      .compareTo(_graduacaoInt(b, 'faixaOrdem'));
  if (comparacaoFaixa != 0) return comparacaoFaixa;

  final comparacaoGrau =
      _graduacaoInt(a, 'grau').compareTo(_graduacaoInt(b, 'grau'));
  if (comparacaoGrau != 0) return comparacaoGrau;

  return (a['id'] ?? '').toString().compareTo((b['id'] ?? '').toString());
}

/// Compara somente a progressão da graduação, independentemente do nome das
/// faixas. A data serve apenas para desempatar registros da mesma faixa/grau.
int compararProgressaoGraduacoes(
  Map<String, dynamic> a,
  Map<String, dynamic> b,
) {
  final comparacaoFaixa = _graduacaoInt(a, 'faixaOrdem')
      .compareTo(_graduacaoInt(b, 'faixaOrdem'));
  if (comparacaoFaixa != 0) return comparacaoFaixa;

  final comparacaoGrau =
      _graduacaoInt(a, 'grau').compareTo(_graduacaoInt(b, 'grau'));
  if (comparacaoGrau != 0) return comparacaoGrau;

  return compararGraduacoesCronologicamente(a, b);
}

/// Calcula as faixas vigentes exclusivamente a partir do histórico aprovado.
/// O primeiro mapa é indexado pelo aluno e o segundo pela modalidade.
Map<String, Map<String, Map<String, dynamic>>> montarFaixasAtuaisPorAluno(
  Iterable<Map<String, dynamic>> graduacoes,
) {
  final resultado = <String, Map<String, Map<String, dynamic>>>{};
  final graduacoesEscolhidas = <String, Map<String, Map<String, dynamic>>>{};

  for (final graduacao in graduacoes) {
    if (graduacao['aprovado'] != true) continue;
    final alunoId =
        (graduacao['alunoId'] ?? graduacao['aluno_id'] ?? '').toString();
    final modalidadeId = _graduacaoModalidade(graduacao);
    if (alunoId.isEmpty || modalidadeId.isEmpty) continue;

    final escolhidasAluno = graduacoesEscolhidas.putIfAbsent(
      alunoId,
      () => <String, Map<String, dynamic>>{},
    );
    final atual = escolhidasAluno[modalidadeId];
    if (atual != null &&
        compararProgressaoGraduacoes(graduacao, atual) <= 0) {
      continue;
    }
    escolhidasAluno[modalidadeId] = graduacao;

    resultado.putIfAbsent(
      alunoId,
      () => <String, Map<String, dynamic>>{},
    )[modalidadeId] = <String, dynamic>{
      'modalidadeId': modalidadeId,
      'modalidadeNome': graduacao['nomeModalidade'] ?? '',
      'faixaId': graduacao['faixaId'] ?? graduacao['faixa_id'] ?? '',
      'faixaNome': graduacao['nomeFaixa'] ?? '',
      'faixaCor': graduacao['corFaixa'] ?? '#FFFFFF',
      'faixaCorBarra': graduacao['corBarraFaixa'] ?? '#000000',
      'faixaTemGraus': graduacao['faixaTemGraus'] == true,
      'faixaMaxGraus':
          (graduacao['faixaMaxGraus'] as num?)?.toInt() ?? 0,
      'faixaOrdem': (graduacao['faixaOrdem'] as num?)?.toInt() ?? 0,
      'grau': (graduacao['grau'] as num?)?.toInt() ?? 0,
    };
  }

  return resultado;
}
