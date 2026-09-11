"use strict";

/**
 * Testes unitários do fluxo de pagamento Asaas — ponta a ponta (sem emulador).
 *
 * Cenários cobertos:
 *  Webhook:
 *    1. PIX confirmado → PAYMENT_RECEIVED → status=1 no Firestore
 *    2. Boleto confirmado → PAYMENT_CONFIRMED → status=1 no Firestore
 *   2b. Cartão de crédito → PAYMENT_CONFIRMED → status=1 + push tipo=pagamento_credit_card
 *    3. Pagamento vencido → PAYMENT_OVERDUE → status=2 no Firestore
 *    4. Boleto atrasado que depois é pago → status=1 (overrides OVERDUE)
 *    5. externalReference inválido → ignorado, Firestore não muda
 *    6. Retry do Asaas → notificação não é duplicada (idempotente)
 *    7. Webhook confirma o asaasChargeId correto no Firestore
 *    8. Admin com FCM token recebe push na confirmação do PIX
 *
 *  Sync (_sincronizarPagamentos / sincronizarPagamentosGlobal):
 *    9.  Pagamento PENDING → Asaas diz RECEIVED → atualiza Firestore
 *   10.  Pagamento OVERDUE quitado → cron pega (bug crítico corrigido)
 *   11.  ChargeId não encontrado → fallback por externalReference → resolve
 *   12.  Nenhum charge encontrado → ignora sem lançar erro
 *   13.  Academia sem integração → retorna { sincronizados: 0 } sem erro
 */

const assert = require("node:assert/strict");
const test = require("node:test");
const { processWebhookEvent, sincronizarPagamentosAcademia } = require("../asaas-payment-logic");

// ─── Mock Firestore em memória ────────────────────────────────────────────────

const TIMESTAMP_SENTINEL = { _sentinel: "serverTimestamp" };

// Injeta um FieldValue.serverTimestamp() stub antes de require() do módulo
// (firebase-admin não está disponível no contexto de testes unitários).
const admin = require("firebase-admin");
// Sobrescreve apenas o FieldValue para os testes
Object.defineProperty(admin, "firestore", {
  get: () => ({
    FieldValue: {
      serverTimestamp: () => TIMESTAMP_SENTINEL,
      delete: () => ({ _sentinel: "deleteField" }),
    },
  }),
  configurable: true,
});

class MockDocRef {
  constructor(store, path) {
    this._store = store;
    this._path = path;
  }
  collection(name) {
    return new MockCollRef(this._store, `${this._path}/${name}`);
  }
  async get() {
    const data = this._store._store[this._path];
    return { exists: data !== undefined, data: () => data, ref: this };
  }
  async update(delta) {
    const existing = this._store._store[this._path] || {};
    this._store._store[this._path] = { ...existing, ...delta };
  }
  async set(data, opts = {}) {
    if (opts.merge) {
      const existing = this._store._store[this._path] || {};
      this._store._store[this._path] = { ...existing, ...data };
    } else {
      this._store._store[this._path] = { ...data };
    }
  }
}

class MockQuery {
  constructor(store, collPath, field, op, value) {
    this._store = store;
    this._collPath = collPath;
    this._field = field;
    this._op = op;
    this._value = value;
  }
  where(f, op, v) {
    // Encadeia um segundo filtro (usado em testes futuros se necessário)
    return new MockQuery(this._store, this._collPath, f, op, v);
  }
  async get() {
    const prefix = this._collPath + "/";
    const docs = Object.entries(this._store._store)
      .filter(([k, v]) => {
        if (!k.startsWith(prefix)) return false;
        const rest = k.slice(prefix.length);
        if (rest.includes("/")) return false; // sub-coleção, não documento direto
        if (this._field && this._op === "==" && v[this._field] !== this._value) return false;
        if (this._field && this._op === "in" && !this._value.includes(v[this._field])) return false;
        return true;
      })
      .map(([k, v]) => ({
        id: k.split("/").pop(),
        ref: new MockDocRef(this._store, k),
        data: () => v,
      }));
    const forEach = (fn) => docs.forEach(fn);
    return { docs, forEach };
  }
}

