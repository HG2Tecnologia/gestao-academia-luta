import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/relatorio_presencas.dart';

void main() {
  test('resolve os nomes pelo cadastro e inclui matriculados sem presença', () {
    final relatorio = montarRelatorioPresencas(
      presencas: [
        {'aluno_id': 'aluno-1', 'data': '2026-08-27'},
        {'aluno_id': 'aluno-1', 'data': '2026-08-28'},
      ],
      matriculas: [
        {'aluno_id': 'aluno-1', 'ativo': true},
        {'aluno_id': 'aluno-2', 'ativo': true},
      ],
      alunos: [
        {'id': 'aluno-1', 'nome': 'Alice Forny', 'ativo': true},
        {'id': 'aluno-2', 'nome': 'Bruno Silva', 'ativo': true},
      ],
    );

    final alunos = (relatorio['alunos'] as List).cast<Map<String, dynamic>>();
    expect(alunos.map((a) => a['nomeAluno']), ['Alice Forny', 'Bruno Silva']);
    expect(alunos[0]['percentual'], 100);
    expect(alunos[1]['percentual'], 0);
    expect(alunos[1]['faltas'], 2);
    expect(relatorio['mediaFrequencia'], 50);
  });

  test('não duplica presença do aluno no mesmo dia', () {
    final relatorio = montarRelatorioPresencas(
      presencas: [
        {'aluno_id': 'aluno-1', 'data': '2026-08-28'},
        {'aluno_id': 'aluno-1', 'data_presenca': '2026-08-28'},
      ],
      matriculas: const [],
      alunos: [
        {'id': 'aluno-1', 'nome': 'Alice Forny'},
      ],
    );

    final aluno = (relatorio['alunos'] as List).single as Map<String, dynamic>;
    expect(aluno['nomeAluno'], 'Alice Forny');
    expect(aluno['presencas'], 1);
    expect(aluno['percentual'], 100);
  });

  test('preserva presença histórica de matrícula encerrada', () {
    final relatorio = montarRelatorioPresencas(
      presencas: [
        {'aluno_id': 'aluno-1', 'data': '2026-08-28'},
      ],
      matriculas: [
        {'aluno_id': 'aluno-1', 'ativo': false},
      ],
      alunos: [
        {'id': 'aluno-1', 'nome': 'Alice Forny', 'ativo': false},
      ],
    );

    final aluno = (relatorio['alunos'] as List).single as Map<String, dynamic>;
    expect(aluno['nomeAluno'], 'Alice Forny');
    expect(aluno['presencas'], 1);
  });
}
