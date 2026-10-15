"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const { initializeApp, deleteApp } = require("firebase/app");
const { connectAuthEmulator, createUserWithEmailAndPassword, getAuth, signInWithEmailAndPassword } = require("firebase/auth");
const { connectFunctionsEmulator, getFunctions, httpsCallable } = require("firebase/functions");
const { Timestamp } = require("firebase/firestore");
const { initializeTestEnvironment } = require("@firebase/rules-unit-testing");

const projectId = "sensei-manager-test";
let environment;
let app;
let contadorUid = 0;

async function criarUsuario() {
  contadorUid += 1;
  const email = `atribuicao-${contadorUid}@example.invalid`;
  const cred = await createUserWithEmailAndPassword(getAuth(app), email, "SenhaFixture123");
  return { uid: cred.user.uid, email };
}

async function criarAcademia(academiaId, uidDono, criadoEmMs) {
  // `withSecurityRulesDisabled` opera no SDK cliente (`firebase/firestore`),
  // não no admin — precisa do `Timestamp` do pacote cliente, senão o
  // próprio emulador rejeita o `.set()` como dado inválido.
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`academias/${academiaId}`).set({
      nome: "Academia Fixture",
      created_by_uid: uidDono,
      criado_em: Timestamp.fromMillis(criadoEmMs),
    });
  });
}

async function lerAtribuicao(academiaId) {
  let resultado;
  await environment.withSecurityRulesDisabled(async (context) => {
    const snap = await context.firestore().doc(`academias/${academiaId}/_atribuicao/dados`).get();
    resultado = snap.exists ? snap.data() : null;
  });
  return resultado;
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
  app = initializeApp({ projectId, apiKey: "fixture-api-key" }, "attribution-test");
  connectAuthEmulator(getAuth(app), "http://127.0.0.1:9099", { disableWarnings: true });
  connectFunctionsEmulator(getFunctions(app), "127.0.0.1", 5001);
});

test.after(async () => {
  await deleteApp(app);
  await environment.cleanup();
});

test.afterEach(async () => {
  await environment.clearFirestore();
});

test("registra atribuição com sucesso e persiste só os campos esperados", async () => {
  const academiaId = "academia-atrib-sucesso";
  const { uid, email } = await criarUsuario();
  await criarAcademia(academiaId, uid, Date.now());
  await signInWithEmailAndPassword(getAuth(app), email, "SenhaFixture123");

  const fn = httpsCallable(getFunctions(app), "registrarAtribuicaoCadastro");
  const res = await fn({
    academiaId,
    consentimentoAnalytics: true,
    atribuicao: {
      classificacao: "identificada",
      utm_source: "google",
      utm_medium: "cpc",
      utm_campaign: "fixture",
      click_id: "abc123",
      click_id_type: "gclid",
      referrer_host: "google.com",
    },
  });

  assert.equal(res.data.ok, true);
  assert.equal(res.data.jaRegistrado, false);

  const gravado = await lerAtribuicao(academiaId);
  assert.equal(gravado.classificacao, "identificada");
  assert.equal(gravado.utm_source, "google");
  assert.equal(gravado.click_id, "abc123");
  assert.equal(gravado.click_id_type, "gclid");

  // expira_em: ~90 dias a partir de agora, calculado no servidor.
  const NOVENTA_DIAS_MS = 90 * 24 * 60 * 60 * 1000;
  const expiraEmMs = gravado.expira_em.toMillis();
  const esperadoMs = Date.now() + NOVENTA_DIAS_MS;
  assert.ok(
    Math.abs(expiraEmMs - esperadoMs) < 5 * 60 * 1000,
    `expira_em deveria estar a ~90 dias de agora (diff: ${Math.abs(expiraEmMs - esperadoMs)}ms)`
  );
});

test("idempotente: segunda chamada não sobrescreve o registro original", async () => {
  const academiaId = "academia-atrib-idempotente";
  const { uid, email } = await criarUsuario();
  await criarAcademia(academiaId, uid, Date.now());
  await signInWithEmailAndPassword(getAuth(app), email, "SenhaFixture123");

  const fn = httpsCallable(getFunctions(app), "registrarAtribuicaoCadastro");
  await fn({ academiaId, consentimentoAnalytics: true, atribuicao: { classificacao: "identificada", utm_source: "google" } });
  const res2 = await fn({ academiaId, consentimentoAnalytics: true, atribuicao: { classificacao: "identificada", utm_source: "facebook" } });

  assert.equal(res2.data.jaRegistrado, true);
  const gravado = await lerAtribuicao(academiaId);
  assert.equal(gravado.utm_source, "google", "não deve sobrescrever com a segunda tentativa");
});