class MockCollRef {
  constructor(store, path) {
    this._store = store;
    this._path = path;
  }
  doc(id) {
    return new MockDocRef(this._store, `${this._path}/${id}`);
  }
  where(field, op, value) {
    return new MockQuery(this._store, this._path, field, op, value);
  }
}

class MockDB {
  constructor(initialData = {}) {
    this._store = { ...initialData };
  }
  doc(path) {
    return new MockDocRef(this, path);
  }
  collection(path) {
    return new MockCollRef(this, path);
  }
  /** Lê o dado bruto para asserts nos testes */
  _read(path) {
    return this._store[path];
  }
}

// ─── Mock Messaging ───────────────────────────────────────────────────────────

function makeMockMessaging() {
  const calls = [];
  return {
    sendEachForMulticast: async (msg) => { calls.push(msg); return { responses: [] }; },
    _calls: calls,
  };
}

// ─── Helpers de fixture ───────────────────────────────────────────────────────

function paymentDoc({ status = 0, asaasStatus = "PENDING", chargeId = "pay_abc123", alunoId = "aluno-1" } = {}) {
  return { status, asaasStatus, asaasChargeId: chargeId, aluno_id: alunoId, valor: 250 };
}

function webhookBody({ event, billingType = "PIX", chargeId = "pay_abc123", ref = "academia-1:pag-1", value = 250, description = "Mensalidade Setembro" } = {}) {
  return {
    event,
    payment: { id: chargeId, externalReference: ref, billingType, value, description },
  };
}

// ─── Cenário 1: PIX confirmado via PAYMENT_RECEIVED ──────────────────────────

test("1 · PIX pago → PAYMENT_RECEIVED → status=1 e asaasStatus=RECEIVED no Firestore", async () => {
  const db = new MockDB({
    "academias/academia-1/pagamentos/pag-1": paymentDoc(),
    "academias/academia-1/funcionarios/admin-1": { perfil: "Admin", fcm_tokens: [] },
  });

  const { action } = await processWebhookEvent(
    webhookBody({ event: "PAYMENT_RECEIVED" }),
    db,
    makeMockMessaging(),
  );

  assert.equal(action, "paid");
  const pag = db._read("academias/academia-1/pagamentos/pag-1");
  assert.equal(pag.status, 1);
  assert.equal(pag.asaasStatus, "RECEIVED");
  assert.equal(pag.asaasChargeId, "pay_abc123");
  assert.ok(pag.pago_em, "pago_em deve ser preenchido");
});

// ─── Cenário 2: Boleto confirmado via PAYMENT_CONFIRMED ──────────────────────

test("2 · Boleto pago → PAYMENT_CONFIRMED → status=1", async () => {
  const db = new MockDB({
    "academias/academia-1/pagamentos/pag-2": paymentDoc({ chargeId: "pay_boleto" }),
    "academias/academia-1/funcionarios/admin-1": { perfil: "Admin", fcm_tokens: [] },
  });

  await processWebhookEvent(
    webhookBody({ event: "PAYMENT_CONFIRMED", billingType: "BOLETO", chargeId: "pay_boleto", ref: "academia-1:pag-2" }),
    db,
    makeMockMessaging(),
  );

  const pag = db._read("academias/academia-1/pagamentos/pag-2");
  assert.equal(pag.status, 1);
  assert.equal(pag.asaasStatus, "RECEIVED");
});

// ─── Cenário 2b: Cartão de crédito confirmado via PAYMENT_CONFIRMED ─────────

