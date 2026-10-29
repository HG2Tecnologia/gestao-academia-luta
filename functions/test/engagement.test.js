"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const { calcularEvasao, contarPresencasModalidadeDesde } = require("../domain/engagement");

const HOJE = new Date("2026-10-29T12:00:00");

test("evasão: aluno sem nenhuma presença não é considerado em risco", () => {
  const alunos = [{ id: "a1", nome: "Sem Presença" }];
  const risco = calcularEvasao(alunos, [], HOJE);
  assert.deepEqual(risco, []);
});

test("evasão: 14+ dias sem treinar vira alerta vermelho", () => {
  const alunos = [{ id: "a1", nome: "João" }];
  const presencas = [{ aluno_id: "a1", data: "2026-10-15" }]; // 14 dias atrás
  const risco = calcularEvasao(alunos, presencas, HOJE);
  assert.equal(risco.length, 1);
  assert.equal(risco[0].nivel, "red");
});

test("evasão: 14+ dias sem treinar vira alerta vermelho, 7-13 vira amarelo", () => {
  const alunos = [{ id: "amarelo", nome: "Amarelo" }];
  const presencas = [{ aluno_id: "amarelo", data: "2026-10-20" }]; // 9 dias atrás
  const risco = calcularEvasao(alunos, presencas, HOJE);
  assert.equal(risco.length, 1);
  assert.equal(risco[0].nivel, "yellow");
  assert.equal(risco[0].dias, 9);
});

test("evasão: menos de 7 dias sem treinar não gera alerta", () => {
  const alunos = [{ id: "a1", nome: "Recente" }];
  const presencas = [{ aluno_id: "a1", data: "2026-10-25" }]; // 4 dias atrás
  const risco = calcularEvasao(alunos, presencas, HOJE);
  assert.deepEqual(risco, []);
});

test("evasão: 'voltou com força' (4+ presenças nos últimos 7 dias) cancela o alerta", () => {
  const alunos = [{ id: "a1", nome: "Comeback" }];
  const presencas = [
    { aluno_id: "a1", data: "2026-10-15" }, // 14 dias atrás — isolada, antiga
    { aluno_id: "a1", data: "2026-10-26" },
    { aluno_id: "a1", data: "2026-10-27" },
    { aluno_id: "a1", data: "2026-10-28" },
    { aluno_id: "a1", data: "2026-10-29" },
  ];
  const risco = calcularEvasao(alunos, presencas, HOJE);
  assert.deepEqual(risco, []);
});

test("evasão: aluno inativo não entra na lista mesmo se não estiver no array de ativos", () => {
  // calcularEvasao só recebe quem já veio filtrado como ativo — não há aluno
  // nessa lista, então nenhum alerta é gerado mesmo com presença antiga de outro id.
  const alunos = [];
  const presencas = [{ aluno_id: "inativo", data: "2026-09-01" }];
  const risco = calcularEvasao(alunos, presencas, HOJE);
  assert.deepEqual(risco, []);
});

test("graduação: conta só presenças da modalidade certa, depois da última graduação", () => {
  const turmaParaModalidade = { "turma-jiu": "mod-jiu", "turma-judo": "mod-judo" };
  const presencas = [
    { turma_id: "turma-jiu", data: "2026-01-10" }, // antes da graduação — não conta
    { turma_id: "turma-jiu", data: "2026-03-01" },
    { turma_id: "turma-jiu", data: "2026-04-01" },
    { turma_id: "turma-judo", data: "2026-05-01" }, // modalidade errada — não conta
  ];
  const desde = new Date("2026-02-01T00:00:00");
  const total = contarPresencasModalidadeDesde(presencas, turmaParaModalidade, "mod-jiu", desde);
  assert.equal(total, 2);
});

test("graduação: sem graduação anterior (desde=null), conta toda a modalidade", () => {
  const turmaParaModalidade = { "turma-jiu": "mod-jiu" };
  const presencas = [
    { turma_id: "turma-jiu", data: "2020-01-01" },
    { turma_id: "turma-jiu", data: "2021-01-01" },
  ];
  const total = contarPresencasModalidadeDesde(presencas, turmaParaModalidade, "mod-jiu", null);
  assert.equal(total, 2);
});
