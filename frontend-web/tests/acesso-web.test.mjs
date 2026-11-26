// Regra de acesso ao web, conferida contra os mesmos cenários usados na
// simulação. Rodar em frontend-web: npm run test:acesso
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import test from 'node:test';

import { avaliarAcessoWeb, paraData } from '../src/app/core/models/acesso-web.ts';

const require = createRequire(import.meta.url);
const { CENARIOS, montarCenario } = require('../../functions/scripts/cenarios-assinatura.js');

const agora = new Date('2026-11-26T12:00:00.000Z');
const LIGADO = { web_bloqueio_ativo: true };
const emDias = (n) => new Date(agora.getTime() + n * 86_400_000);

// cenário -> [situação, entra com a trava ligada]
const ESPERADO = {
  gratis: ['gratis', false],
  teste: ['teste', true],
  'teste-acabando': ['teste', true],
  pro: ['pro', false],
  black: ['black-belt', true],
  'pro-cancelado': ['pro', false],
  'black-cancelado': ['black-belt', true],
  'pro-carencia': ['pro', false],
  'black-carencia': ['black-belt', true],
  expirado: ['gratis', false],
  reembolsado: ['gratis', false],
  suspenso: ['suspenso', false],
  'cortesia-web': ['cortesia', true],
  cortesia: ['pro', false],
};

test('todo cenário da simulação tem resultado esperado', () => {
  assert.deepEqual(Object.keys(CENARIOS).sort(), Object.keys(ESPERADO).sort());
});

for (const [cenario, [situacao, entra]] of Object.entries(ESPERADO)) {
  test(`${cenario}: ${situacao}, ${entra ? 'entra' : 'bloqueado'}`, () => {
    const { campos } = montarCenario(cenario, { agora });
    const ligado = avaliarAcessoWeb(campos, LIGADO, agora);
    assert.equal(ligado.situacao, situacao);
    assert.equal(ligado.liberado, entra);

    const desligado = avaliarAcessoWeb(campos, {}, agora);
    assert.equal(desligado.situacao, situacao);
    assert.equal(desligado.liberado, true, 'sem a trava todos entram');
  });
}

test('trava só liga com o valor booleano true', () => {
  const { campos } = montarCenario('gratis', { agora });
  for (const valor of [undefined, false, 'true', 1]) {
    assert.equal(avaliarAcessoWeb(campos, { web_bloqueio_ativo: valor }, agora).liberado, true);
  }
});

test('acesso_web sem plano pago ou vencido não libera', () => {
  const base = { acesso_web: true, criado_em: emDias(-90) };
  assert.equal(avaliarAcessoWeb({ ...base, plano_tipo: 0 }, LIGADO, agora).liberado, false);
  const vencido = { ...base, plano_tipo: 1, plano_expiracao: emDias(-2).toISOString() };
  assert.equal(avaliarAcessoWeb(vencido, LIGADO, agora).liberado, false);
});

test('cortesia vencida não libera', () => {
  const academia = { plano_tipo: 0, criado_em: emDias(-90), web_cortesia_ate: emDias(-1) };
  assert.equal(avaliarAcessoWeb(academia, LIGADO, agora).liberado, false);
});

test('suspensa é identificada para a tela explicar', () => {
  const academia = { plano_tipo: 0, plano_status: 'suspenso', criado_em: emDias(-90) };
  assert.equal(avaliarAcessoWeb(academia, LIGADO, agora).situacao, 'suspenso');
});

test('quem compra o PRO durante o teste mantém o web até o teste acabar', () => {
  const academia = { plano_tipo: 1, criado_em: emDias(-5) };
  assert.equal(avaliarAcessoWeb(academia, LIGADO, agora).situacao, 'teste');
  assert.equal(avaliarAcessoWeb({ ...academia, criado_em: emDias(-31) }, LIGADO, agora).situacao, 'pro');
});

test('prazo do teste: padrão de 30 dias, ajustável por config.trial_dias', () => {
  const em = (idade, extra = {}) =>
    avaliarAcessoWeb({ criado_em: emDias(-idade) }, { ...LIGADO, ...extra }, agora);
  assert.equal(em(0).diasDeTesteRestantes, 30);
  assert.equal(em(29).liberado, true);
  assert.equal(em(30).liberado, false);
  assert.equal(em(40, { trial_dias: 60 }).diasDeTesteRestantes, 20);
  assert.equal(em(31, { trial_dias: 0 }).liberado, false);
});

test('datas: Timestamp, Date, texto e valores inválidos', () => {
  assert.equal(paraData({ toDate: () => agora }), agora);
  assert.equal(paraData(agora), agora);
  assert.equal(paraData(agora.toISOString()).getTime(), agora.getTime());
  for (const invalido of [null, undefined, '', 'abc', 42, {}]) {
    assert.equal(paraData(invalido), null);
  }
  assert.equal(avaliarAcessoWeb({}, LIGADO, agora).liberado, false);
});