test("2b · Cartão de crédito pago → PAYMENT_CONFIRMED → status=1 e push com tipo=pagamento_credit_card", async () => {
  const messaging = makeMockMessaging();
  const db = new MockDB({
    "academias/academia-1/pagamentos/pag-2b": paymentDoc({ chargeId: "pay_card" }),
    "academias/academia-1/funcionarios/admin-1": { perfil: "Admin", fcm_tokens: ["tok-admin"] },
  });

  await processWebhookEvent(
    webhookBody({ event: "PAYMENT_CONFIRMED", billingType: "CREDIT_CARD", chargeId: "pay_card", ref: "academia-1:pag-2b" }),
    db,
    messaging,
  );

  const pag = db._read("academias/academia-1/pagamentos/pag-2b");
  assert.equal(pag.status, 1);
  assert.equal(pag.asaasStatus, "RECEIVED");
  assert.equal(pag.asaasChargeId, "pay_card");

  assert.equal(messaging._calls.length, 1, "deve enviar push para o admin");
  assert.equal(messaging._calls[0].data.tipo, "pagamento_credit_card");

  const notif = db._read("academias/academia-1/notificacoes/pago-pag-2b");
  assert.ok(notif, "notificação deve existir");
  assert.match(notif.mensagem, /Cartão/);
});

// ─── Cenário 3: Pagamento venceu → PAYMENT_OVERDUE → status=2 ────────────────

test("3 · Vencimento → PAYMENT_OVERDUE → status=2 e asaasStatus=OVERDUE", async () => {
  const db = new MockDB({
    "academias/academia-1/pagamentos/pag-3": paymentDoc(),
  });

  const { action } = await processWebhookEvent(
    { event: "PAYMENT_OVERDUE", payment: { externalReference: "academia-1:pag-3" } },
    db,
    makeMockMessaging(),
  );

  assert.equal(action, "overdue");
  const pag = db._read("academias/academia-1/pagamentos/pag-3");
  assert.equal(pag.status, 2);
  assert.equal(pag.asaasStatus, "OVERDUE");
});

// ─── Cenário 4: Boleto marcado OVERDUE e depois pago ─────────────────────────

test("4 · Boleto atrasado que depois é pago → status=1 (OVERDUE → RECEIVED)", async () => {
  const db = new MockDB({
    "academias/academia-1/pagamentos/pag-4": paymentDoc({ status: 2, asaasStatus: "OVERDUE" }),
    "academias/academia-1/funcionarios/admin-1": { perfil: "Admin", fcm_tokens: [] },
  });

  // Primeiro o vencimento (já está no Firestore como OVERDUE)
  // Agora o aluno paga:
  await processWebhookEvent(
    webhookBody({ event: "PAYMENT_RECEIVED", ref: "academia-1:pag-4" }),
    db,
    makeMockMessaging(),
  );

  const pag = db._read("academias/academia-1/pagamentos/pag-4");
  assert.equal(pag.status, 1, "deve sobrescrever OVERDUE para Pago");
  assert.equal(pag.asaasStatus, "RECEIVED");
});

// ─── Cenário 5: externalReference inválido → ignorado ────────────────────────

test("5 · externalReference sem ':' → webhook ignorado, Firestore não alterado", async () => {
  const db = new MockDB({
    "academias/academia-1/pagamentos/pag-5": paymentDoc(),
  });

  const { action } = await processWebhookEvent(
    { event: "PAYMENT_RECEIVED", payment: { externalReference: "referencia-sem-separador" } },
    db,
    makeMockMessaging(),
  );

  assert.equal(action, "ignored");
  const pag = db._read("academias/academia-1/pagamentos/pag-5");
  assert.equal(pag.status, 0, "Firestore não deve ter sido alterado");
});

// ─── Cenário 6: Retry do Asaas → notificação idempotente ────────────────────

