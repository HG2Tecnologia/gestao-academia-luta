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

async function seed(context, overrides = {}) {
  const firestore = context.firestore();
  await firestore.doc("academias/academy-a").set({ nome: "Academia A" });
  await firestore.doc("academias/academy-a/funcionarios/admin-a").set({
    nome: "Admin A",
    perfil: "Admin",
    ativo: true,
  });
  await firestore.doc("academias/academy-a/funcionarios/professor-a").set({
    nome: "Professor A",
    perfil: "Professor",
    ativo: true,
    permissoes: { acao_graduar: overrides.professorPodeGraduar ?? true },
  });
  await firestore.doc("academias/academy-a/faixas/faixa-branca").set({
    nome: "Branca",
    modalidade_id: "jiu-jitsu",
    ordem: 0,
    cor: "#FFFFFF",
    cor_barra: "#000000",
    tem_graus: true,
    max_graus: 4,
  });
  await firestore.doc("academias/academy-a/faixas/faixa-azul").set({
    nome: "Azul",
    modalidade_id: "jiu-jitsu",
    ordem: 1,
    cor: "#0000FF",
    cor_barra: "#000000",
    tem_graus: true,
    max_graus: 4,
  });
  await firestore.doc("academias/academy-a/graduacoes/grad-1").set({
    aluno_id: "aluno-1",
    modalidade_id: "jiu-jitsu",
    faixa_id: "faixa-branca",
    nomeFaixa: "Branca",
    faixaOrdem: 0,
    grau: 2,
    data_exame: "2026-01-10",
    aprovado: true,
  });
  await firestore.doc("academias/academy-a/graduacoes/grad-2").set({
    aluno_id: "aluno-1",
    modalidade_id: "jiu-jitsu",
    faixa_id: "faixa-branca",
    nomeFaixa: "Branca",
    faixaOrdem: 0,
    grau: 3,
    data_exame: "2026-03-10",
    aprovado: true,
  });
}

async function linkAccount(context, uid, academiaId, usuarioId, perfilNome, nome) {
  await context.firestore().doc(`usuariosFirebase/${uid}`).set({
    schemaVersion: 2,
    profile_refs: [
      { key: `${academiaId}|funcionarios|${usuarioId}`, academiaId, colecao: "funcionarios", usuarioId, perfil_nome: perfilNome, nome },
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

  app = initializeApp({ projectId, apiKey: "fixture-api-key" }, "graduacao-test");
  connectAuthEmulator(getAuth(app), "http://127.0.0.1:9099", { disableWarnings: true });
  connectFunctionsEmulator(getFunctions(app), "127.0.0.1", 5001);
});

test.after(async () => {
  await deleteApp(app);
  await environment.cleanup();
});

test("admin corrige uma graduação: transação grava depois, mantém antes na auditoria e não sinaliza conflito", async () => {
  await environment.withSecurityRulesDisabled((ctx) => seed(ctx));

  const auth = getAuth(app);
  await createUserWithEmailAndPassword(auth, "admin-a-graduacao@sensei.app", "SenhaFixtureAdmin1");
  const adminUid = auth.currentUser.uid;
  await environment.withSecurityRulesDisabled((ctx) =>
    linkAccount(ctx, adminUid, "academy-a", "admin-a", "Admin", "Admin A"),
  );

  const functions = getFunctions(app);
  const editar = httpsCallable(functions, "editarGraduacao");
  // grad-1 (2026-01-10) é cronologicamente anterior a grad-2 (2026-03-10,
  // grau 3) — corrigir para grau 1 mantém a ordem consistente.
  const resultado = await editar({
    academiaId: "academy-a",
    graduacaoId: "grad-1",
    faixaId: "faixa-branca",
    grau: 1,
    dataExame: "2026-01-10",
    observacoes: "grau corrigido",
  });

  assert.equal(resultado.data.ok, true);
  assert.equal(resultado.data.before.grau, 2);
  assert.equal(resultado.data.after.grau, 1);
  assert.equal(resultado.data.conflito, null);

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const doc = await ctx.firestore().doc("academias/academy-a/graduacoes/grad-1").get();
    assert.equal(doc.data().grau, 1);
    assert.equal(doc.data().observacoes, "grau corrigido");
    assert.ok(doc.data().editado_por);

    const auditoria = await ctx.firestore().collection("academias/academy-a/auditoria").get();
    assert.equal(auditoria.size, 1);
    const registro = auditoria.docs[0].data();
    assert.equal(registro.tipo, "edicao_graduacao");
    assert.equal(registro.antes.grau, 2);
    assert.equal(registro.depois.grau, 1);
  });
});

test("correção que inverte a ordem cronológica retorna aviso de conflito sem bloquear a gravação", async () => {
  await environment.withSecurityRulesDisabled((ctx) => seed(ctx));

  const auth = getAuth(app);
  await createUserWithEmailAndPassword(auth, "admin-b-graduacao@sensei.app", "SenhaFixtureAdmin1");
  const adminUid = auth.currentUser.uid;
  await environment.withSecurityRulesDisabled((ctx) =>
    linkAccount(ctx, adminUid, "academy-a", "admin-a", "Admin", "Admin A"),
  );

  const functions = getFunctions(app);
  const editar = httpsCallable(functions, "editarGraduacao");
  // grad-2 (2026-03-10, grau 3) corrigida por engano para grau 0 — fica
  // abaixo de grad-1 (2026-01-10, grau 2), que é cronologicamente anterior.
  const resultado = await editar({
    academiaId: "academy-a",
    graduacaoId: "grad-2",
    faixaId: "faixa-branca",
    grau: 0,
    dataExame: "2026-03-10",
  });

  assert.equal(resultado.data.ok, true);
  assert.ok(resultado.data.conflito);
  assert.match(resultado.data.conflito.mensagem, /progressão menor/);
});

test("professor sem a permissão acao_graduar não pode editar graduação", async () => {
  await environment.withSecurityRulesDisabled((ctx) => seed(ctx, { professorPodeGraduar: false }));

  const auth = getAuth(app);
  await createUserWithEmailAndPassword(auth, "professor-a-graduacao@sensei.app", "SenhaFixtureProf1");
  const profUid = auth.currentUser.uid;
  await environment.withSecurityRulesDisabled((ctx) =>
    linkAccount(ctx, profUid, "academy-a", "professor-a", "Professor", "Professor A"),
  );

  const functions = getFunctions(app);
  const editar = httpsCallable(functions, "editarGraduacao");
  await assert.rejects(
    () =>
      editar({
        academiaId: "academy-a",
        graduacaoId: "grad-1",
        faixaId: "faixa-azul",
        grau: 0,
        dataExame: "2026-01-10",
      }),
    (error) => {
      assert.equal(error.code, "functions/permission-denied");
      return true;
    },
  );
});
