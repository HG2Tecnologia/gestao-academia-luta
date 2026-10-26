"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const projectId = "sensei-manager-test";

// `iap-functions.js` chama `admin.firestore()` no escopo do módulo. No
// processo real da function isso roda depois do `admin.initializeApp()` de
// `index.js`; aqui, mesmo padrão já usado em modalidade-init-functions.test.js
// — inicializa um app mínimo antes do require. Rodando sob
// `firebase emulators:exec --only firestore,auth`, o Admin SDK conecta
// automaticamente no emulador (via FIRESTORE_EMULATOR_HOST), então toda
// leitura/escrita abaixo é isolada do Firestore de produção.
require("firebase-admin").initializeApp({ projectId });
const admin = require("firebase-admin");
const db = admin.firestore();
const { HttpsError } = require("firebase-functions/v2/https");
const { _internal } = require("../iap-functions");

let contador = 0;
async function criarAcademia(overrides = {}) {
  contador += 1;
  const id = `academia-iap-${contador}`;
  await db.doc(`academias/${id}`).set({ nome: "Academia Fixture", ...overrides });
  return id;
}

async function assertHttpsError(promise, code) {
  await assert.rejects(promise, (e) => {
    assert.ok(e instanceof HttpsError, `esperava HttpsError, recebeu ${e}`);
    assert.equal(e.code, code);
    return true;
  });
}

const PRODUTO = "br.com.senseimanager.pro.mensal";
const DAQUI_30_DIAS = Date.now() + 30 * 24 * 60 * 60 * 1000;
const HA_1_DIA = Date.now() - 24 * 60 * 60 * 1000;

test("rejeita produto desconhecido", async () => {
  const academiaId = await criarAcademia();
  await assertHttpsError(
    _internal.processarAtivacaoAssinatura({
      academiaId,
      productId: "produto.inventado",
      plataforma: "ios",
      ambiente: "production",
      expiresAtMs: DAQUI_30_DIAS,
    }),
    "invalid-argument"
  );
});

test("rejeita transação já expirada", async () => {
  const academiaId = await criarAcademia();
  await assertHttpsError(
    _internal.processarAtivacaoAssinatura({
      academiaId,
      productId: PRODUTO,
      plataforma: "ios",
      ambiente: "production",
      expiresAtMs: HA_1_DIA,
    }),
    "permission-denied"
  );
});

test("rejeita academia inexistente", async () => {
  await assertHttpsError(
    _internal.processarAtivacaoAssinatura({
      academiaId: "academia-que-nao-existe",
      productId: PRODUTO,
      plataforma: "ios",
      ambiente: "production",
      expiresAtMs: DAQUI_30_DIAS,
    }),
    "not-found"
  );
});

test("ativação de produção grava todos os campos corretamente", async () => {
  const academiaId = await criarAcademia();
  const resultado = await _internal.processarAtivacaoAssinatura({
    academiaId,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: DAQUI_30_DIAS,
    transactionId: "tx-1",
    originalTransactionId: "tx-original-1",
  });
  assert.deepEqual(resultado, { ok: true, ambiente: "production" });

  const doc = await db.doc(`academias/${academiaId}`).get();
  const d = doc.data();
  assert.equal(d.plano_tipo, 1);
  assert.equal(d.plano_produto_id, PRODUTO);
  assert.equal(d.plano_plataforma, "ios");
  assert.equal(d.plano_ambiente, "production");
  assert.equal(d.plano_transaction_id, "tx-1");
  assert.equal(d.plano_original_transaction_id, "tx-original-1");
  assert.equal(d.plano_expiracao, new Date(DAQUI_30_DIAS).toISOString());
  assert.ok(d.plano_assinado_em, "deveria gravar plano_assinado_em na primeira ativação");
});

test("compra de sandbox grava plano_ambiente='sandbox', distinguível de produção", async () => {
  const academiaId = await criarAcademia();
  await _internal.processarAtivacaoAssinatura({
    academiaId,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "sandbox",
    expiresAtMs: DAQUI_30_DIAS,
    transactionId: "tx-sandbox",
    originalTransactionId: "tx-sandbox-original",
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_ambiente, "sandbox");
  assert.equal(doc.data().plano_tipo, 1);
});

test("renovação (segunda ativação) não sobrescreve plano_assinado_em original", async () => {
  const academiaId = await criarAcademia({
    plano_assinado_em: "2026-01-01T00:00:00.000Z",
  });
  await _internal.processarAtivacaoAssinatura({
    academiaId,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: DAQUI_30_DIAS,
    transactionId: "tx-renovacao",
    originalTransactionId: "tx-original-1",
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_assinado_em, "2026-01-01T00:00:00.000Z");
});

test("ativação android grava plano_plataforma='android'", async () => {
  const academiaId = await criarAcademia();
  await _internal.processarAtivacaoAssinatura({
    academiaId,
    productId: PRODUTO,
    plataforma: "android",
    ambiente: "production",
    expiresAtMs: DAQUI_30_DIAS,
    transactionId: "order-1",
    originalTransactionId: "purchase-token-1",
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_plataforma, "android");
});
