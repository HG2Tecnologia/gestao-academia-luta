import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/grau_colorido.dart';

void main() {
  group('calcularGrauCoresOficialIbjjf', () {
    test('12 graus: 4 brancos, 4 vermelhos, 4 da cor da próxima faixa', () {
      final cores = calcularGrauCoresOficialIbjjf(
        maxGraus: 12,
        corProximaFaixaHex: '#808080', // cinza, ex. branca -> cinza
      );
      expect(cores.length, 12);
      expect(cores.sublist(0, 4), List.filled(4, '#FFFFFF'));
      expect(cores.sublist(4, 8), List.filled(4, '#FF0000'));
      expect(cores.sublist(8, 12), List.filled(4, '#808080'));
    });

    test('11 graus (sistema mensal oficial): 4 brancos, 4 vermelhos, 3 da próxima cor', () {
      final cores = calcularGrauCoresOficialIbjjf(
        maxGraus: 11,
        corProximaFaixaHex: '#FFFF00',
      );
      expect(cores.length, 11);
      expect(cores.sublist(0, 4), List.filled(4, '#FFFFFF'));
      expect(cores.sublist(4, 8), List.filled(4, '#FF0000'));
      expect(cores.sublist(8, 11), List.filled(3, '#FFFF00'));
    });

    test('sem próxima faixa (última da sequência), usa preto como fallback neutro', () {
      final cores = calcularGrauCoresOficialIbjjf(maxGraus: 12, corProximaFaixaHex: null);
      expect(cores.sublist(8, 12), List.filled(4, '#000000'));
    });

    test('maxGraus menor que 8 nunca usa a cor da próxima faixa', () {
      final cores = calcularGrauCoresOficialIbjjf(maxGraus: 4, corProximaFaixaHex: '#808080');
      expect(cores, List.filled(4, '#FFFFFF'));
    });

    test('maxGraus 0 ou negativo devolve lista vazia, nunca lança exceção', () {
      expect(calcularGrauCoresOficialIbjjf(maxGraus: 0), isEmpty);
      expect(calcularGrauCoresOficialIbjjf(maxGraus: -1), isEmpty);
    });
  });

  group('calcularGrauCoresEmBlocos', () {
    test('descrição do cliente: 12 graus com 3 cores vira 4 de cada, em blocos', () {
      final cores = calcularGrauCoresEmBlocos(
        maxGraus: 12,
        cores: ['#FFFFFF', '#FF0000', '#FFFF00'],
      );
      expect(cores.length, 12);
      expect(cores.sublist(0, 4), List.filled(4, '#FFFFFF'));
      expect(cores.sublist(4, 8), List.filled(4, '#FF0000'));
      expect(cores.sublist(8, 12), List.filled(4, '#FFFF00'));
    });

    test('maxGraus não divisível igualmente: último bloco absorve o resto', () {
      final cores = calcularGrauCoresEmBlocos(
        maxGraus: 10,
        cores: ['#FFFFFF', '#FF0000', '#FFFF00'],
      );
      expect(cores.length, 10);
      // blockSize = ceil(10/3) = 4 -> índices 0-3 branco, 4-7 vermelho, 8-9 amarelo
      expect(cores.sublist(0, 4), List.filled(4, '#FFFFFF'));
      expect(cores.sublist(4, 8), List.filled(4, '#FF0000'));
      expect(cores.sublist(8, 10), List.filled(2, '#FFFF00'));
    });

    test('uma cor só preenche tudo', () {
      final cores = calcularGrauCoresEmBlocos(maxGraus: 4, cores: ['#000000']);
      expect(cores, List.filled(4, '#000000'));
    });

    test('lista de cores vazia ou maxGraus <= 0 devolve vazio, nunca lança exceção', () {
      expect(calcularGrauCoresEmBlocos(maxGraus: 4, cores: const []), isEmpty);
      expect(calcularGrauCoresEmBlocos(maxGraus: 0, cores: ['#FFFFFF']), isEmpty);
    });
  });

  group('indicesDeCoresIgnoradasEmBlocos', () {
    test('bug real reportado: 3 cores com só 4 graus faz a 3ª cor nunca aparecer', () {
      final ignoradas = indicesDeCoresIgnoradasEmBlocos(
        maxGraus: 4,
        cores: ['#FFFFFF', '#FF0000', '#FFFF00'],
      );
      expect(ignoradas, [2]); // índice 2 = amarelo, nunca alcançado
    });

    test('12 graus com 3 cores: todas aparecem, nenhuma ignorada', () {
      final ignoradas = indicesDeCoresIgnoradasEmBlocos(
        maxGraus: 12,
        cores: ['#FFFFFF', '#FF0000', '#FFFF00'],
      );
      expect(ignoradas, isEmpty);
    });

    test('maxGraus 0 ou cores vazias: nunca lança exceção, devolve vazio', () {
      expect(
        indicesDeCoresIgnoradasEmBlocos(maxGraus: 0, cores: ['#FFFFFF']),
        isEmpty,
      );
      expect(
        indicesDeCoresIgnoradasEmBlocos(maxGraus: 4, cores: const []),
        isEmpty,
      );
    });
  });

  group('montarElegibilidadeGrausColoridosPorAluno', () {
    test(
      'mesma modalidade, turma Kids com o recurso ligado e turma Adulto sem — só o aluno da Kids é elegível',
      () {
        final turmasPorId = {
          'turma-kids': {'modalidadeId': 'jiu-jitsu', 'usa_graus_coloridos': true},
          'turma-adulto': {'modalidadeId': 'jiu-jitsu', 'usa_graus_coloridos': false},
        };
        final matriculas = [
          {'aluno_id': 'crianca-1', 'turma_id': 'turma-kids', 'ativo': true},
          {'aluno_id': 'adulto-1', 'turma_id': 'turma-adulto', 'ativo': true},
        ];
        final elegiveis = montarElegibilidadeGrausColoridosPorAluno(
          matriculas: matriculas,
          turmasPorId: turmasPorId,
          grausColoridosDisponivelNaAcademia: true,
        );
        expect(elegiveis['crianca-1'], {'jiu-jitsu'});
        expect(elegiveis.containsKey('adulto-1'), isFalse);
      },
    );

    test(
      'switch "pai" da academia desligado zera a elegibilidade de todo mundo, mesmo com a turma ainda marcada',
      () {
        final turmasPorId = {
          'turma-kids': {
            'modalidadeId': 'jiu-jitsu',
            'usa_graus_coloridos': true,
          },
        };
        final matriculas = [
          {'aluno_id': 'crianca-1', 'turma_id': 'turma-kids', 'ativo': true},
        ];
        final elegiveis = montarElegibilidadeGrausColoridosPorAluno(
          matriculas: matriculas,
          turmasPorId: turmasPorId,
          grausColoridosDisponivelNaAcademia: false,
        );
        expect(elegiveis, isEmpty);
      },
    );

    test('matrícula inativa não conta, mesmo numa turma com o recurso ligado', () {
      final turmasPorId = {
        'turma-kids': {'modalidadeId': 'jiu-jitsu', 'usa_graus_coloridos': true},
      };
      final matriculas = [
        {'aluno_id': 'ex-aluno', 'turma_id': 'turma-kids', 'ativo': false},
      ];
      final elegiveis = montarElegibilidadeGrausColoridosPorAluno(
        matriculas: matriculas,
        turmasPorId: turmasPorId,
        grausColoridosDisponivelNaAcademia: true,
      );
      expect(elegiveis, isEmpty);
    });

    test('aluno em DUAS turmas da mesma modalidade, uma com e outra sem: ainda elegível', () {
      final turmasPorId = {
        'turma-a': {'modalidadeId': 'jiu-jitsu', 'usa_graus_coloridos': false},
        'turma-b': {'modalidadeId': 'jiu-jitsu', 'usa_graus_coloridos': true},
      };
      final matriculas = [
        {'aluno_id': 'aluno-1', 'turma_id': 'turma-a', 'ativo': true},
        {'aluno_id': 'aluno-1', 'turma_id': 'turma-b', 'ativo': true},
      ];
      final elegiveis = montarElegibilidadeGrausColoridosPorAluno(
        matriculas: matriculas,
        turmasPorId: turmasPorId,
        grausColoridosDisponivelNaAcademia: true,
      );
      expect(elegiveis['aluno-1'], {'jiu-jitsu'});
    });

    test('turma sem o campo usa_graus_coloridos (todo o cadastro hoje) nunca torna ninguém elegível — não-regressão', () {
      final turmasPorId = {
        'turma-x': {'modalidadeId': 'jiu-jitsu'}, // sem o campo, como é hoje
      };
      final matriculas = [
        {'aluno_id': 'aluno-1', 'turma_id': 'turma-x', 'ativo': true},
      ];
      final elegiveis = montarElegibilidadeGrausColoridosPorAluno(
        matriculas: matriculas,
        turmasPorId: turmasPorId,
        grausColoridosDisponivelNaAcademia: true,
      );
      expect(elegiveis, isEmpty);
    });

    test('matrícula sem turma correspondente (órfã) não lança exceção', () {
      final elegiveis = montarElegibilidadeGrausColoridosPorAluno(
        matriculas: [
          {'aluno_id': 'aluno-1', 'turma_id': 'turma-inexistente', 'ativo': true},
        ],
        turmasPorId: const {},
        grausColoridosDisponivelNaAcademia: true,
      );
      expect(elegiveis, isEmpty);
    });

    test('lista de matrículas vazia devolve mapa vazio', () {
      expect(
        montarElegibilidadeGrausColoridosPorAluno(
          matriculas: const [],
          turmasPorId: const {},
          grausColoridosDisponivelNaAcademia: true,
        ),
        isEmpty,
      );
    });
  });

  group('maxGrausEfetivo', () {
    test(
      'faixa configurada pro sistema colorido (12) mas aluno não elegível cai pro padrão de 4',
      () {
        expect(
          maxGrausEfetivo(
            maxGrausConfigurado: 12,
            temGrauCoresConfigurado: true,
            elegivelGrauColorido: false,
          ),
          4,
        );
      },
    );

    test('aluno elegível mantém o valor configurado (12)', () {
      expect(
        maxGrausEfetivo(
          maxGrausConfigurado: 12,
          temGrauCoresConfigurado: true,
          elegivelGrauColorido: true,
        ),
        12,
      );
    });

    test(
      'faixa que nunca configurou grau_cores (ex.: graus de faixa preta) não é afetada pela elegibilidade',
      () {
        expect(
          maxGrausEfetivo(
            maxGrausConfigurado: 6,
            temGrauCoresConfigurado: false,
            elegivelGrauColorido: false,
          ),
          6,
        );
      },
    );
  });

  group('ajustarGrauCoresPersonalizado', () {
    test('tamanho já bate: devolve a lista como está', () {
      final cores = ajustarGrauCoresPersonalizado(
        maxGraus: 3,
        coresAtuais: ['#FFFFFF', '#FF0000', '#000000'],
      );
      expect(cores, ['#FFFFFF', '#FF0000', '#000000']);
    });

    test('maxGraus subiu: completa repetindo a última cor, nunca lança exceção de índice', () {
      final cores = ajustarGrauCoresPersonalizado(
        maxGraus: 5,
        coresAtuais: ['#FFFFFF', '#FF0000'],
      );
      expect(cores, ['#FFFFFF', '#FF0000', '#FF0000', '#FF0000', '#FF0000']);
    });

    test('maxGraus desceu: trunca', () {
      final cores = ajustarGrauCoresPersonalizado(
        maxGraus: 2,
        coresAtuais: ['#FFFFFF', '#FF0000', '#000000', '#808080'],
      );
      expect(cores, ['#FFFFFF', '#FF0000']);
    });

    test('lista vazia e maxGraus > 0: completa com a cor padrão, não quebra', () {
      final cores = ajustarGrauCoresPersonalizado(maxGraus: 3, coresAtuais: const []);
      expect(cores, ['#FFFFFF', '#FFFFFF', '#FFFFFF']);
    });
  });
}
