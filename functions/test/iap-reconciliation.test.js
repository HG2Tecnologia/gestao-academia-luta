"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const projectId = "sensei-manager-test";

// Mesmo padrão de iap-functions.test.js: inicializa antes do require, roda
// sob `firebase emulators:exec --only firestore,auth` (isolado de produção).
require("firebase-admin").initializeApp({ projectId });
const admin = require("firebase-admin");
const db = admin.firestore();
const { _internal } = require("../iap-reconciliation");

let contador = 0;
async function criarAcademia(overrides = {}) {
  contador += 1;
  const id = `academia-reconc-${contador}`;
  await db.doc(`academias/${id}`).set({ nome: "Academia Fixture", ...overrides });
  return id;
}

const HA_10_DIAS = new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString();
const DAQUI_10_DIAS = new Date(Date.now() + 10 * 24 * 60 * 60 * 1000).toISOString();

test("reconciliação revoga cortesia vencida há 3+ dias, sem consultar loja nenhuma", async () => {
  const academiaId = await criarAcademia({
    plano_tipo: 1,
    plano_origem: "cortesia",
    plano_expiracao: HA_10_DIAS,
  });
  const resultado = await _internal.processarReconciliacaoAssinaturas();
  assert.ok(resultado.processadas >= 1);

  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_tipo, 0);
  assert.equal(doc.data().plano_status, "expirado_cortesia");
});

test("reconciliação nunca mexe em cortesia sem plano_expiracao definida", async () => {
  const academiaId = await criarAcademia({
    plano_tipo: 1,
    plano_origem: "cortesia",
    // sem plano_expiracao: nunca entra no filtro da query (plano_expiracao < limite)
  });
  await _internal.processarReconciliacaoAssinaturas();

  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_tipo, 1, "cortesia sem prazo não pode ser derrubada");
});

test("reconciliação nunca mexe em cortesia/manual ainda dentro do prazo", async () => {
  const academiaId = await criarAcademia({
    plano_tipo: 1,
    plano_origem: "manual",
    plano_expiracao: DAQUI_10_DIAS,
  });
  await _internal.processarReconciliacaoAssinaturas();

  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_tipo, 1);
});

test("reconciliação pula (sem quebrar) academia 'loja' sem plano_original_transaction_id", async () => {
  await criarAcademia({
    plano_tipo: 1,
    plano_origem: "loja",
    plano_plataforma: "ios",
    plano_expiracao: HA_10_DIAS,
    // sem plano_original_transaction_id de propósito
  });
  // Não deve lançar mesmo sem conseguir consultar a Apple.
  await assert.doesNotReject(_internal.processarReconciliacaoAssinaturas());
});
