import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/frequencia_treino.dart';

void main() {
  // Quinta-feira, 20:00 — Firestore weekday: 0=Dom..6=Sáb -> quinta = 4.
  final agora = DateTime(2026, 3, 12, 20, 0);

  List<Map<String, dynamic>> horariosQuinta() => [
    {'turma_id': 't1', 'dia_semana': 4, 'hora_inicio': '19:00'},
  ];

  // Segunda(1), quarta(3) e sexta(5) — mesma convenção 0=Dom..6=Sáb.
  List<Map<String, dynamic>> horariosSegQuaSex() => [
    {'turma_id': 't1', 'dia_semana': 1, 'hora_inicio': '19:00'},
    {'turma_id': 't1', 'dia_semana': 3, 'hora_inicio': '19:00'},
    {'turma_id': 't1', 'dia_semana': 5, 'hora_inicio': '19:00'},
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

  test('turma sem nenhum horário cadastrado: nunca gera falta', () {
    // Bug relatado: aluno matriculado numa turma que não tem horários
    // cadastrados (ex.: turma nova, horário ainda não configurado) não pode
    // acumular falta em dia nenhum.
    final r = calcularFrequencia(
      presencas: const [],
      matriculas: [
        {'turma_id': 't2', 'criado_em': '2026-01-01T00:00:00'},
      ],
      horarios: horariosQuinta(), // só tem horário pra t1, não pra t2
      agora: agora,
    );
    expect(r.totalTreinos, 0);
    expect(r.totalFaltas, 0);
  });

  test('só gera falta nos dias em que a turma realmente treina', () {
    // Turma treina só quinta (t1). Nenhum outro dia da semana deve virar
    // sessão/falta, mesmo passando várias semanas.
    final r = calcularFrequencia(
      presencas: const [],
      matriculas: [
        {'turma_id': 't1', 'criado_em': '2026-03-01T00:00:00'},
      ],
      horarios: horariosQuinta(),
      agora: agora,
    );
    // Entre 01/03 e 12/03 só há uma quinta fora da janela de 24h: 05/03.
    expect(r.totalFaltas, 1);
    for (final f in r.faltas) {
      final dia = DateTime.parse(f['data'] as String);
      expect(dia.weekday, DateTime.thursday);
    }
  });

  test('presença sem turma_id (schema antigo) cobre o dia de qualquer turma', () {
    // Reproduz o gap de schema do check-in do professor via QR (só gravava
    // horario_id, sem turma_id) antes da correção em addPresenca — presenças
    // órfãs de turma_id não podem gerar falta falsa no dia em que houve
    // check-in, mesmo sem o vínculo explícito com a turma.
    final r = calcularFrequencia(
      presencas: [
        {'turma_id': '', 'data': '2026-03-05'},
      ],
      matriculas: [
        {'turma_id': 't1', 'criado_em': '2026-03-01T00:00:00'},
      ],
      horarios: horariosQuinta(),
      agora: agora,
    );
    expect(r.totalFaltas, 0);
  });

  test('sem limite semanal: 3ª aula da semana sem presença vira falta normalmente', () {
    // Controle (mesmo cenário do teste seguinte, sem `limitesPorTurma`):
    // prova que sem a config o comportamento de antes se mantém.
    final agoraDomingo = DateTime(2026, 3, 15, 10, 0); // domingo, ainda dentro da mesma semana
    final r = calcularFrequencia(
      presencas: [
        {'turma_id': 't1', 'data': '2026-03-09'}, // segunda
        {'turma_id': 't1', 'data': '2026-03-11'}, // quarta
      ],
      matriculas: [
        {'turma_id': 't1', 'criado_em': '2026-03-09T00:00:00'},
      ],
      horarios: horariosSegQuaSex(),
      agora: agoraDomingo,
    );
    // Sexta (2026-03-13) sem presença e sem limite -> vira falta.
    expect(r.totalFaltas, 1);
  });

  test('plano de 2 dias/semana: 3º dia agendado não vira falta ao atingir a cota', () {
    // Exemplo do pedido: turma treina seg/qua/sex, plano do aluno é de 2
    // dias por semana. Ele já foi segunda e quarta (cota da semana
    // cumprida) — sexta não pode virar falta, porque o plano dele não
    // cobre esse 3º dia.
    final agoraDomingo = DateTime(2026, 3, 15, 10, 0);
    final r = calcularFrequencia(
      presencas: [
        {'turma_id': 't1', 'data': '2026-03-09'}, // segunda
        {'turma_id': 't1', 'data': '2026-03-11'}, // quarta
      ],
      matriculas: [
        {'turma_id': 't1', 'criado_em': '2026-03-09T00:00:00'},
      ],
      horarios: horariosSegQuaSex(),
      limitesPorTurma: const {'t1': 2},
      agora: agoraDomingo,
    );
    expect(r.totalFaltas, 0, reason: 'sexta está além da cota semanal do plano, não é falta');
    expect(r.totalPresencas, 2);
    expect(r.totalTreinos, 2);
  });

  test('plano de 2 dias/semana: falta ainda conta dentro da cota semanal', () {
    // Mesmo plano de 2x/semana, mas o aluno só foi na segunda — a quarta
    // (2ª aula da semana, dentro da cota) sem presença AINDA vira falta.
    // Só a sexta (3ª, fora da cota) fica de fora.
    final agoraDomingo = DateTime(2026, 3, 15, 10, 0);
    final r = calcularFrequencia(
      presencas: [
        {'turma_id': 't1', 'data': '2026-03-09'}, // segunda
      ],
      matriculas: [
        {'turma_id': 't1', 'criado_em': '2026-03-09T00:00:00'},
      ],
      horarios: horariosSegQuaSex(),
      limitesPorTurma: const {'t1': 2},
      agora: agoraDomingo,
    );
    expect(r.totalFaltas, 1, reason: 'quarta está dentro da cota semanal e ficou sem presença');
  });

  test('total de treinos soma sessões + presenças órfãs (fora do horário atual)', () {
    // Bug relatado: "Total" mostrava só max(sessões, presenças) — se o
    // aluno tem presença numa turma/dia fora da matrícula ou do horário
    // atual (ex.: turma antiga, aula avulsa), o total ficava menor que
    // presenças + faltas somadas.
    final r = calcularFrequencia(
      presencas: [
        {'turma_id': 't1', 'data': '2026-02-26'}, // cobre a sessão de t1
        {'turma_id': 't-antiga', 'data': '2026-01-01'}, // órfã: t-antiga não tem horário/matrícula
      ],
      matriculas: [
        {'turma_id': 't1', 'criado_em': '2026-02-01T10:00:00'},
      ],
      horarios: horariosQuinta(),
      agora: agora,
    );
    // Sessões: mesmas 6 quintas do teste "presença cobre a falta" (05,12,19,
    // 26/02 e 05,12/03) = 6. Presença órfã de t-antiga soma +1 ao total.
    expect(r.totalPresencas, 2);
    expect(r.totalTreinos, 7); // 6 sessões + 1 presença órfã
  });

  test('falta automática desativada: nunca gera falta, só mostra presença real', () {
    // Configuração nova: academia pode desligar a inferência automática de
    // falta. Nesse modo, dias sem presença não aparecem em lugar nenhum —
    // nem como falta, nem como pendência.
    final r = calcularFrequencia(
      presencas: [
        {'turma_id': 't1', 'data': '2026-02-26'},
      ],
      matriculas: [
        {'turma_id': 't1', 'criado_em': '2026-02-01T10:00:00'},
      ],
      horarios: horariosQuinta(),
      contabilizarFaltaAutomatica: false,
      agora: agora,
    );
    expect(r.totalFaltas, 0);
    expect(r.totalPresencas, 1);
    expect(r.totalTreinos, 1);
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
