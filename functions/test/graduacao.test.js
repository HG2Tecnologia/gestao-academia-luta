"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  compararCronologicamente,
  compararProgressao,
  detectarConflitoDeOrdem,
} = require("../domain/graduacao");

test("graduação: ordena do registro mais antigo para o mais novo por data de exame", () => {
  const antiga = { id: "a", data_exame: "2026-01-10", faixaOrdem: 1, grau: 0 };
  const nova = { id: "b", data_exame: "2026-06-10", faixaOrdem: 2, grau: 0 };
  assert.ok(compararCronologicamente(antiga, nova) < 0);
  assert.ok(compararCronologicamente(nova, antiga) > 0);
});

test("graduação: desempata pelo instante de criação quando a data de exame é igual", () => {
  const a = { id: "a", data_exame: "2026-01-10", criado_em: { toDate: () => new Date("2026-01-10T09:00:00Z") } };
  const b = { id: "b", data_exame: "2026-01-10", criado_em: { toDate: () => new Date("2026-01-10T09:05:00Z") } };
  assert.ok(compararCronologicamente(a, b) < 0);
});

test("graduação: progressão ignora o nome, só considera faixaOrdem e grau", () => {
  const azul2 = { faixaOrdem: 3, grau: 2, data_exame: "2026-01-01" };
  const roxa0 = { faixaOrdem: 4, grau: 0, data_exame: "2026-01-02" };
  assert.ok(compararProgressao(azul2, roxa0) < 0);
});

test("graduação: sem conflito quando a progressão cresce ao longo do tempo", () => {
  const historico = [
    { id: "1", aprovado: true, data_exame: "2026-01-01", faixaOrdem: 1, grau: 0 },
    { id: "2", aprovado: true, data_exame: "2026-04-01", faixaOrdem: 1, grau: 2 },
    { id: "3", aprovado: true, data_exame: "2026-08-01", faixaOrdem: 2, grau: 0 },
  ];
  assert.equal(detectarConflitoDeOrdem(historico), null);
});

test("graduação: detecta quando uma correção deixa um registro posterior com progressão menor", () => {
  const historico = [
    { id: "1", aprovado: true, data_exame: "2026-01-01", faixaOrdem: 1, grau: 0 },
    // corrigido por engano para uma faixa anterior à graduação de 2026-01-01
    { id: "2", aprovado: true, data_exame: "2026-04-01", faixaOrdem: 0, grau: 0 },
  ];
  const conflito = detectarConflitoDeOrdem(historico);
  assert.ok(conflito);
  assert.equal(conflito.anterior.id, "1");
  assert.equal(conflito.atual.id, "2");
});

test("graduação: ignora registros reprovados na checagem de conflito", () => {
  const historico = [
    { id: "1", aprovado: true, data_exame: "2026-01-01", faixaOrdem: 2, grau: 0 },
    { id: "2", aprovado: false, data_exame: "2026-04-01", faixaOrdem: 0, grau: 0 },
  ];
  assert.equal(detectarConflitoDeOrdem(historico), null);
});
