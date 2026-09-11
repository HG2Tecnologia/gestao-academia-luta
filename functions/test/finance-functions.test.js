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

test("desconsidera cobranças retroativas anteriores ao corte, sem tocar em pagas nem já desconsideradas", async () => {
  await environment.withSecurityRulesDisabled(async (ctx) => {
    const pagamentos = ctx.firestore().collection("academias/academy-a/pagamentos");
    // pendente antes do corte — deve virar Desconsiderado (4).
    await pagamentos.doc("retro-pendente").set({
      aluno_id: "aluno-1",
      status: 0,
      mes_referencia: "2025-12",
      data_vencimento: "2025-12-15",
      valor: 150,
    });
    // atrasada antes do corte — também deve virar Desconsiderado (4).
    await pagamentos.doc("retro-atrasada").set({
      aluno_id: "aluno-1",
      status: 0,
      mes_referencia: "2026-01",
      data_vencimento: "2026-01-15",
      valor: 150,
    });
    // já paga antes do corte — NUNCA deve ser tocada.
    await pagamentos.doc("retro-paga").set({
      aluno_id: "aluno-1",
      status: 1,
      mes_referencia: "2026-02",
      data_vencimento: "2026-02-15",
      valor: 150,
    });
    // já desconsiderada antes do corte — permanece como está.
    await pagamentos.doc("retro-ja-desc").set({
      aluno_id: "aluno-1",
      status: 4,
      mes_referencia: "2026-03",
      data_vencimento: "2026-03-15",
      valor: 150,
    });
    // dentro/depois do corte — nunca deve ser tocada.
    await pagamentos.doc("dentro-do-corte").set({
      aluno_id: "aluno-1",
      status: 0,
      mes_referencia: "2026-09",
      data_vencimento: "2026-09-15",
      valor: 150,
    });
  });

  const functions = getFunctions(app);
  const limpar = httpsCallable(functions, "disregardChargesBeforePeriod");
  const resultado = await limpar({ academiaId: "academy-a", period: "2026-04" });

  assert.equal(resultado.data.ok, true);
  assert.equal(resultado.data.desconsideradas, 2);
  assert.equal(resultado.data.ignoradas, 2);

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const pagamentos = ctx.firestore().collection("academias/academy-a/pagamentos");
    assert.equal((await pagamentos.doc("retro-pendente").get()).data().status, 4);
    assert.equal((await pagamentos.doc("retro-atrasada").get()).data().status, 4);
    assert.equal((await pagamentos.doc("retro-paga").get()).data().status, 1, "paga não pode virar desconsiderada");
    assert.equal((await pagamentos.doc("retro-ja-desc").get()).data().status, 4);
    assert.equal((await pagamentos.doc("dentro-do-corte").get()).data().status, 0, "fora do intervalo de corte não deve mudar");
  });
});

