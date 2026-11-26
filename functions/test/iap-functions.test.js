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
  assert.equal(
    d.plano_origem,
    "loja",
    "toda ativação validada de verdade com a Apple/Google é origem 'loja', nunca cortesia/manual"
  );
});

test("ativação grava um evento em eventos_assinatura (histórico de auditoria)", async () => {
  const academiaId = await criarAcademia();
  await _internal.processarAtivacaoAssinatura({
    academiaId,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: DAQUI_30_DIAS,
    origemEvento: "app",
  });

  const snap = await db
    .collection("eventos_assinatura")
    .where("academiaId", "==", academiaId)
    .get();
  assert.equal(snap.size, 1);
  const evento = snap.docs[0].data();
  assert.equal(evento.evento, "ativacao");
  assert.equal(evento.status_novo, "ativo");
  assert.equal(evento.origem, "app");
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
    originalTransactionId: "tx-original-renovacao",
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

  const eventos = await db
    .collection("eventos_assinatura")
    .where("academiaId", "==", academiaId)
    .where("evento", "==", "revogado")
    .get();
  assert.equal(eventos.size, 1);
  assert.equal(eventos.docs[0].data().status_novo, "reembolsado");
});

test("revogarAssinatura nunca mexe em plano_origem (cortesia/manual continuam protegidas)", async () => {
  const academiaId = await criarAcademia({ plano_tipo: 1, plano_origem: "cortesia" });
  await _internal.revogarAssinatura({ academiaId, status: "expirado" });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_tipo, 0);
  assert.equal(
    doc.data().plano_origem,
    "cortesia",
    "revogar o Pro não deve apagar de onde ele veio"
  );
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

test("rotear: DID_CHANGE_RENEWAL_PREF (upgrade/downgrade de plano) atualiza produto e expiração", async () => {
  const academiaId = await criarAcademia();
  await ativarPara(academiaId);

  const novoProduto = "br.com.senseimanager.pro.anual";
  const novaExpiracao = DAQUI_30_DIAS + 365 * 24 * 60 * 60 * 1000;
  await _internal.rotearNotificacaoAssinatura({
    notificationType: "DID_CHANGE_RENEWAL_PREF",
    originalTransactionId: `tx-${academiaId}`,
    productId: novoProduto,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: novaExpiracao,
    transactionId: "tx-upgrade",
    renovacaoAutomatica: true,
  });

  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_produto_id, novoProduto);
  assert.equal(doc.data().plano_expiracao, new Date(novaExpiracao).toISOString());
  assert.equal(doc.data().plano_tipo, 1);
});

test("rotear: REFUND_REVERSED restaura o Pro depois de um reembolso desfeito", async () => {
  const academiaId = await criarAcademia();
  await ativarPara(academiaId);
  await _internal.rotearNotificacaoAssinatura({
    notificationType: "REFUND",
    originalTransactionId: `tx-${academiaId}`,
  });
  let doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_tipo, 0, "revogado pelo reembolso");

  await _internal.rotearNotificacaoAssinatura({
    notificationType: "REFUND_REVERSED",
    originalTransactionId: `tx-${academiaId}`,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: DAQUI_30_DIAS,
    transactionId: "tx-refund-reversed",
  });
  doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_tipo, 1, "Apple desfez o reembolso, acesso volta");
  assert.equal(doc.data().plano_status, "ativo");
});

