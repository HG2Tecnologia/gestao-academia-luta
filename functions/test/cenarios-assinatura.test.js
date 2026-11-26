"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  CENARIOS,
  CAMPOS_DE_ASSINATURA,
  montarCenario,
} = require("../scripts/cenarios-assinatura");
const { apontarParaEmulador } = require("../scripts/emulador-env");

const agora = new Date("2026-11-26T12:00:00.000Z");

test("só Black Belt pago libera o web", () => {
  const comWeb = Object.keys(CENARIOS).filter(
    (nome) => montarCenario(nome, { agora }).campos.acesso_web === true
  );
  assert.deepEqual(comWeb, ["black", "black-cancelado", "black-carencia"]);
});

test("cada cenário define ou apaga todos os campos de assinatura", () => {
  for (const nome of Object.keys(CENARIOS)) {
    const { campos, remover } = montarCenario(nome, { agora });
    for (const campo of CAMPOS_DE_ASSINATURA) {
      assert.notEqual(campo in campos, remover.includes(campo), `${nome}: ${campo}`);
    }
  }
});

test("teste de 30 dias: início, fim próximo e encerrado", () => {
  const idade = (nome) =>
    (agora - montarCenario(nome, { agora }).campos.criado_em) / 86_400_000;
  assert.equal(idade("teste"), 0);
  assert.equal(idade("teste-acabando"), 27);
  assert.ok(idade("gratis") > 30);
});

test("carência mantém o acesso mesmo com a data vencida", () => {
  const { campos } = montarCenario("black-carencia", { agora });
  assert.equal(campos.plano_tipo, 1);
  assert.ok(new Date(campos.plano_expiracao) < agora);
});

test("expirado e reembolsado perdem o acesso", () => {
  for (const nome of ["expirado", "reembolsado"]) {
    const { campos } = montarCenario(nome, { agora });
    assert.equal(campos.plano_tipo, 0, nome);
    assert.equal(campos.acesso_web, false, nome);
  }
});

test("rejeita cenário e plataforma inválidos", () => {
  assert.throws(() => montarCenario("nao-existe"), /desconhecido/);
  assert.throws(() => montarCenario("toString"), /desconhecido/);
  assert.throws(() => montarCenario("pro", { plataforma: "web" }), /inválida/);
});

test("scripts usam o emulador local por padrão e recusam endereço remoto", () => {
  const env = {};
  apontarParaEmulador(env);
  assert.equal(env.FIRESTORE_EMULATOR_HOST, "127.0.0.1:8080");
  assert.equal(env.FIREBASE_AUTH_EMULATOR_HOST, "127.0.0.1:9099");
  assert.throws(
    () => apontarParaEmulador({ FIRESTORE_EMULATOR_HOST: "firestore.googleapis.com:443" }),
    /não é um endereço local/
  );
});