test("click_id_type inválido é descartado, nunca gravado como veio", async () => {
  const academiaId = "academia-atrib-clickid-invalido";
  const { uid, email } = await criarUsuario();
  await criarAcademia(academiaId, uid, Date.now());
  await signInWithEmailAndPassword(getAuth(app), email, "SenhaFixture123");

  const fn = httpsCallable(getFunctions(app), "registrarAtribuicaoCadastro");
  await fn({
    academiaId,
    consentimentoAnalytics: true,
    atribuicao: { classificacao: "identificada", click_id: "forjado", click_id_type: "tipo_inventado" },
  });

  const gravado = await lerAtribuicao(academiaId);
  assert.equal(gravado.click_id_type, null);
  assert.equal(gravado.click_id, null);
});

test("rejeita quem não é o criador da academia, nada é gravado", async () => {
  const academiaId = "academia-atrib-nao-dono";
  const { uid: dono } = await criarUsuario();
  await criarAcademia(academiaId, dono, Date.now());

  const { email: emailIntruso } = await criarUsuario();
  await signInWithEmailAndPassword(getAuth(app), emailIntruso, "SenhaFixture123");

  const fn = httpsCallable(getFunctions(app), "registrarAtribuicaoCadastro");
  await assert.rejects(
    fn({ academiaId, consentimentoAnalytics: true, atribuicao: { classificacao: "identificada" } }),
    (erro) => erro.code === "functions/permission-denied"
  );

  const gravado = await lerAtribuicao(academiaId);
  assert.equal(gravado, null);
});

test("rejeita fora da janela de 30 minutos, nada é gravado", async () => {
  const academiaId = "academia-atrib-janela-expirada";
  const { uid, email } = await criarUsuario();
  await criarAcademia(academiaId, uid, Date.now() - 31 * 60 * 1000);
  await signInWithEmailAndPassword(getAuth(app), email, "SenhaFixture123");

  const fn = httpsCallable(getFunctions(app), "registrarAtribuicaoCadastro");
  await assert.rejects(
    fn({ academiaId, consentimentoAnalytics: true, atribuicao: { classificacao: "identificada" } }),
    (erro) => erro.code === "functions/failed-precondition"
  );

  const gravado = await lerAtribuicao(academiaId);
  assert.equal(gravado, null);
});

test("academia inexistente é rejeitada", async () => {
  const { email } = await criarUsuario();
  await signInWithEmailAndPassword(getAuth(app), email, "SenhaFixture123");

  const fn = httpsCallable(getFunctions(app), "registrarAtribuicaoCadastro");
  await assert.rejects(
    fn({ academiaId: "academia-que-nao-existe", consentimentoAnalytics: true, atribuicao: { classificacao: "identificada" } }),
    (erro) => erro.code === "functions/not-found"
  );
});

test("sem declaração explícita de consentimento: nada é gravado, mesmo com dados válidos", async () => {
  const academiaId = "academia-atrib-sem-consentimento";
  const { uid, email } = await criarUsuario();
  await criarAcademia(academiaId, uid, Date.now());
  await signInWithEmailAndPassword(getAuth(app), email, "SenhaFixture123");

  const fn = httpsCallable(getFunctions(app), "registrarAtribuicaoCadastro");
  await assert.rejects(
    fn({ academiaId, atribuicao: { classificacao: "identificada", utm_source: "google" } }),
    (erro) => erro.code === "functions/invalid-argument"
  );
  await assert.rejects(
    fn({ academiaId, consentimentoAnalytics: false, atribuicao: { classificacao: "identificada" } }),
    (erro) => erro.code === "functions/invalid-argument"
  );

  const gravado = await lerAtribuicao(academiaId);
  assert.equal(gravado, null);
});

test("classificação inválida enviada pelo cliente é normalizada, nunca aceita como veio", async () => {
  const academiaId = "academia-atrib-classificacao-forjada";
  const { uid, email } = await criarUsuario();
  await criarAcademia(academiaId, uid, Date.now());
  await signInWithEmailAndPassword(getAuth(app), email, "SenhaFixture123");

  const fn = httpsCallable(getFunctions(app), "registrarAtribuicaoCadastro");
  await fn({ academiaId, consentimentoAnalytics: true, atribuicao: { classificacao: "organico_inventado_pelo_cliente" } });

  const gravado = await lerAtribuicao(academiaId);
  assert.equal(gravado.classificacao, "nao_identificada");
});