test("6 · Retry do Asaas (mesmo evento 2x) → apenas 1 documento de notificação", async () => {
  const db = new MockDB({
    "academias/academia-1/pagamentos/pag-6": paymentDoc(),
    "academias/academia-1/funcionarios/admin-1": { perfil: "Admin", fcm_tokens: [] },
  });

  const evt = webhookBody({ event: "PAYMENT_RECEIVED", ref: "academia-1:pag-6", chargeId: "pay_retry" });

  await processWebhookEvent(evt, db, makeMockMessaging());
  await processWebhookEvent(evt, db, makeMockMessaging()); // segunda chamada (retry)

  // O ID do documento é determinístico: "pago-pag-6"
  // set() com merge:true não duplica — apenas existe 1 documento
  const notif = db._read("academias/academia-1/notificacoes/pago-pag-6");
  assert.ok(notif, "notificação deve existir");
  assert.equal(notif.chave_dedup, "pago-pag-6");
  // Confirma que NÃO existe outro documento com sufixo diferente (add() criaria um novo)
  const keys = Object.keys(db._store).filter((k) =>
    k.startsWith("academias/academia-1/notificacoes/") && k !== "academias/academia-1/notificacoes/pago-pag-6",
  );
  assert.equal(keys.length, 0, "não deve ter criado notificação duplicada");
});

// ─── Cenário 7: asaasChargeId correto é gravado no webhook ───────────────────

test("7 · Webhook grava o asaasChargeId recebido no evento (campo id do payment)", async () => {
  const db = new MockDB({
    "academias/academia-1/pagamentos/pag-7": paymentDoc({ chargeId: "pay_old_id" }),
    "academias/academia-1/funcionarios/admin-1": { perfil: "Admin", fcm_tokens: [] },
  });

  await processWebhookEvent(
    webhookBody({ event: "PAYMENT_RECEIVED", ref: "academia-1:pag-7", chargeId: "pay_new_id_from_asaas" }),
    db,
    makeMockMessaging(),
  );

  const pag = db._read("academias/academia-1/pagamentos/pag-7");
  assert.equal(pag.asaasChargeId, "pay_new_id_from_asaas", "deve gravar o chargeId do evento");
});

// ─── Cenário 8: Push notification enviado para Admin com FCM token ────────────

test("8 · Admin com FCM token recebe push na confirmação do pagamento PIX", async () => {
  const db = new MockDB({
    "academias/academia-1/pagamentos/pag-8": paymentDoc(),
    "academias/academia-1/funcionarios/admin-1": { perfil: "Admin", fcm_tokens: ["fcm-token-abc"] },
    "academias/academia-1/funcionarios/prof-1": { perfil: "Professor", fcm_tokens: ["fcm-token-xyz"] },
  });
  const msg = makeMockMessaging();

  await processWebhookEvent(
    webhookBody({ event: "PAYMENT_RECEIVED", ref: "academia-1:pag-8", value: 250, description: "Mensalidade Setembro" }),
    db,
    msg,
  );

  assert.equal(msg._calls.length, 1, "deve ter enviado 1 multicast");
  assert.deepEqual(msg._calls[0].tokens, ["fcm-token-abc"]);
  assert.ok(msg._calls[0].notification.title.includes("PIX"), "título deve mencionar PIX");
  assert.ok(msg._calls[0].notification.title.includes("250"), "título deve incluir o valor");
});

// ─── Cenário 9: Sync — pagamento PENDING que Asaas diz RECEIVED ──────────────

test("9 · Sync: pagamento PENDING → Asaas retorna RECEIVED → atualiza Firestore", async () => {
  const db = new MockDB({
    "academias/acad-sync/integracoes/asaas": { subcontaId: "sub-123", walletId: "wallet-abc" },
    "academias/acad-sync/pagamentos/pag-pending": paymentDoc({ asaasStatus: "PENDING", chargeId: "pay_sync1" }),
  });

  const makeClient = () => ({
    get: async (url) => {
      if (url === "/payments/pay_sync1") return { data: { status: "RECEIVED", id: "pay_sync1" } };
      throw new Error("not found");
    },
  });

  const result = await sincronizarPagamentosAcademia("acad-sync", null, db, makeClient);

  assert.equal(result.sincronizados, 1);
  const pag = db._read("academias/acad-sync/pagamentos/pag-pending");
  assert.equal(pag.status, 1);
  assert.equal(pag.asaasStatus, "RECEIVED");
});

// ─── Cenário 10: Sync — boleto OVERDUE quitado (bug crítico corrigido) ────────

