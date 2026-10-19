"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const { initializeApp, deleteApp } = require("firebase/app");
const { connectFunctionsEmulator, getFunctions, httpsCallable } = require("firebase/functions");

const { construirPayload } = require("../analytics-functions");

let app;

test.before(() => {
  app = initializeApp({ projectId: "sensei-manager-test", apiKey: "fixture-api-key" }, "analytics-test");
  connectFunctionsEmulator(getFunctions(app), "127.0.0.1", 5001);
});

test.after(async () => {
  await deleteApp(app);
});

test("construirPayload: monta o payload do Measurement Protocol sem campos vazios", () => {
  const payload = construirPayload({
    clientId: "123.456",
    nomeEvento: "page_view",
    paramsEntrada: { session_id: "789", page_location: "https://sensei-crm.web.app/", page_title: "Home" },
  });

  assert.equal(payload.client_id, "123.456");
  assert.equal(payload.events.length, 1);
  assert.equal(payload.events[0].name, "page_view");
  assert.equal(payload.events[0].params.session_id, "789");
  assert.equal(payload.events[0].params.page_location, "https://sensei-crm.web.app/");
  assert.equal(payload.events[0].params.page_title, "Home");
  assert.equal(payload.events[0].params.method, undefined);
});

test("construirPayload: sign_up sempre leva method=email, outros eventos não", () => {
  const signUp = construirPayload({ clientId: "1.1", nomeEvento: "sign_up", paramsEntrada: {} });
  assert.equal(signUp.events[0].params.method, "email");

  const cadastroIniciado = construirPayload({ clientId: "1.1", nomeEvento: "cadastro_iniciado", paramsEntrada: {} });
  assert.equal(cadastroIniciado.events[0].params.method, undefined);
});

test("construirPayload: session_id inválido (não numérico) é descartado, nunca repassado como veio", () => {
  const payload = construirPayload({
    clientId: "1.1",
    nomeEvento: "page_view",
    paramsEntrada: { session_id: "<script>forjado</script>" },
  });
  assert.equal(payload.events[0].params.session_id, undefined);
});

test("construirPayload: page_location/page_title longos demais são truncados, nunca rejeitam o evento", () => {
  const payload = construirPayload({
    clientId: "1.1",
    nomeEvento: "page_view",
    paramsEntrada: { page_location: "x".repeat(1000), page_title: "y".repeat(500) },
  });
  assert.equal(payload.events[0].params.page_location.length, 500);
  assert.equal(payload.events[0].params.page_title.length, 200);
});

test("rejeita sem declaração explícita de consentimento", async () => {
  const fn = httpsCallable(getFunctions(app), "registrarEventoAnalytics");
  await assert.rejects(
    fn({ clientId: "123.456", evento: { name: "page_view", params: {} } }),
    (erro) => erro.code === "functions/invalid-argument"
  );
  await assert.rejects(
    fn({ clientId: "123.456", consentimentoAnalytics: false, evento: { name: "page_view", params: {} } }),
    (erro) => erro.code === "functions/invalid-argument"
  );
});

test("rejeita clientId em formato inválido", async () => {
  const fn = httpsCallable(getFunctions(app), "registrarEventoAnalytics");
  await assert.rejects(
    fn({ clientId: "nao-e-um-client-id-valido", consentimentoAnalytics: true, evento: { name: "page_view", params: {} } }),
    (erro) => erro.code === "functions/invalid-argument"
  );
});

test("rejeita nome de evento fora da lista permitida", async () => {
  const fn = httpsCallable(getFunctions(app), "registrarEventoAnalytics");
  await assert.rejects(
    fn({ clientId: "123.456", consentimentoAnalytics: true, evento: { name: "evento_inventado_pelo_cliente", params: {} } }),
    (erro) => erro.code === "functions/invalid-argument"
  );
});

test("sem GA4_API_SECRET configurado: não lança erro pro chamador, só retorna ok:false", async () => {
  // Neste ambiente de teste não configuramos o secret real (pendência
  // documentada em functions/analytics-functions.js) — confirma que a
  // ausência do secret nunca propaga erro pro cliente, só é logada.
  const fn = httpsCallable(getFunctions(app), "registrarEventoAnalytics");
  const res = await fn({ clientId: "123.456", consentimentoAnalytics: true, evento: { name: "page_view", params: {} } });
  assert.equal(res.data.ok, false);
});
