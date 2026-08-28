import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/graduacao_order.dart';

void main() {
  test('ordena graduações de datas diferentes da mais antiga para a nova', () {
    final graduacoes = <Map<String, dynamic>>[
      {'id': 'nova', 'dataExame': '2026-08-28'},
      {'id': 'antiga', 'dataExame': '2026-08-11'},
    ]..sort(compararGraduacoesCronologicamente);

    expect(graduacoes.map((g) => g['id']), ['antiga', 'nova']);
  });

  test('usa o instante exato de criação para graduações do mesmo dia', () {
    final graduacoes = <Map<String, dynamic>>[
      {
        'id': 'segunda',
        'dataExame': '2026-08-28',
        'criado_em': '2026-08-28T12:00:02.000Z',
      },
      {
        'id': 'primeira',
        'dataExame': '2026-08-28',
        'criado_em': '2026-08-28T12:00:01.000Z',
      },
    ]..sort(compararGraduacoesCronologicamente);

    expect(graduacoes.map((g) => g['id']), ['primeira', 'segunda']);
  });

  test('registros legados usam ordem da faixa e grau, não o nome', () {
    final graduacoes = <Map<String, dynamic>>[
      {
        'id': 'faixa-seguinte',
        'modalidadeId': 'jiu-jitsu',
        'dataExame': '2026-08-28',
        'nomeFaixa': 'Faixa personalizada B',
        'faixaOrdem': 2,
        'grau': 0,
      },
      {
        'id': 'terceiro-grau',
        'modalidadeId': 'jiu-jitsu',
        'dataExame': '2026-08-28',
        'nomeFaixa': 'Faixa personalizada A',
        'faixaOrdem': 1,
        'grau': 3,
      },
      {
        'id': 'sem-grau',
        'modalidadeId': 'jiu-jitsu',
        'dataExame': '2026-08-28',
        'nomeFaixa': 'Faixa personalizada A',
        'faixaOrdem': 1,
        'grau': 0,
      },
    ]..sort(compararGraduacoesCronologicamente);

    expect(
      graduacoes.map((g) => g['id']),
      ['sem-grau', 'terceiro-grau', 'faixa-seguinte'],
    );
  });

  test('mantém registros legados e timestampados em blocos determinísticos', () {
    final graduacoes = <Map<String, dynamic>>[
      {
        'id': 'nova',
        'modalidadeId': 'jiu-jitsu',
        'dataExame': '2026-08-28',
        'criado_em': '2026-08-28T12:00:01.000Z',
        'faixaOrdem': 1,
      },
      {
        'id': 'legada',
        'modalidadeId': 'jiu-jitsu',
        'dataExame': '2026-08-28',
        'faixaOrdem': 2,
      },
    ]..sort(compararGraduacoesCronologicamente);

    expect(graduacoes.map((g) => g['id']), ['legada', 'nova']);
  });

  test('graduação atual é a mais avançada mesmo com histórico crescente', () {
    final brancaRecente = <String, dynamic>{
      'faixaOrdem': 1,
      'grau': 4,
      'dataExame': '2026-08-28',
    };
    final azulAntiga = <String, dynamic>{
      'faixaOrdem': 2,
      'grau': 0,
      'dataExame': '2026-08-20',
    };

    expect(compararProgressaoGraduacoes(azulAntiga, brancaRecente), greaterThan(0));
  });

  test('faixas atuais são derivadas apenas do histórico aprovado existente', () {
    final atuais = montarFaixasAtuaisPorAluno([
      {
        'id': 'grad-1',
        'aluno_id': 'aluno-1',
        'aprovado': true,
        'modalidadeId': 'jiu-jitsu',
        'nomeModalidade': 'Jiu Jitsu',
        'nomeFaixa': 'Azul',
        'corFaixa': '#0000FF',
        'faixaOrdem': 2,
        'grau': 2,
      },
      {
        'id': 'reprovada',
        'aluno_id': 'aluno-1',
        'aprovado': false,
        'modalidadeId': 'judo',
        'nomeFaixa': 'Verde',
        'faixaOrdem': 3,
      },
    ]);

    expect(atuais['aluno-1']!.keys, ['jiu-jitsu']);
    expect(atuais['aluno-1']!['jiu-jitsu']!['faixaNome'], 'Azul');
    expect(montarFaixasAtuaisPorAluno(const []), isEmpty);
  });
}
