import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/frequencia_treino.dart';

void main() {
  // Quinta-feira, 20:00 — Firestore weekday: 0=Dom..6=Sáb -> quinta = 4.
  final agora = DateTime(2026, 3, 12, 20, 0);

  List<Map<String, dynamic>> horariosQuinta() => [
    {'turma_id': 't1', 'dia_semana': 4, 'hora_inicio': '19:00'},
  ];

  test('sem matrícula/horário: tudo zero', () {
    final r = calcularFrequencia(
      presencas: const [],
      matriculas: const [],
      horarios: const [],
      agora: agora,
    );
    expect(r.totalTreinos, 0);
    expect(r.totalPresencas, 0);
    expect(r.totalFaltas, 0);
  });

  test('conta sessões desde a matrícula e marca falta só após 24h', () {
    // Matriculado dia 26/02 (quinta anterior). Quintas até 12/03 20h:
    // 26/02, 05/03, 12/03. A de 12/03 (hoje 19h) já aconteceu mas está
    // dentro das 24h -> não é falta ainda.
    final r = calcularFrequencia(
      presencas: const [],
      matriculas: [
        {'turma_id': 't1', 'criado_em': '2026-02-26T10:00:00'},
      ],
      horarios: horariosQuinta(),
      agora: agora,
    );
    expect(r.totalTreinos, 3); // 3 aulas já aconteceram
    expect(r.totalFaltas, 2); // só 26/02 e 05/03 passaram das 24h
  });

  test('presença cobre a falta daquele dia/turma', () {
    final r = calcularFrequencia(
      presencas: [
        {'turma_id': 't1', 'data': '2026-02-26'},
      ],
      matriculas: [
        {'turma_id': 't1', 'criado_em': '2026-02-01T10:00:00'},
      ],
      horarios: horariosQuinta(),
      agora: agora,
    );
    expect(r.totalPresencas, 1);
    // Quintas de fevereiro/março até 12/03: 05,12,19,26/02 e 05,12/03 = 6.
    // Fora da janela de 24h e sem presença: 05,12,19/02 e 05/03 = 4.
    expect(r.totalFaltas, 4);
  });

  test('só considera o ano corrente', () {
    final r = calcularFrequencia(
      presencas: [
        {'turma_id': 't1', 'data': '2025-11-20'}, // ano passado, ignora
        {'turma_id': 't1', 'data': '2026-02-26'},
      ],
      matriculas: [
        {'turma_id': 't1', 'criado_em': '2025-01-01T00:00:00'},
      ],
      horarios: horariosQuinta(),
      agora: agora,
    );
    expect(r.totalPresencas, 1); // só a de 2026
  });

  test('aula ainda no futuro do dia não entra', () {
    // agora = quinta 10:00 (antes da aula das 19h)
    final r = calcularFrequencia(
      presencas: const [],
      matriculas: [
        {'turma_id': 't1', 'criado_em': '2026-03-12T00:00:00'},
      ],
      horarios: horariosQuinta(),
      agora: DateTime(2026, 3, 12, 10, 0),
    );
    expect(r.totalTreinos, 0);
    expect(r.totalFaltas, 0);
  });
}
