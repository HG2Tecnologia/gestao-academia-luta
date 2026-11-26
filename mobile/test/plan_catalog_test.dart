import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/plan_catalog.dart';

DecisaoCompra _decidir(
  String produtoId, {
  String loja = 'android',
  SituacaoPlano situacao = const SituacaoPlano(pago: false),
  List<AssinaturaNoAparelho>? noAparelho = const [],
}) => decidirCompra(
  produtoId: produtoId,
  loja: loja,
  situacao: situacao,
  noAparelho: noAparelho,
);

SituacaoPlano _assinante(
  String produtoId, {
  String plataforma = 'android',
  String? compraId = 'compra-academia',
  bool renova = true,
  String origem = 'loja',
}) => SituacaoPlano(
  pago: true,
  origem: origem,
  plataforma: plataforma,
  produtoId: produtoId,
  compraId: compraId,
  renovacaoAutomatica: renova,
);

AssinaturaNoAparelho _noAparelho(
  String produtoId, {
  String compraId = 'compra-academia',
  bool renova = true,
}) => AssinaturaNoAparelho(
  compraId: compraId,
  produtoId: produtoId,
  renova: renova,
);

Matcher _bloqueada(MotivoBloqueio motivo) =>
    isA<CompraBloqueada>().having((d) => d.motivo, 'motivo', motivo);

Matcher _troca(ModoTroca modo) => isA<TrocaDePlano>()
    .having((d) => d.modo, 'modo', modo)
    .having((d) => d.compraAtualId, 'compraAtualId', 'compra-academia');

void main() {
  group('catálogo', () {
    test('um produto para cada nível e período, com IDs únicos', () {
      expect(kCatalogo.length, 6);
      expect(kCatalogo.map((p) => p.id).toSet().length, 6);
      for (final nivel in NivelPlano.values) {
        for (final periodo in Periodo.values) {
          expect(produtoDe(nivel, periodo).nivel, nivel);
        }
      }
    });

    test('IDs cabem no limite de 40 caracteres do Google', () {
      for (final p in kCatalogo) {
        expect(p.id.length, lessThanOrEqualTo(40), reason: p.id);
      }
    });

    test('preços de reserva decididos para o Black Belt', () {
      expect(
        [
          for (final p in kCatalogo)
            if (p.nivel == NivelPlano.blackBelt) p.precoReserva,
        ],
        [99.99, 229.90, 749.90],
      );
    });

    test('desconto em relação ao mensal', () {
      int desconto(double preco, double mensal, int meses) =>
          descontoPercentual(
            precoPeriodo: preco,
            precoMensal: mensal,
            meses: meses,
          );
      expect(desconto(149.90, 69.99, 3), 29);
      expect(desconto(499.90, 69.99, 12), 40);
      expect(desconto(229.90, 99.99, 3), 23);
      expect(desconto(749.90, 99.99, 12), 38);
      expect(desconto(99.99, 99.99, 1), 0);
    });
  });

  group('compra nova', () {
    test('academia no grátis, sem nada no aparelho', () {
      expect(_decidir(kIapBlackMensal), isA<CompraNova>());
    });

    test('cortesia não impede a compra', () {
      expect(
        _decidir(
          kIapBlackMensal,
          situacao: _assinante(kIapMensal, origem: 'cortesia', compraId: null),
        ),
        isA<CompraNova>(),
      );
    });

    test('loja não consultada vale pelos dados da academia', () {
      expect(_decidir(kIapMensal, noAparelho: null), isA<CompraNova>());
    });
  });

  group('troca de plano', () {
    for (final (atual, novo, modo) in [
      (kIapMensal, kIapBlackMensal, ModoTroca.imediata),
      (kIapAnual, kIapBlackMensal, ModoTroca.imediata),
      (kIapBlackMensal, kIapMensal, ModoTroca.noProximoCiclo),
      (kIapMensal, kIapAnual, ModoTroca.noProximoCiclo),
      (kIapBlackAnual, kIapBlackMensal, ModoTroca.noProximoCiclo),
    ]) {
      test('$atual -> $novo: ${modo.name}', () {
        expect(
          _decidir(
            novo,
            situacao: _assinante(atual),
            noAparelho: [_noAparelho(atual)],
          ),
          _troca(modo),
        );
      });
    }

    test('ativação antiga sem identificador usa a única do aparelho', () {
      expect(
        _decidir(
          kIapBlackMensal,
          situacao: _assinante(kIapMensal, compraId: null),
          noAparelho: [_noAparelho(kIapMensal)],
        ),
        _troca(ModoTroca.imediata),
      );
    });

    test('assinatura cancelada no aparelho ainda é substituída', () {
      expect(
        _decidir(
          kIapBlackMensal,
          situacao: _assinante(kIapMensal, renova: false),
          noAparelho: [_noAparelho(kIapMensal, renova: false)],
        ),
        _troca(ModoTroca.imediata),
      );
    });
  });

  group('bloqueios contra cobrança dupla', () {
    test('mesmo produto que já renova', () {
      expect(
        _decidir(kIapMensal, situacao: _assinante(kIapMensal)),
        _bloqueada(MotivoBloqueio.planoAtual),
      );
    });

    test('academia paga pela outra loja', () {
      for (final (loja, outra) in [('android', 'ios'), ('ios', 'android')]) {
        expect(
          _decidir(
            kIapBlackMensal,
            loja: loja,
            situacao: _assinante(kIapMensal, plataforma: outra),
          ),
          _bloqueada(MotivoBloqueio.assinaturaEmOutraLoja),
        );
      }
    });

    test('outra loja já cancelada libera a compra', () {
      expect(
        _decidir(
          kIapBlackMensal,
          situacao: _assinante(kIapMensal, plataforma: 'ios', renova: false),
        ),
        isA<CompraNova>(),
      );
    });

    test('assinatura da academia está em outra conta da loja', () {
      expect(
        _decidir(kIapBlackMensal, situacao: _assinante(kIapMensal)),
        _bloqueada(MotivoBloqueio.assinaturaEmOutraConta),
      );
    });

    test('conta da loja já paga uma assinatura de outra academia', () {
      expect(
        _decidir(
          kIapBlackMensal,
          noAparelho: [_noAparelho(kIapMensal, compraId: 'de-outra')],
        ),
        _bloqueada(MotivoBloqueio.contaDaLojaJaAssina),
      );
    });
  });
}
