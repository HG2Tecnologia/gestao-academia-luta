"use strict";

// Gatilhos `testar*` disparam rotinas reais (e-mail, push, revogação de plano):
// nenhum pode ficar aberto na internet.

const assert = require("node:assert/strict");
const test = require("node:test");

process.env.GCLOUD_PROJECT ||= "sensei-manager-test";
const funcoes = require("../index");

const gatilhos = Object.keys(funcoes).filter((nome) => nome.startsWith("testar"));

test("os três gatilhos manuais continuam exportados", () => {
  assert.deepEqual(gatilhos.sort(), [
    "testarAlertasEngajamento",
    "testarReconciliacaoAssinaturas",
    "testarVencimentosContasAcademia",
  ]);
});

for (const nome of gatilhos) {
  test(`${nome} não é público`, () => {
    assert.deepEqual(funcoes[nome].__endpoint.httpsTrigger.invoker, ["private"]);
  });
}
