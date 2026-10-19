/// Cálculo puro das cores de cada grau de uma faixa, para o recurso
/// opcional de "graus coloridos" (ex.: sistema infantil da IBJJF/CBJJ).
///
/// Não lê nem escreve Firestore — recebe os dados já resolvidos e devolve a
/// lista de cores (uma por grau, índice 0 = 1º grau). Faixas que nunca
/// configuram isso simplesmente não chamam nada daqui; o campo `grau_cores`
/// fica ausente, e toda a exibição (BeltBadge/_BeltVisual) cai no
/// comportamento de hoje (uma única cor de ponteira).
library;

const String kGrauCoresPresetOficialIbjjf = 'oficial_ibjjf';
const String kGrauCoresPresetSimplificado = 'simplificado';
const String kGrauCoresPresetPersonalizado = 'personalizado';

const List<String> kPresetsGrauCores = [
  kGrauCoresPresetOficialIbjjf,
  kGrauCoresPresetSimplificado,
  kGrauCoresPresetPersonalizado,
];

/// Sistema "Mensal" da IBJJF/CBJJ (infantil, 4 a 15 anos): os 4 primeiros
/// graus são brancos, os 4 seguintes vermelhos, e os restantes usam a cor da
/// PRÓXIMA faixa na sequência (ex.: branca→cinza usa cinza nos últimos
/// graus). Se não houver próxima faixa (ex.: última faixa antes da fase
/// adulta) ou a cor não for informada, usa preto como fallback neutro.
List<String> calcularGrauCoresOficialIbjjf({
  required int maxGraus,
  String? corProximaFaixaHex,
}) {
  if (maxGraus <= 0) return const [];
  const branco = '#FFFFFF';
  const vermelho = '#FF0000';
  final corResto = (corProximaFaixaHex == null || corProximaFaixaHex.isEmpty)
      ? '#000000'
      : corProximaFaixaHex;
  return List.generate(maxGraus, (i) {
    if (i < 4) return branco;
    if (i < 8) return vermelho;
    return corResto;
  });
}

/// Modelo simplificado (popular em várias academias, embora não seja a
/// regra oficial da IBJJF): a academia escolhe N cores fixas e elas se
/// repetem em blocos iguais até preencher `maxGraus`. Ex.: 3 cores e 12
/// graus → 4 de cada, na ordem escolhida (branco, vermelho, amarelo).
List<String> calcularGrauCoresEmBlocos({
  required int maxGraus,
  required List<String> cores,
}) {
  if (maxGraus <= 0 || cores.isEmpty) return const [];
  final blockSize = (maxGraus / cores.length).ceil();
  return List.generate(maxGraus, (i) {
    final idx = (i ~/ blockSize).clamp(0, cores.length - 1);
    return cores[idx];
  });
}

/// Índices (na lista `cores`) que NUNCA vão aparecer no resultado de
/// [calcularGrauCoresEmBlocos] com esse `maxGraus` — ex.: 3 cores mas só 4
/// graus no total faz a 3ª cor nunca ser alcançada (os 4 graus inteiros já
/// se esgotam nos 2 primeiros blocos). Usado pra avisar a academia ANTES
/// de salvar, em vez de ela só notar depois que uma cor "sumiu".
List<int> indicesDeCoresIgnoradasEmBlocos({
  required int maxGraus,
  required List<String> cores,
}) {
  if (maxGraus <= 0 || cores.isEmpty) return const [];
  final blockSize = (maxGraus / cores.length).ceil();
  final usados = <int>{};
  for (var i = 0; i < maxGraus; i++) {
    usados.add((i ~/ blockSize).clamp(0, cores.length - 1));
  }
  return [
    for (var k = 0; k < cores.length; k++)
      if (!usados.contains(k)) k,
  ];
}

/// Modalidades (por id) em que cada aluno está ELEGÍVEL pra graus
/// coloridos — baseado em matrícula ATIVA numa turma dessa modalidade que
/// ligou o recurso (`usa_graus_coloridos`). Uma faixa pode ter `grau_cores`
/// configurado, mas isso só é exibido pro aluno se ele estiver numa turma
/// que optou por isso — ex.: a mesma modalidade "Jiu-Jitsu" pode ter turma
/// Kids (colorido) e turma Adulto (sem colorido) ao mesmo tempo.
///
/// Puro: recebe os dados já carregados (matrículas + turmas), nunca lê
/// Firestore. `turmasPorId` é um mapa id→doc de turma.
Map<String, Set<String>> montarElegibilidadeGrausColoridosPorAluno({
  required Iterable<Map<String, dynamic>> matriculas,
  required Map<String, Map<String, dynamic>> turmasPorId,
}) {
  final resultado = <String, Set<String>>{};
  for (final m in matriculas) {
    if (m['ativo'] != true) continue;
    final alunoId = (m['aluno_id'] ?? '').toString();
    final turmaId = (m['turma_id'] ?? '').toString();
    if (alunoId.isEmpty || turmaId.isEmpty) continue;
    final turma = turmasPorId[turmaId];
    if (turma == null || turma['usa_graus_coloridos'] != true) continue;
    final modalidadeId =
        (turma['modalidadeId'] ?? turma['modalidade_id'] ?? '').toString();
    if (modalidadeId.isEmpty) continue;
    resultado.putIfAbsent(alunoId, () => <String>{}).add(modalidadeId);
  }
  return resultado;
}

/// Ajusta uma lista de cores personalizada ao `maxGraus` atual: trunca se
/// tiver cores a mais, completa repetindo a última cor se faltar — nunca
/// deixa a lista vazia nem maior que `maxGraus` (evita índice fora da faixa
/// na hora de desenhar).
List<String> ajustarGrauCoresPersonalizado({
  required int maxGraus,
  required List<String> coresAtuais,
  String corPadrao = '#FFFFFF',
}) {
  if (maxGraus <= 0) return const [];
  if (coresAtuais.length == maxGraus) return List.of(coresAtuais);
  final resultado = List<String>.of(coresAtuais.take(maxGraus));
  final ultima = resultado.isNotEmpty ? resultado.last : corPadrao;
  while (resultado.length < maxGraus) {
    resultado.add(ultima);
  }
  return resultado;
}