test("10 · Sync: boleto OVERDUE que foi pago → cron atualiza para status=1", async () => {
  const db = new MockDB({
    "academias/acad-sync2/integracoes/asaas": { subcontaId: "sub-456", walletId: "wallet-def" },
    "academias/acad-sync2/pagamentos/pag-overdue": paymentDoc({
      status: 2,
      asaasStatus: "OVERDUE",
      chargeId: "pay_overdue1",
    }),
  });

  const makeClient = () => ({
    get: async (url) => {
      if (url === "/payments/pay_overdue1") return { data: { status: "RECEIVED", id: "pay_overdue1" } };
      throw new Error("not found");
    },
  });

  const result = await sincronizarPagamentosAcademia("acad-sync2", null, db, makeClient);

  assert.equal(result.sincronizados, 1, "deve ter sincronizado o boleto atrasado que foi pago");
  const pag = db._read("academias/acad-sync2/pagamentos/pag-overdue");
  assert.equal(pag.status, 1);
  assert.equal(pag.asaasStatus, "RECEIVED");
});

// ─── Cenário 11: Sync — fallback por externalReference ───────────────────────

test("11 · Sync: chargeId não encontrado → fallback externalReference → resolve", async () => {
  const db = new MockDB({
    "academias/acad-fb/integracoes/asaas": { subcontaId: "sub-789", walletId: "wallet-ghi" },
    "academias/acad-fb/pagamentos/pag-fb": paymentDoc({
      asaasStatus: "PENDING",
      chargeId: "pay_old_id",
      alunoId: "aluno-2",
    }),
  });

  const makeClient = (walletId) => ({
    get: async (url) => {
      if (url.startsWith("/payments/pay_old_id")) {
        // Simula 404 — chargeId desconhecido
        const err = new Error("not found");
        err.response = { status: 404 };
        throw err;
      }
      if (url.includes("externalReference=acad-fb%3Apag-fb")) {
        return { data: { data: [{ id: "pay_new_correct", status: "RECEIVED" }] } };
      }
      throw new Error("unexpected url: " + url);
    },
  });

  const result = await sincronizarPagamentosAcademia("acad-fb", null, db, makeClient);

  assert.equal(result.sincronizados, 1, "deve ter resolvido via fallback externalReference");
  const pag = db._read("academias/acad-fb/pagamentos/pag-fb");
  assert.equal(pag.status, 1);
  assert.equal(pag.asaasChargeId, "pay_new_correct", "deve atualizar chargeId para o charge correto");
});

// ─── Cenário 12: Sync — nenhum charge encontrado → ignora sem erro ────────────

test("12 · Sync: charge não encontrado em nenhuma tentativa → ignora silenciosamente", async () => {
  const db = new MockDB({
    "academias/acad-nf/integracoes/asaas": { subcontaId: "sub-000", walletId: "wallet-000" },
    "academias/acad-nf/pagamentos/pag-ghost": paymentDoc({ asaasStatus: "PENDING", chargeId: "pay_ghost" }),
  });

  const makeClient = () => ({
    get: async (url) => {
      const err = new Error("not found");
      err.response = { status: 404 };
      throw err;
    },
  });

  // Não deve lançar erro
  const result = await sincronizarPagamentosAcademia("acad-nf", null, db, makeClient);

  assert.equal(result.sincronizados, 0, "não deve sincronizar nenhum");
  const pag = db._read("academias/acad-nf/pagamentos/pag-ghost");
  assert.equal(pag.status, 0, "Firestore não deve ter sido alterado");
});

// ─── Cenário 13: Academia sem integração → retorna 0 sem erro ─────────────────

test("13 · Sync: academia sem integração Asaas → retorna { sincronizados: 0 }", async () => {
  const db = new MockDB({}); // sem nenhum doc de integração

  const makeClient = () => ({ get: async () => { throw new Error("nunca deve ser chamado"); } });

  const result = await sincronizarPagamentosAcademia("acad-sem-asaas", null, db, makeClient);

  assert.equal(result.sincronizados, 0);
});
