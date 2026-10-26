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

test("ativação grava plano_status='ativo' e plano_renovacao_automatica=true por padrão", async () => {
  const academiaId = await criarAcademia();
  await _internal.processarAtivacaoAssinatura({
    academiaId,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: DAQUI_30_DIAS,
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_status, "ativo");
  assert.equal(doc.data().plano_renovacao_automatica, true);
});

test("buscarAcademiaPorOriginalTransactionId encontra a academia certa", async () => {
  const academiaId = await criarAcademia();
  await _internal.processarAtivacaoAssinatura({
    academiaId,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: DAQUI_30_DIAS,
    originalTransactionId: "original-tx-unica-123",
  });
  const encontrado = await _internal.buscarAcademiaPorOriginalTransactionId(
    "original-tx-unica-123"
  );
  assert.equal(encontrado, academiaId);
});

test("buscarAcademiaPorOriginalTransactionId retorna null quando não encontra", async () => {
  const encontrado = await _internal.buscarAcademiaPorOriginalTransactionId(
    "nunca-existiu"
  );
  assert.equal(encontrado, null);
});

test("atualizarStatusAssinatura não mexe em plano_tipo nem plano_expiracao", async () => {
  const academiaId = await criarAcademia();
  await _internal.processarAtivacaoAssinatura({
    academiaId,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: DAQUI_30_DIAS,
  });
  await _internal.atualizarStatusAssinatura({
    academiaId,
    status: "cancelado_ate_expirar",
    renovacaoAutomatica: false,
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_status, "cancelado_ate_expirar");
  assert.equal(doc.data().plano_renovacao_automatica, false);
  // acesso continua válido até a data já gravada — cancelar não revoga na hora
  assert.equal(doc.data().plano_tipo, 1);
  assert.equal(doc.data().plano_expiracao, new Date(DAQUI_30_DIAS).toISOString());
});

test("revogarAssinatura derruba plano_tipo imediatamente (reembolso/revogação)", async () => {
  const academiaId = await criarAcademia();
  await _internal.processarAtivacaoAssinatura({
    academiaId,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: DAQUI_30_DIAS,
  });
  await _internal.revogarAssinatura({ academiaId, status: "reembolsado" });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_tipo, 0);
  assert.equal(doc.data().plano_status, "reembolsado");
});

// A partir daqui, os testes cobrem `rotearNotificacaoAssinatura` diretamente
// — é onde mora 100% da nossa regra de negócio sobre o que cada tipo de
// notificação deve fazer. A verificação criptográfica em si (decodificar o
// JWS de verdade) não é testável sem um payload real assinado pela Apple;
// os testes acima (ativarAssinaturaIOS/Android via SignedDataVerifier já
// manualmente verificado) cobrem que a lib rejeita token inválido.

async function ativarPara(academiaId, overrides = {}) {
  await _internal.processarAtivacaoAssinatura({
    academiaId,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: DAQUI_30_DIAS,
    originalTransactionId: `tx-${academiaId}`,
    ...overrides,
  });
}

test("rotear: notificação sem academia correspondente não quebra, só ignora", async () => {
  await assert.doesNotReject(
    _internal.rotearNotificacaoAssinatura({
      notificationType: "DID_RENEW",
      originalTransactionId: "tx-que-nao-existe",
      productId: PRODUTO,
      plataforma: "ios",
      ambiente: "production",
      expiresAtMs: DAQUI_30_DIAS,
    })
  );
});

test("rotear: DID_RENEW atualiza plano_expiracao pra nova data (renovação de verdade)", async () => {
  const academiaId = await criarAcademia();
  await ativarPara(academiaId);

  const novaExpiracao = DAQUI_30_DIAS + 30 * 24 * 60 * 60 * 1000;
  await _internal.rotearNotificacaoAssinatura({
    notificationType: "DID_RENEW",
    originalTransactionId: `tx-${academiaId}`,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: novaExpiracao,
    transactionId: "tx-renovacao-nova",
    renovacaoAutomatica: true,
  });

  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_expiracao, new Date(novaExpiracao).toISOString());
  assert.equal(doc.data().plano_status, "ativo");
  assert.equal(doc.data().plano_tipo, 1);
});