test("rotear: RENEWAL_EXTENDED (cortesia da Apple) atualiza a data de expiração", async () => {
  const academiaId = await criarAcademia();
  await ativarPara(academiaId);

  const novaExpiracao = DAQUI_30_DIAS + 7 * 24 * 60 * 60 * 1000;
  await _internal.rotearNotificacaoAssinatura({
    notificationType: "RENEWAL_EXTENDED",
    originalTransactionId: `tx-${academiaId}`,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: novaExpiracao,
    transactionId: "tx-extensao",
  });
  const doc = await db.doc(`academias/${academiaId}`).get();
  assert.equal(doc.data().plano_expiracao, new Date(novaExpiracao).toISOString());
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

test("mapa Android: assinatura pausada é tratada como expirada (sem acesso até o usuário retomar)", () => {
  assert.equal(
    _internal.SUBSCRIPTION_STATE_PARA_NOTIFICATION_TYPE.SUBSCRIPTION_STATE_PAUSED,
    "EXPIRED"
  );
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

// ── Quem pode ativar ────────────────────────────────────────────────────────

const iapFunctions = require("../iap-functions");

async function criarConta(uid, dados) {
  await db.doc(`usuariosFirebase/${uid}`).set(dados);
  return uid;
}
const contaV2 = (academiaId, papel) => ({
  schemaVersion: 2,
  academiaId,
  perfil: papel,
  academy_ids: [academiaId],
  roles_by_academy: { [academiaId]: [papel] },
});

// Chama a function de verdade com uma compra falsa: quem passa pela checagem de
// permissão só falha depois, na validação junto à loja.
const CHAMADAS = [
  ["ativarAssinaturaIOS", { jwsTransaction: "falso" }],
  ["ativarAssinaturaAndroid", { purchaseToken: "falso" }],
];
const chamar = (nome, uid, data) => iapFunctions[nome].run({ auth: { uid }, data });

for (const [nome, compra] of CHAMADAS) {
  test(`${nome}: recusa quem não é da equipe da academia`, async () => {
    const academiaId = await criarAcademia();
    const outraAcademia = await criarAcademia();
    const casos = [
      await criarConta(`${nome}-sem-conta-ok`, contaV2(outraAcademia, "Admin")),
      await criarConta(`${nome}-aluno`, contaV2(academiaId, "Aluno")),
      `${nome}-inexistente`,
    ];
    for (const uid of casos) {
      await assert.rejects(chamar(nome, uid, { academiaId, ...compra }), (e) => {
        assert.equal(e.code, "permission-denied");
        assert.match(e.message, /não tem permissão/);
        return true;
      });
    }
  });

  test(`${nome}: Admin, Secretaria, Professor e conta antiga passam da permissão`, async () => {
    const academiaId = await criarAcademia();
    const contas = [
      contaV2(academiaId, "Admin"),
      contaV2(academiaId, "Secretaria"),
      contaV2(academiaId, "Professor"),
      { academiaId, perfil: "Admin" }, // conta v1
    ];
    for (const [i, conta] of contas.entries()) {
      const uid = await criarConta(`${nome}-equipe-${i}`, conta);
      await assert.rejects(chamar(nome, uid, { academiaId, ...compra }), (e) => {
        assert.match(e.message, /validar a compra/);
        return true;
      });
    }
  });

  test(`${nome}: rejeita academiaId com barra`, async () => {
    await assertHttpsError(
      chamar(nome, "qualquer", { academiaId: "a/usuarios/b", ...compra }),
      "invalid-argument"
    );
  });
}

// ── Uma compra, uma academia ────────────────────────────────────────────────

const ativarCompra = (academiaId, originalTransactionId, extra = {}) =>
  _internal.processarAtivacaoAssinatura({
    academiaId,
    productId: PRODUTO,
    plataforma: "ios",
    ambiente: "production",
    expiresAtMs: DAQUI_30_DIAS,
    originalTransactionId,
    ...extra,
  });
const lerAcademia = async (id) => (await db.doc(`academias/${id}`).get()).data();

test("compra em uso não ativa uma segunda academia", async () => {
  const a = await criarAcademia();
  const b = await criarAcademia({ plano_tipo: 0 });
  await ativarCompra(a, "compra-em-uso");
  await assertHttpsError(ativarCompra(b, "compra-em-uso"), "already-exists");
  assert.equal((await lerAcademia(b)).plano_tipo, 0);
  assert.equal((await lerAcademia(a)).plano_tipo, 1);
});

test("a mesma academia restaura a própria compra quantas vezes precisar", async () => {
  const a = await criarAcademia();
  await ativarCompra(a, "compra-restaurada");
  await ativarCompra(a, "compra-restaurada");
  assert.equal((await lerAcademia(a)).plano_tipo, 1);
});

test("carência e cancelamento ainda no prazo contam como compra em uso", async () => {
  for (const [i, estado] of [
    { plano_status: "periodo_carencia", plano_expiracao: new Date(HA_1_DIA).toISOString() },
    { plano_status: "cancelado_ate_expirar", plano_expiracao: new Date(DAQUI_30_DIAS).toISOString() },
  ].entries()) {
    const compra = `compra-estado-${i}`;
    await criarAcademia({
      plano_tipo: 1, plano_origem: "loja", plano_original_transaction_id: compra, ...estado,
    });
    await assertHttpsError(ativarCompra(await criarAcademia(), compra), "already-exists");
  }
});

test("compra de academia revogada pode ir para outra, e os webhooks passam a achar a nova", async () => {
  const a = await criarAcademia();
  const b = await criarAcademia();
  await ativarCompra(a, "compra-revogada");
  await _internal.revogarAssinatura({ academiaId: a, status: "expirado" });
  await ativarCompra(b, "compra-revogada");
  assert.equal((await lerAcademia(a)).plano_original_transaction_id, undefined);
  assert.equal((await lerAcademia(b)).plano_tipo, 1);
  assert.equal(await _internal.buscarAcademiaPorOriginalTransactionId("compra-revogada"), b);
});

test("academia vencida que ainda constava como Pro perde o acesso na transferência", async () => {
  const vencida = await criarAcademia({
    plano_tipo: 1, plano_origem: "loja", plano_status: "ativo",
    plano_expiracao: new Date(HA_1_DIA).toISOString(),
    plano_original_transaction_id: "compra-vencida",
  });
  await ativarCompra(await criarAcademia(), "compra-vencida");
  const d = await lerAcademia(vencida);
  assert.equal(d.plano_tipo, 0);
  assert.equal(d.plano_status, "transferido");
});

test("transferência não derruba cortesia que guardava o identificador antigo", async () => {
  const cortesia = await criarAcademia({
    plano_tipo: 1, plano_origem: "cortesia", plano_original_transaction_id: "compra-antiga",
  });
  await ativarCompra(await criarAcademia(), "compra-antiga");
  const d = await lerAcademia(cortesia);
  assert.equal(d.plano_tipo, 1);
  assert.equal(d.plano_original_transaction_id, undefined);
});

test("academia excluída não prende a compra", async () => {
  const a = await criarAcademia();
  await ativarCompra(a, "compra-de-excluida");
  await db.doc(`academias/${a}`).delete();
  await ativarCompra(await criarAcademia(), "compra-de-excluida");
});

test("duplicidade que já existia não quebra a restauração de quem já tem a compra", async () => {
  const dados = {
    plano_tipo: 1, plano_origem: "loja", plano_original_transaction_id: "compra-duplicada",
    plano_expiracao: new Date(DAQUI_30_DIAS).toISOString(),
  };
  const a = await criarAcademia(dados);
  await criarAcademia(dados);
  await ativarCompra(a, "compra-duplicada");
});

test("ativações simultâneas da mesma compra: só uma academia ganha", async () => {
  const academias = [await criarAcademia(), await criarAcademia(), await criarAcademia()];
  const resultados = await Promise.allSettled(
    academias.map((id) => ativarCompra(id, "compra-simultanea"))
  );
  assert.equal(resultados.filter((r) => r.status === "fulfilled").length, 1);
  const pagas = (await Promise.all(academias.map(lerAcademia))).filter((d) => d.plano_tipo === 1);
  assert.equal(pagas.length, 1);
});

test("webhook e reconciliação renovam sem passar pela trava", async () => {
  const dados = {
    plano_tipo: 1, plano_origem: "loja", plano_original_transaction_id: "compra-webhook",
    plano_expiracao: new Date(DAQUI_30_DIAS).toISOString(),
  };
  const a = await criarAcademia(dados);
  await ativarCompra(a, "compra-webhook", { origemEvento: "webhook" });
  await ativarCompra(a, "compra-webhook", { origemEvento: "reconciliacao" });
});

// ── Black Belt e acesso ao web ──────────────────────────────────────────────

const {
  PRODUTOS_BLACK_BELT,
  PRODUTOS_PRO,
} = require("../domain/subscription-access");

const BLACK = "br.com.senseimanager.black.mensal";
const BLACK_ANUAL = "br.com.senseimanager.black.anual";
const emDias = (n) => Date.now() + n * 24 * 60 * 60 * 1000;

for (const produto of [...PRODUTOS_PRO, ...PRODUTOS_BLACK_BELT]) {
  test(`ativar ${produto} define o acesso ao web`, async () => {
    const id = await criarAcademia();
    await ativarCompra(id, `compra-${produto}`, { productId: produto });
    const d = await lerAcademia(id);
    assert.equal(d.plano_tipo, 1);
    assert.equal(d.acesso_web, produto.includes(".black."));
  });
}

// Apple: o identificador da assinatura não muda nas trocas de plano.
async function assinanteApple(productId, extra = {}) {
  const id = await criarAcademia();
  const compra = `apple-${id}`;
  await ativarCompra(id, compra, { productId, transacaoEmMs: emDias(-10), ...extra });
  const evento = (notificationType, dados = {}) =>
    _internal.rotearNotificacaoAssinatura({
      notificationType,
      originalTransactionId: compra,
      productId,
      plataforma: "ios",
      ambiente: "production",
      expiresAtMs: DAQUI_30_DIAS,
      transacaoEmMs: emDias(-10),
      ...dados,
    });
  return { id, compra, evento };
}

test("Apple: upgrade libera o web na hora", async () => {
  const { id, evento } = await assinanteApple(PRODUTO);
  await evento("DID_CHANGE_RENEWAL_PREF", { productId: BLACK, transacaoEmMs: emDias(0) });
  assert.equal((await lerAcademia(id)).acesso_web, true);
});

test("Apple: upgrade vale mesmo vencendo antes do plano anterior", async () => {
  const { id, evento } = await assinanteApple(PRODUTO, { expiresAtMs: emDias(300) });
  await evento("DID_CHANGE_RENEWAL_PREF", {
    productId: BLACK, transacaoEmMs: emDias(0), expiresAtMs: emDias(30),
  });
  assert.equal((await lerAcademia(id)).acesso_web, true);
});

test("Apple: downgrade agendado mantém o web até renovar no PRO", async () => {
  const { id, evento } = await assinanteApple(BLACK);
  await evento("DID_CHANGE_RENEWAL_PREF"); // ainda a transação do plano atual
  assert.equal((await lerAcademia(id)).acesso_web, true);
  await evento("DID_RENEW", { productId: PRODUTO, transacaoEmMs: emDias(0) });
  const d = await lerAcademia(id);
  assert.equal(d.acesso_web, false);
  assert.equal(d.plano_tipo, 1);
});

test("Apple: cancelamento e carência mantêm o web", async () => {
  const { id, evento } = await assinanteApple(BLACK);
  await evento("DID_CHANGE_RENEWAL_STATUS", { renovacaoAutomatica: false });
  assert.equal((await lerAcademia(id)).acesso_web, true);
  await evento("DID_FAIL_TO_RENEW");
  assert.equal((await lerAcademia(id)).acesso_web, true);
});

for (const tipo of ["EXPIRED", "GRACE_PERIOD_EXPIRED", "REFUND", "REVOKE"]) {
  test(`Apple: ${tipo} retira o plano e o web`, async () => {
    const { id, evento } = await assinanteApple(BLACK);
    await evento(tipo);
    const d = await lerAcademia(id);
    assert.equal(d.plano_tipo, 0);
    assert.equal(d.acesso_web, false);
  });
}

test("Apple: reembolso de transação anterior ao upgrade não derruba o plano atual", async () => {
  const { id, evento } = await assinanteApple(PRODUTO);
  await evento("DID_CHANGE_RENEWAL_PREF", { productId: BLACK, transacaoEmMs: emDias(0) });
  await evento("REFUND", { transacaoEmMs: emDias(-10) });
  assert.equal((await lerAcademia(id)).acesso_web, true);
});

test("Apple: restaurar a transação antiga não desfaz o upgrade", async () => {
  const { id, compra } = await assinanteApple(BLACK, { transacaoEmMs: emDias(0) });
  const r = await ativarCompra(id, compra, { productId: PRODUTO, transacaoEmMs: emDias(-10) });
  assert.equal(r.ignorada, "transacao_antiga");
  assert.equal((await lerAcademia(id)).plano_produto_id, BLACK);
});

// ── Outra assinatura na mesma academia ──────────────────────────────────────

test("outra assinatura PRO não derruba o Black Belt ativo", async () => {
  const id = await criarAcademia();
  await ativarCompra(id, "black-ativo", { productId: BLACK });
  const r = await ativarCompra(id, "pro-paralelo", { expiresAtMs: emDias(300) });
  assert.equal(r.ignorada, "plano_menor");
  assert.equal((await lerAcademia(id)).plano_original_transaction_id, "black-ativo");
});

test("com o Black Belt cancelado, a assinatura nova passa a valer", async () => {
  const id = await criarAcademia();
  await ativarCompra(id, "black-cancelado", { productId: BLACK, renovacaoAutomatica: false });
  await ativarCompra(id, "pro-novo");
  assert.equal((await lerAcademia(id)).plano_original_transaction_id, "pro-novo");
});

test("Black Belt substitui um PRO ativo, mesmo vencendo antes", async () => {
  const id = await criarAcademia();
  await ativarCompra(id, "pro-longo", { expiresAtMs: emDias(300) });
  await ativarCompra(id, "black-curto", { productId: BLACK });
  assert.equal((await lerAcademia(id)).acesso_web, true);
});

test("mesmo nível: fica a assinatura que vence depois", async () => {
  const id = await criarAcademia();
  await ativarCompra(id, "pro-anual", { expiresAtMs: emDias(300) });
  const r = await ativarCompra(id, "pro-curto");
  assert.equal(r.ignorada, "vence_antes");
});

// ── Google ──────────────────────────────────────────────────────────────────

const iso = (n) => new Date(emDias(n)).toISOString();
const item = (productId, expira, extra = { autoRenewingPlan: { autoRenewEnabled: true } }) => ({
  productId,
  ...(expira === null ? {} : { expiryTime: iso(expira) }),
  ...extra,
});
const compraGoogle = (lineItems, extra = {}) => ({
  subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
  lineItems,
  ...extra,
});
async function assinanteGoogle(productId) {
  const id = await criarAcademia();
  const token = `token-${id}`;
  await _internal.ativarCompraAndroid({
    academiaId: id,
    purchaseToken: token,
    compra: compraGoogle([item(productId, 30)]),
  });
  return { id, token };
}

test("Google: upgrade com token novo, ativado pelo app", async () => {
  const { id, token } = await assinanteGoogle(PRODUTO);
  await _internal.ativarCompraAndroid({
    academiaId: id,
    purchaseToken: `${token}-novo`,
    compra: compraGoogle([item(BLACK, 30)], { linkedPurchaseToken: token }),
  });
  const d = await lerAcademia(id);
  assert.equal(d.acesso_web, true);
  assert.equal(d.plano_original_transaction_id, `${token}-novo`);
});

test("Google: upgrade que chega só pela notificação migra para o token novo", async () => {
  const { id, token } = await assinanteGoogle(PRODUTO);
  await _internal.aplicarCompraGoogle(
    `${token}-novo`,
    compraGoogle([item(BLACK, 30)], { linkedPurchaseToken: token })
  );
  assert.equal((await lerAcademia(id)).acesso_web, true);

  // A expiração do token antigo chega depois e não afeta mais nada.
  await _internal.aplicarCompraGoogle(
    token,
    compraGoogle([item(PRODUTO, -1)], { subscriptionState: "SUBSCRIPTION_STATE_EXPIRED" })
  );
  assert.equal((await lerAcademia(id)).plano_tipo, 1);
});

test("Google: expiração do token antigo antes da notificação nova se recupera", async () => {
  const { id, token } = await assinanteGoogle(PRODUTO);
  await _internal.aplicarCompraGoogle(
    token,
    compraGoogle([item(PRODUTO, -1)], { subscriptionState: "SUBSCRIPTION_STATE_EXPIRED" })
  );
  await _internal.aplicarCompraGoogle(
    `${token}-novo`,
    compraGoogle([item(BLACK, 30)], { linkedPurchaseToken: token })
  );
  const d = await lerAcademia(id);
  assert.equal(d.plano_tipo, 1);
  assert.equal(d.acesso_web, true);
});

test("Google: troca pendente de pagamento não mexe na assinatura atual", async () => {
  const { id, token } = await assinanteGoogle(PRODUTO);
  await _internal.aplicarCompraGoogle(
    `${token}-pendente`,
    compraGoogle([item(BLACK, 30)], {
      linkedPurchaseToken: token,
      subscriptionState: "SUBSCRIPTION_STATE_PENDING",
    })
  );
  const d = await lerAcademia(id);
  assert.equal(d.plano_original_transaction_id, token);
  assert.equal(d.acesso_web, false);
});

test("Google: downgrade agendado mantém o web e, na renovação, passa ao PRO", async () => {
  const { id, token } = await assinanteGoogle(BLACK);
  const novo = `${token}-novo`;
  const agendada = compraGoogle(
    [
      item(PRODUTO, null),
      item(BLACK, 20, { deferredItemReplacement: { productId: PRODUTO } }),
    ],
    { linkedPurchaseToken: token }
  );
  await _internal.ativarCompraAndroid({ academiaId: id, purchaseToken: novo, compra: agendada });
  let d = await lerAcademia(id);
  assert.equal(d.acesso_web, true);
  assert.equal(d.plano_renovacao_automatica, true);

  await _internal.aplicarCompraGoogle(
    novo,
    compraGoogle([item(BLACK, -1, {}), item(PRODUTO, 30)], { linkedPurchaseToken: token })
  );
  d = await lerAcademia(id);
  assert.equal(d.plano_produto_id, PRODUTO);
  assert.equal(d.acesso_web, false);
  assert.equal(d.plano_tipo, 1);
});

test("Google: cancelamento e carência mantêm o web; expiração retira", async () => {
  const { id, token } = await assinanteGoogle(BLACK);
  for (const estado of ["SUBSCRIPTION_STATE_CANCELED", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"]) {
    await _internal.aplicarCompraGoogle(
      token, compraGoogle([item(BLACK, 5)], { subscriptionState: estado })
    );
    assert.equal((await lerAcademia(id)).acesso_web, true, estado);
  }
  await _internal.aplicarCompraGoogle(
    token, compraGoogle([item(BLACK, -1)], { subscriptionState: "SUBSCRIPTION_STATE_EXPIRED" })
  );
  assert.equal((await lerAcademia(id)).acesso_web, false);
});

test("Google: trocar a compra de outra academia é recusado", async () => {
  const { token } = await assinanteGoogle(PRODUTO);
  const intrusa = await criarAcademia();
  await assertHttpsError(
    _internal.ativarCompraAndroid({
      academiaId: intrusa,
      purchaseToken: `${token}-novo`,
      compra: compraGoogle([item(BLACK, 30)], { linkedPurchaseToken: token }),
    }),
    "already-exists"
  );
});

test("Google: compra pendente é recusada na ativação", async () => {
  await assertHttpsError(
    _internal.ativarCompraAndroid({
      academiaId: await criarAcademia(),
      purchaseToken: "token-pendente",
      compra: compraGoogle([item(BLACK, 30)], { subscriptionState: "SUBSCRIPTION_STATE_PENDING" }),
    }),
    "permission-denied"
  );
});

test("transferência para outra academia retira o web da anterior", async () => {
  const vencida = await criarAcademia({
    plano_tipo: 1, plano_origem: "loja", acesso_web: true,
    plano_expiracao: new Date(HA_1_DIA).toISOString(),
    plano_original_transaction_id: "black-vencido",
  });
  await ativarCompra(await criarAcademia(), "black-vencido", { productId: BLACK_ANUAL });
  assert.equal((await lerAcademia(vencida)).acesso_web, false);
});

for (const produto of [PRODUTO, BLACK]) {
  test(`Google: suspensão retira o acesso e o pagamento aprovado devolve (${produto})`, async () => {
    const { id, token } = await assinanteGoogle(produto);
    await _internal.aplicarCompraGoogle(
      token, compraGoogle([item(produto, -1)], { subscriptionState: "SUBSCRIPTION_STATE_ON_HOLD" })
    );
    let d = await lerAcademia(id);
    assert.equal(d.plano_tipo, 0);
    assert.equal(d.acesso_web, false);
    assert.equal(d.plano_status, "suspenso");

    await _internal.aplicarCompraGoogle(token, compraGoogle([item(produto, 30)]));
    d = await lerAcademia(id);
    assert.equal(d.plano_tipo, 1);
    assert.equal(d.acesso_web, produto === BLACK);
    assert.equal(d.plano_status, "ativo");
  });
}

for (const estado of ["SUBSCRIPTION_STATE_ON_HOLD", "SUBSCRIPTION_STATE_PAUSED"]) {
  test(`Google: o app não ativa compra em ${estado}`, async () => {
    await assertHttpsError(
      _internal.ativarCompraAndroid({
        academiaId: await criarAcademia(),
        purchaseToken: `token-${estado}`,
        compra: compraGoogle([item(BLACK, 30)], { subscriptionState: estado }),
      }),
      "permission-denied"
    );
  });
}