test("corrige mensalidade duplicada (mesmo aluno + mesmo mês) preservando a paga", async () => {
  // Academia própria, isolada das demais — evita que os documentos de
  // pagamento criados pelos testes anteriores (que também usam "aluno-1" em
  // "2026-09") sejam pegos sem querer como duplicata aqui.
  await environment.withSecurityRulesDisabled(async (ctx) => {
    const firestore = ctx.firestore();
    await firestore.doc("academias/academy-b").set({ nome: "Academia B" });
    await firestore.doc("academias/academy-b/funcionarios/admin-b").set({
      nome: "Admin B",
      perfil: "Admin",
      ativo: true,
    });

    const pagamentos = firestore.collection("academias/academy-b/pagamentos");

    // Grupo A: uma paga + uma pendente no mesmo mês — fica só a paga.
    await pagamentos.doc("dup-a-pago").set({
      aluno_id: "aluno-x",
      status: 1,
      tipo: "Mensalidade",
      mes_referencia: "2026-05",
      data_vencimento: "2026-05-10",
      valor: 150,
    });
    await pagamentos.doc("dup-a-pendente").set({
      aluno_id: "aluno-x",
      status: 0,
      // Sem `tipo` — exatamente o formato do bug real (caminho ad-hoc antigo).
      mes_referencia: "2026-05",
      data_vencimento: "2026-05-10",
      valor: 150,
    });
    // Cobrança avulsa do mesmo aluno, mesmo mês — nunca é "duplicata" de
    // mensalidade, tem que ficar de fora inteiramente.
    await pagamentos.doc("avulsa-mesmo-mes").set({
      aluno_id: "aluno-x",
      status: 0,
      tipo: "Taxa de Matrícula",
      mes_referencia: "2026-05",
      data_vencimento: "2026-05-20",
      valor: 80,
    });

    // Grupo B: duas pendentes, nenhuma paga — fica a de ID determinístico.
    await pagamentos.doc("mensalidade__aluno-y__2026-06").set({
      aluno_id: "aluno-y",
      status: 0,
      tipo: "Mensalidade",
      mes_referencia: "2026-06",
      data_vencimento: "2026-06-10",
      valor: 150,
      origem: "auto",
    });
    await pagamentos.doc("dup-b-manual").set({
      aluno_id: "aluno-y",
      status: 0,
      mes_referencia: "2026-06",
      data_vencimento: "2026-06-10",
      valor: 150,
    });

    // Grupo C: DUAS pagas — ambíguo, tem que ficar intocado (revisão manual).
    await pagamentos.doc("dup-c-pago1").set({
      aluno_id: "aluno-z",
      status: 1,
      mes_referencia: "2026-07",
      data_vencimento: "2026-07-10",
      valor: 150,
    });
    await pagamentos.doc("dup-c-pago2").set({
      aluno_id: "aluno-z",
      status: 1,
      mes_referencia: "2026-07",
      data_vencimento: "2026-07-10",
      valor: 150,
    });

    // Controle: um aluno sem duplicata nenhuma — nunca deve ser tocado.
    await pagamentos.doc("sem-duplicata").set({
      aluno_id: "aluno-w",
      status: 0,
      mes_referencia: "2026-08",
      data_vencimento: "2026-08-10",
      valor: 150,
    });
  });

  const auth = getAuth(app);
  await createUserWithEmailAndPassword(auth, "admin-b-finance@sensei.app", "SenhaFixtureAdmin1");
  await environment.withSecurityRulesDisabled((ctx) =>
    ctx
      .firestore()
      .doc(`usuariosFirebase/${auth.currentUser.uid}`)
      .set({
        schemaVersion: 2,
        profile_refs: [
          {
            key: "academy-b|funcionarios|admin-b",
            academiaId: "academy-b",
            colecao: "funcionarios",
            usuarioId: "admin-b",
            perfil_nome: "Admin",
            nome: "Admin B",
          },
        ],
      }),
  );

  const functions = getFunctions(app);
  const corrigir = httpsCallable(functions, "mergeDuplicateCharges");
  const resultado = await corrigir({ academiaId: "academy-b" });

  assert.equal(resultado.data.ok, true);
  assert.equal(resultado.data.gruposComDuplicata, 3, "grupos A, B e C têm mais de um documento ativo");
  assert.equal(resultado.data.resolvidasAutomaticamente, 2, "uma resolução no grupo A e uma no B");
  assert.equal(resultado.data.ignoradasRevisaoManual, 1, "grupo C (duas pagas) fica pra revisão humana");

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const pagamentos = ctx.firestore().collection("academias/academy-b/pagamentos");

    assert.equal((await pagamentos.doc("dup-a-pago").get()).data().status, 1, "a paga nunca é tocada");
    assert.equal((await pagamentos.doc("dup-a-pendente").get()).data().status, 4, "a pendente duplicada vira desconsiderada");
    assert.equal(
      (await pagamentos.doc("avulsa-mesmo-mes").get()).data().status,
      0,
      "cobrança avulsa nunca é tratada como duplicata de mensalidade",
    );

    assert.equal(
      (await pagamentos.doc("mensalidade__aluno-y__2026-06").get()).data().status,
      0,
      "o ID determinístico é o que fica quando ninguém pagou ainda",
    );
    assert.equal((await pagamentos.doc("dup-b-manual").get()).data().status, 4);

    assert.equal((await pagamentos.doc("dup-c-pago1").get()).data().status, 1, "ambíguo: nada é tocado");
    assert.equal((await pagamentos.doc("dup-c-pago2").get()).data().status, 1, "ambíguo: nada é tocado");

    assert.equal((await pagamentos.doc("sem-duplicata").get()).data().status, 0);
  });
});
