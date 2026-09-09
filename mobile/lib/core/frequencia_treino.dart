/// Cálculo de frequência de treino do aluno — compartilhado entre a Home e a
/// tela de Presenças para não duplicar a regra.
///
/// Regras:
/// - Conta a partir de 1º de janeiro do ano corrente (ou da matrícula, se for
///   depois). É sempre "no ano".
/// - Uma sessão só vira FALTA quando já passaram 24h do início da aula sem
///   presença registrada — dá tempo do professor lançar depois, até no fim de
///   semana. Aula ainda dentro da janela fica pendente (não é falta).
/// - Aula cujo horário ainda não chegou não entra em nada.
library;

class ResumoFrequencia {
  /// Sessões que já aconteceram no ano (inclui as pendentes das últimas 24h).
  final int totalTreinos;

  /// Presenças registradas no ano (lista enriquecida, mais recente primeiro
  /// não garantido — ordene na tela).
  final List<Map<String, dynamic>> presencas;

  /// Sessões esperadas sem presença, já fora da janela de 24h.
  final List<Map<String, dynamic>> faltas;

  const ResumoFrequencia({
    required this.totalTreinos,
    required this.presencas,
    required this.faltas,
  });

  int get totalPresencas => presencas.length;
  int get totalFaltas => faltas.length;
}

/// [presencas], [matriculas] e [horarios] vêm crus do `firestoreService`.
/// [turmaNome] mapeia `turmaId -> nome` (opcional, só enriquece os itens).
ResumoFrequencia calcularFrequencia({
  required List<Map<String, dynamic>> presencas,
  required List<Map<String, dynamic>> matriculas,
  required List<Map<String, dynamic>> horarios,
  Map<String, String> turmaNome = const {},
  DateTime? agora,
}) {
  final now = agora ?? DateTime.now();
  final inicioAno = DateTime(now.year, 1, 1);

  final presencasAno = presencas
      .where((p) {
        final d = _parseDate(p['data']?.toString());
        return d != null && d.year == now.year;
      })
      .map((p) {
        final turmaId = p['turma_id']?.toString() ?? '';
        return <String, dynamic>{
          ...p,
          'tipo': 'presente',
          'nomeTurma': p['nomeTurma'] ?? turmaNome[turmaId] ?? '',
          'horaCheckin': p['hora_checkin'] ?? p['horaCheckin'],
        };
      })
      .toList();

  // Por turma: dia da semana (0=Dom..6=Sáb) -> minuto de início mais cedo.
  final horariosPorTurma = <String, Map<int, int>>{};
  for (final h in horarios) {
    final turmaId = (h['turma_id'] ?? '').toString();
    if (turmaId.isEmpty) continue;
    final dia = _diaSemana(h['dia_semana'] ?? h['diaSemana']);
    if (dia == null) continue;
    final min = _minutos(h['hora_inicio'] ?? h['horaInicio']);
    final mapa = horariosPorTurma.putIfAbsent(turmaId, () => <int, int>{});
    mapa[dia] = mapa.containsKey(dia)
        ? (min < mapa[dia]! ? min : mapa[dia]!)
        : min;
  }

  final sessoes = <Map<String, dynamic>>[];
  for (final m in matriculas) {
    final turmaId = (m['turma_id'] ?? '').toString();
    final dias = horariosPorTurma[turmaId];
    if (turmaId.isEmpty || dias == null || dias.isEmpty) continue;

    var desde = _parseDate(m['criado_em']?.toString()) ?? inicioAno;
    desde = DateTime(desde.year, desde.month, desde.day);
    if (desde.isBefore(inicioAno)) desde = inicioAno;

    for (var d = desde; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
      final min = dias[d.weekday % 7];
      if (min == null) continue;
      final inicioAula = DateTime(
        d.year,
        d.month,
        d.day,
      ).add(Duration(minutes: min));
      if (inicioAula.isAfter(now)) continue; // aula ainda não aconteceu
      sessoes.add({
        'turma_id': turmaId,
        'nomeTurma': turmaNome[turmaId] ?? '',
        'dia': _diaChave(inicioAula),
        'data': inicioAula.toIso8601String(),
        'tipo': 'falta',
        'graceOver': now.isAfter(inicioAula.add(const Duration(hours: 24))),
      });
    }
  }

  final coberturaTurmaDia = <String>{
    for (final p in presencasAno)
      '${p['turma_id'] ?? ''}|${_diaChaveStr(p['data']?.toString())}',
  };
  final coberturaDiaSemTurma = <String>{
    for (final p in presencasAno)
      if ((p['turma_id'] ?? '').toString().isEmpty)
        _diaChaveStr(p['data']?.toString()),
  };

  final faltas = sessoes.where((s) {
    if (s['graceOver'] != true) return false;
    final dia = s['dia'] as String;
    if (coberturaTurmaDia.contains('${s['turma_id']}|$dia')) return false;
    if (coberturaDiaSemTurma.contains(dia)) return false;
    return true;
  }).toList();

  final total = sessoes.length < presencasAno.length
      ? presencasAno.length
      : sessoes.length;

  return ResumoFrequencia(
    totalTreinos: total,
    presencas: presencasAno,
    faltas: faltas,
  );
}

DateTime? _parseDate(String? s) {
  if (s == null) return null;
  try {
    return DateTime.parse(s);
  } catch (_) {
    return null;
  }
}

int _minutos(dynamic raw) {
  final partes = (raw ?? '').toString().split(':');
  if (partes.length < 2) return 0;
  return (int.tryParse(partes[0]) ?? 0) * 60 + (int.tryParse(partes[1]) ?? 0);
}

int? _diaSemana(dynamic raw) {
  if (raw is num) {
    final v = raw.toInt();
    return (v >= 0 && v <= 6) ? v : null;
  }
  const nomes = [
    'domingo',
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
  ];
  final i = nomes.indexOf((raw ?? '').toString().toLowerCase());
  return i < 0 ? null : i;
}

String _diaChave(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _diaChaveStr(String? s) {
  final raw = s ?? '';
  return raw.length >= 10 ? raw.substring(0, 10) : raw;
}