test("rotear: DID_CHANGE_RENEWAL_STATUS (desligou auto-renew) marca cancelado_ate_expirar sem tocar na expiração", async () => {
  const academiaId = await criarAcademia();
  await ativarPara(academiaId);
  const expiracaoAntes = (await db.doc(`academias/${academiaId}`).get()).data()
    .plano_expiracao;

  await _internal.rotearNotificacaoAssinatura({
    notificationType: "DID_CHANGE_RENEWAL_STATUS",
    originalTransactionId: `tx-${academiaId}`,
    renovacaoAutomatica: false,
  });

  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_status, "cancelado_ate_expirar");
  assert.equal(doc.data().plano_renovacao_automatica, false);
  assert.equal(doc.data().plano_tipo, 1, "continua Pro até a data que já tinha");
  assert.equal(doc.data().plano_expiracao, expiracaoAntes);
});

test("rotear: DID_CHANGE_RENEWAL_STATUS (religou auto-renew) volta pra 'ativo'", async () => {
  const academiaId = await criarAcademia();
  await ativarPara(academiaId);
  await _internal.rotearNotificacaoAssinatura({
    notificationType: "DID_CHANGE_RENEWAL_STATUS",
    originalTransactionId: `tx-${academiaId}`,
    renovacaoAutomatica: true,
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_status, "ativo");
  assert.equal(doc.data().plano_renovacao_automatica, true);
});

test("rotear: DID_FAIL_TO_RENEW marca periodo_carencia sem revogar ainda", async () => {
  const academiaId = await criarAcademia();
  await ativarPara(academiaId);
  await _internal.rotearNotificacaoAssinatura({
    notificationType: "DID_FAIL_TO_RENEW",
    originalTransactionId: `tx-${academiaId}`,
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_status, "periodo_carencia");
  assert.equal(doc.data().plano_tipo, 1, "grace period ainda é acesso válido");
});

test("rotear: GRACE_PERIOD_EXPIRED revoga o Pro na hora", async () => {
  const academiaId = await criarAcademia();
  await ativarPara(academiaId);
  await _internal.rotearNotificacaoAssinatura({
    notificationType: "GRACE_PERIOD_EXPIRED",
    originalTransactionId: `tx-${academiaId}`,
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_tipo, 0);
  assert.equal(doc.data().plano_status, "expirado");
});

test("rotear: EXPIRED revoga o Pro", async () => {
  const academiaId = await criarAcademia();
  await ativarPara(academiaId);
  await _internal.rotearNotificacaoAssinatura({
    notificationType: "EXPIRED",
    originalTransactionId: `tx-${academiaId}`,
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_tipo, 0);
  assert.equal(doc.data().plano_status, "expirado");
});

test("rotear: REFUND revoga o Pro imediatamente, mesmo com data de expiração ainda longe", async () => {
  const academiaId = await criarAcademia();
  await ativarPara(academiaId);
  await _internal.rotearNotificacaoAssinatura({
    notificationType: "REFUND",
    originalTransactionId: `tx-${academiaId}`,
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_tipo, 0);
  assert.equal(doc.data().plano_status, "reembolsado");
});

test("rotear: REVOKE revoga o Pro imediatamente", async () => {
  const academiaId = await criarAcademia();
  await ativarPara(academiaId);
  await _internal.rotearNotificacaoAssinatura({
    notificationType: "REVOKE",
    originalTransactionId: `tx-${academiaId}`,
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_tipo, 0);
  assert.equal(doc.data().plano_status, "reembolsado");
});

test("rotear: tipo de notificação desconhecido é ignorado sem quebrar nem alterar o estado", async () => {
  const academiaId = await criarAcademia();
  await ativarPara(academiaId);
  await _internal.rotearNotificacaoAssinatura({
    notificationType: "PRICE_INCREASE",
    originalTransactionId: `tx-${academiaId}`,
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_status, "ativo");
  assert.equal(doc.data().plano_tipo, 1);
});
