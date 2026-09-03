"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const { initializeApp, deleteApp } = require("firebase/app");
const { connectAuthEmulator, createUserWithEmailAndPassword, getAuth } = require("firebase/auth");
const { connectFunctionsEmulator, getFunctions, httpsCallable } = require("firebase/functions");
const { initializeTestEnvironment } = require("@firebase/rules-unit-testing");

const projectId = "sensei-manager-test";
let environment;
let app;

async function seed(context) {
  const firestore = context.firestore();
  await firestore.doc("academias/academy-a").set({ nome: "Academia A" });
  await firestore.doc("academias/academy-a/funcionarios/admin-a").set({
    nome: "Admin A",
    perfil: "Admin",
    ativo: true,
  });
  await firestore.doc("academias/academy-a/planos/plano-basico").set({
    nome: "Básico",
    valor_mensal: 150,
    ativo: true,
  });
  // aluno ativo com plano e dia de vencimento próprio — deve gerar cobrança.
  await firestore.doc("academias/academy-a/usuarios/aluno-1").set({
    nome: "Aluno Um",
    ativo: true,
    plano_id: "plano-basico",
    dia_vencimento: 15,
  });
  // aluno ativo mas SEM plano — não deve gerar cobrança.
  await firestore.doc("academias/academy-a/usuarios/aluno-2").set({
    nome: "Aluno Dois",
    ativo: true,
  });
  // aluno inativo com plano — não deve gerar cobrança.
  await firestore.doc("academias/academy-a/usuarios/aluno-3").set({
    nome: "Aluno Três",
    ativo: false,
    plano_id: "plano-basico",
  });
}

async function linkAdmin(context, uid) {
  await context.firestore().doc(`usuariosFirebase/${uid}`).set({
    schemaVersion: 2,
    profile_refs: [
      { key: "academy-a|funcionarios|admin-a", academiaId: "academy-a", colecao: "funcionarios", usuarioId: "admin-a", perfil_nome: "Admin", nome: "Admin A" },
    ],
  });
}

test.before(async () => {
  const rulesPath = path.join(__dirname, "..", "..", "scripts", "migrate-firestore", "firestore.rules");
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: fs.readFileSync(rulesPath, "utf8"),
    },
  });

  app = initializeApp({ projectId, apiKey: "fixture-api-key" }, "finance-test");
  connectAuthEmulator(getAuth(app), "http://127.0.0.1:9099", { disableWarnings: true });
  connectFunctionsEmulator(getFunctions(app), "127.0.0.1", 5001);
});

test.after(async () => {
  await deleteApp(app);
  await environment.cleanup();
});

test("gera mensalidade só para aluno ativo com plano, respeitando o dia de vencimento", async () => {
  await environment.withSecurityRulesDisabled((ctx) => seed(ctx));

  const auth = getAuth(app);
  await createUserWithEmailAndPassword(auth, "admin-a-finance@sensei.app", "SenhaFixtureAdmin1");
  await environment.withSecurityRulesDisabled((ctx) => linkAdmin(ctx, auth.currentUser.uid));

  const functions = getFunctions(app);
  const garantir = httpsCallable(functions, "ensureChargesForPeriod");
  const resultado = await garantir({ academiaId: "academy-a", period: "2026-09" });

  assert.equal(resultado.data.ok, true);
  assert.equal(resultado.data.criadas, 1);
  assert.equal(resultado.data.ignoradas, 0);

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const cobranca = await ctx
      .firestore()
      .doc("academias/academy-a/pagamentos/mensalidade__aluno-1__2026-09")
      .get();
    assert.equal(cobranca.exists, true);
    assert.equal(cobranca.data().valor, 150);
    assert.equal(cobranca.data().data_vencimento, "2026-09-15");
    assert.equal(cobranca.data().mes_referencia, "2026-09");
    assert.equal(cobranca.data().origem, "auto");

    const semPlano = await ctx
      .firestore()
      .doc("academias/academy-a/pagamentos/mensalidade__aluno-2__2026-09")
      .get();
    assert.equal(semPlano.exists, false);

    const inativo = await ctx
      .firestore()
      .doc("academias/academy-a/pagamentos/mensalidade__aluno-3__2026-09")
      .get();
    assert.equal(inativo.exists, false);
  });
});

test("chamar de novo para a mesma competência é idempotente — não duplica nem sobrescreve", async () => {
  // Marca a cobrança como paga para provar que uma segunda chamada não a
  // reseta nem a duplica.
  await environment.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc("academias/academy-a/pagamentos/mensalidade__aluno-1__2026-09").update({
      status: 1,
      data_pagamento: "2026-09-10",
    });
  });

  const functions = getFunctions(app);
  const garantir = httpsCallable(functions, "ensureChargesForPeriod");
  const resultado = await garantir({ academiaId: "academy-a", period: "2026-09" });

  assert.equal(resultado.data.criadas, 0);
  assert.equal(resultado.data.ignoradas, 1);

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const cobranca = await ctx
      .firestore()
      .doc("academias/academy-a/pagamentos/mensalidade__aluno-1__2026-09")
      .get();
    assert.equal(cobranca.data().status, 1, "não deve resetar o pagamento já registrado");
    assert.equal(cobranca.data().data_pagamento, "2026-09-10");
  });
});
