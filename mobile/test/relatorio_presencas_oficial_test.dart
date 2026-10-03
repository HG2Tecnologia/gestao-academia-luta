import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/relatorio_presencas_oficial.dart';

void main() {
  // Segunda(1) e quarta(3) — 0=Dom..6=Sáb.
  List<Map<String, dynamic>> horariosSegQua(String turmaId) => [
    {'turma_id': turmaId, 'dia_semana': 1, 'hora_inicio': '19:00'},
    {'turma_id': turmaId, 'dia_semana': 3, 'hora_inicio': '19:00'},
  ];

  final aluno = {'id': 'a1', 'nome': 'Alice', 'telefone': '11999990000', 'ativo': true};
  final turma = {'id': 't1', 'nome': 'Jiu-Jitsu Infantil', 'modalidadeId': 'm1'};

  test('1 turma: conta presença/falta/total dentro do período informado', () {
    // Março/2026: segundas 02,09,16,23,30; quartas 04,11,18,25.
    final linhas = montarRelatorioPresencasOficial(
      alunos: [aluno],
      matriculas: [
        {'id': 'mat1', 'aluno_id': 'a1', 'turma_id': 't1', 'ativo': true, 'criado_em': '2026-01-01T00:00:00'},
      ],
      presencas: [
        {'aluno_id': 'a1', 'turma_id': 't1', 'data': '2026-03-02'},
        {'aluno_id': 'a1', 'turma_id': 't1', 'data': '2026-03-04'},
      ],
      horarios: horariosSegQua('t1'),
      turmas: [turma],
      graduacoesDetalhadas: const [],
      de: DateTime(2026, 3, 1),
      ate: DateTime(2026, 3, 31, 23, 59, 59),
    );

    expect(linhas, hasLength(1));
    final l = linhas.first;
    expect(l.nomeAluno, 'Alice');
    expect(l.telefone, '11999990000');
    expect(l.nomeTurma, 'Jiu-Jitsu Infantil');
    expect(l.presencas, 2);
    // 9 sessões esperadas no mês (5 segundas + 4 quartas), 2 com presença.
    expect(l.totalAulas, 9);
    expect(l.faltas, 7);
  });

  test('aluno em 2 turmas gera 2 linhas, sem misturar presença de uma na outra', () {
    final turma2 = {'id': 't2', 'nome': 'Muay Thai', 'modalidadeId': 'm2'};
    final linhas = montarRelatorioPresencasOficial(
      alunos: [aluno],
      matriculas: [
        {'id': 'mat1', 'aluno_id': 'a1', 'turma_id': 't1', 'ativo': true, 'criado_em': '2026-01-01'},
        {'id': 'mat2', 'aluno_id': 'a1', 'turma_id': 't2', 'ativo': true, 'criado_em': '2026-01-01'},
      ],
      presencas: [
        {'aluno_id': 'a1', 'turma_id': 't1', 'data': '2026-03-02'},
      ],
      horarios: [...horariosSegQua('t1'), ...horariosSegQua('t2')],
      turmas: [turma, turma2],
      graduacoesDetalhadas: const [],
      de: DateTime(2026, 3, 1),
      ate: DateTime(2026, 3, 31, 23, 59, 59),
    );

    expect(linhas, hasLength(2));
    final t1 = linhas.firstWhere((l) => l.turmaId == 't1');
    final t2 = linhas.firstWhere((l) => l.turmaId == 't2');
    expect(t1.presencas, 1);
    expect(t2.presencas, 0); // a presença da t1 não vaza pra t2
    expect(t2.faltas, 9);
  });

  test('filtro por turma: só retorna linhas daquela turma', () {
    final turma2 = {'id': 't2', 'nome': 'Muay Thai', 'modalidadeId': 'm2'};
    final linhas = montarRelatorioPresencasOficial(
      alunos: [aluno],
      matriculas: [
        {'id': 'mat1', 'aluno_id': 'a1', 'turma_id': 't1', 'ativo': true, 'criado_em': '2026-01-01'},
        {'id': 'mat2', 'aluno_id': 'a1', 'turma_id': 't2', 'ativo': true, 'criado_em': '2026-01-01'},
      ],
      presencas: const [],
      horarios: [...horariosSegQua('t1'), ...horariosSegQua('t2')],
      turmas: [turma, turma2],
      graduacoesDetalhadas: const [],
      de: DateTime(2026, 3, 1),
      ate: DateTime(2026, 3, 31, 23, 59, 59),
      turmaId: 't1',
    );

    expect(linhas, hasLength(1));
    expect(linhas.first.turmaId, 't1');
  });

  test('aluno matriculado no meio do período: sem falta antes da matrícula', () {
    final linhas = montarRelatorioPresencasOficial(
      alunos: [aluno],
      matriculas: [
        // Matriculou só dia 16/03 — segundas/quartas antes disso não contam.
        {'id': 'mat1', 'aluno_id': 'a1', 'turma_id': 't1', 'ativo': true, 'criado_em': '2026-03-16T00:00:00'},
      ],
      presencas: const [],
      horarios: horariosSegQua('t1'),
      turmas: [turma],
      graduacoesDetalhadas: const [],
      de: DateTime(2026, 3, 1),
      ate: DateTime(2026, 3, 31, 23, 59, 59),
    );

    expect(linhas, hasLength(1));
    // A partir de 16/03: segundas 16,23,30 + quartas 18,25 = 5.
    expect(linhas.first.totalAulas, 5);
    expect(linhas.first.faltas, 5);
  });

  test('relatório anual: soma o ano inteiro', () {
    final linhas = montarRelatorioPresencasOficial(
      alunos: [aluno],
      matriculas: [
        {'id': 'mat1', 'aluno_id': 'a1', 'turma_id': 't1', 'ativo': true, 'criado_em': '2026-01-01T00:00:00'},
      ],
      presencas: const [],
      horarios: horariosSegQua('t1'),
      turmas: [turma],
      graduacoesDetalhadas: const [],
      de: DateTime(2026, 1, 1),
      ate: DateTime(2026, 12, 31, 23, 59, 59),
    );

    expect(linhas, hasLength(1));
    expect(linhas.first.totalAulas, greaterThan(90));
  });

  test('período personalizado cruzando virada de ano: mescla os 2 anos', () {
    final linhas = montarRelatorioPresencasOficial(
      alunos: [aluno],
      matriculas: [
        {'id': 'mat1', 'aluno_id': 'a1', 'turma_id': 't1', 'ativo': true, 'criado_em': '2025-01-01T00:00:00'},
      ],
      presencas: [
        {'aluno_id': 'a1', 'turma_id': 't1', 'data': '2025-12-29'}, // segunda
        {'aluno_id': 'a1', 'turma_id': 't1', 'data': '2026-01-05'}, // segunda
      ],
      horarios: horariosSegQua('t1'),
      turmas: [turma],
      graduacoesDetalhadas: const [],
      de: DateTime(2025, 12, 15),
      ate: DateTime(2026, 1, 15),
    );

    expect(linhas, hasLength(1));
    expect(linhas.first.presencas, 2);
  });

  test('falta_automatica_ativa = false: zero faltas, só presença real', () {
    final linhas = montarRelatorioPresencasOficial(
      alunos: [aluno],
      matriculas: [
        {'id': 'mat1', 'aluno_id': 'a1', 'turma_id': 't1', 'ativo': true, 'criado_em': '2026-01-01'},
      ],
      presencas: [
        {'aluno_id': 'a1', 'turma_id': 't1', 'data': '2026-03-02'},
      ],
      horarios: horariosSegQua('t1'),
      turmas: [turma],
      graduacoesDetalhadas: const [],
      de: DateTime(2026, 3, 1),
      ate: DateTime(2026, 3, 31, 23, 59, 59),
      contabilizarFaltaAutomatica: false,
    );

    expect(linhas.first.presencas, 1);
    expect(linhas.first.faltas, 0);
    expect(linhas.first.totalAulas, 1);
  });

  test('resolve a faixa aprovada mais alta da modalidade da turma', () {
    final linhas = montarRelatorioPresencasOficial(
      alunos: [aluno],
      matriculas: [
        {'id': 'mat1', 'aluno_id': 'a1', 'turma_id': 't1', 'ativo': true, 'criado_em': '2026-01-01'},
      ],
      presencas: const [],
      horarios: horariosSegQua('t1'),
      turmas: [turma],
      graduacoesDetalhadas: [
        {
          'aluno_id': 'a1',
          'modalidadeId': 'm1',
          'aprovado': true,
          'nomeFaixa': 'Azul',
          'faixaOrdem': 2,
          'grau': 1,
        },
        {
          'aluno_id': 'a1',
          'modalidadeId': 'm1',
          'aprovado': true,
          'nomeFaixa': 'Branca',
          'faixaOrdem': 1,
          'grau': 4,
        },
        {
          // Outra modalidade — não deve interferir.
          'aluno_id': 'a1',
          'modalidadeId': 'm2',
          'aprovado': true,
          'nomeFaixa': 'Preta',
          'faixaOrdem': 9,
          'grau': 1,
        },
      ],
      de: DateTime(2026, 3, 1),
      ate: DateTime(2026, 3, 31, 23, 59, 59),
    );

    expect(linhas.first.faixaNome, 'Azul');
  });

  test('limite semanal do plano: dias além da cota não viram falta', () {
    final linhas = montarRelatorioPresencasOficial(
      alunos: [aluno],
      matriculas: [
        {'id': 'mat1', 'aluno_id': 'a1', 'turma_id': 't1', 'ativo': true, 'criado_em': '2026-03-09T00:00:00'},
      ],
      presencas: [
        {'aluno_id': 'a1', 'turma_id': 't1', 'data': '2026-03-09'},
      ],
      horarios: horariosSegQua('t1'),
      turmas: [turma],
      graduacoesDetalhadas: const [],
      de: DateTime(2026, 3, 9),
      ate: DateTime(2026, 3, 11, 23, 59, 59),
      limitesPorTurmaPorAluno: const {
        'a1': {'t1': 1},
      },
    );

    // Semana de 09-11/03: segunda 09 (presença) e quarta 11 — cota já usada
    // na segunda, então a quarta nem vira sessão (nem falta).
    expect(linhas.first.presencas, 1);
    expect(linhas.first.faltas, 0);
    expect(linhas.first.totalAulas, 1);
  });
}
