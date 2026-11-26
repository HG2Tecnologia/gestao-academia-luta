import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/plan_catalog.dart';
import 'package:tatame/core/plan_service.dart';

String _emDias(int dias) =>
    DateTime.now().add(Duration(days: dias)).toIso8601String();

Map<String, dynamic> _paga(String produto, {Map<String, dynamic>? extra}) => {
  'criado_em': _emDias(-90),
  'plano_tipo': 1,
  'plano_status': 'ativo',
  'plano_origem': 'loja',
  'plano_expiracao': _emDias(30),
  'plano_produto_id': produto,
  'plano_plataforma': 'android',
  'plano_original_transaction_id': 'token-1',
  'acesso_web': produto.contains('.black.'),
  ...?extra,
};

void main() {
  final plan = PlanService.instance;
  setUp(plan.reset);

  test('teste de 30 dias libera os recursos sem ser Pro', () {
    plan.aplicarDados({'criado_em': _emDias(-10), 'plano_tipo': 0});
    expect(plan.isPro, isFalse);
    expect(plan.temAcessoCompleto, isTrue);
    expect(plan.showAds, isFalse);
    expect(plan.nivel, isNull);
  });

  test('grátis depois do teste não tem acesso completo', () {
    plan.aplicarDados({'criado_em': _emDias(-31), 'plano_tipo': 0});
    expect(plan.temAcessoCompleto, isFalse);
    expect(plan.showAds, isTrue);
  });

  test('PRO não inclui o web', () {
    plan.aplicarDados(_paga(kIapAnual));
    expect(plan.nivel, NivelPlano.pro);
    expect(plan.acessoWeb, isFalse);
    expect(plan.planDisplayName, 'Sensei PRO');
    expect(planoProdutoDisplayName(plan.planoProdutoId), 'Anual');
  });

  test('Black Belt inclui o web', () {
    plan.aplicarDados(_paga(kIapBlackTrimestral));
    expect(plan.nivel, NivelPlano.blackBelt);
    expect(plan.acessoWeb, isTrue);
    expect(plan.planDisplayName, 'Sensei Black Belt');
    expect(planoProdutoDisplayName(plan.planoProdutoId), 'Trimestral');
  });

  test('cortesia sem produto conta como PRO', () {
    plan.aplicarDados({'plano_tipo': 1, 'plano_origem': 'cortesia'});
    expect(plan.nivel, NivelPlano.pro);
    expect(plan.temAcessoCompleto, isTrue);
  });

  test('suspensa perde o acesso', () {
    plan.aplicarDados(
      _paga(
        kIapBlackMensal,
        extra: {
          'plano_tipo': 0,
          'plano_status': 'suspenso',
          'acesso_web': false,
        },
      ),
    );
    expect(plan.isPro, isFalse);
    expect(plan.temAcessoCompleto, isFalse);
    expect(plan.acessoWeb, isFalse);
  });

  test('situação usada na decisão de compra', () {
    plan.aplicarDados(
      _paga(kIapMensal, extra: {'plano_renovacao_automatica': false}),
    );
    final s = plan.situacao;
    expect(s.pago, isTrue);
    expect(s.produtoId, kIapMensal);
    expect(s.plataforma, 'android');
    expect(s.compraId, 'token-1');
    expect(s.renovacaoAutomatica, isFalse);
  });
}
