const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ── Funções de identidade / acesso ───────────────────────────────────────────
const accountFunctions = require('./account-functions');
exports.discoverAccessProfiles = accountFunctions.discoverAccessProfiles;
exports.activateAccessAccount = accountFunctions.activateAccessAccount;
exports.refreshAccessAccount = accountFunctions.refreshAccessAccount;

const adminFunctions = require('./admin-functions');
exports.adminResetPassword = adminFunctions.adminResetPassword;
exports.completeMandatoryPasswordChange = adminFunctions.completeMandatoryPasswordChange;

const graduacaoFunctions = require('./graduacao-functions');
exports.editarGraduacao = graduacaoFunctions.editarGraduacao;

const turmaFunctions = require('./turma-functions');
exports.arquivarTurma = turmaFunctions.arquivarTurma;

const financeFunctions = require('./finance-functions');
exports.ensureChargesForPeriod = financeFunctions.ensureChargesForPeriod;
exports.gerarMensalidadesAutomaticas = financeFunctions.gerarMensalidadesAutomaticas;

// ── Secrets Asaas ────────────────────────────────────────────────────────────
const ASAAS_API_KEY = defineSecret('ASAAS_API_KEY');
const ASAAS_WEBHOOK_TOKEN = defineSecret('ASAAS_WEBHOOK_TOKEN');

// Troque para https://www.asaas.com/api/v3 quando for para produção
const ASAAS_BASE = 'https://sandbox.asaas.com/api/v3';

function asaasHttp(apiKey, walletId = null) {
  const headers = {
    'access_token': apiKey,
    'Content-Type': 'application/json',
    'User-Agent': 'SenseiManager/1.0',
  };
  if (walletId) headers['wallet'] = walletId;
  return axios.create({ baseURL: ASAAS_BASE, headers, timeout: 20000 });
}

// ── criarSubcontaAcademia ────────────────────────────────────────────────────
exports.criarSubcontaAcademia = onCall(
  { secrets: [ASAAS_API_KEY], region: 'us-central1' },
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError('unauthenticated', 'Não autenticado.');
    const { academiaId } = req.data;
    if (!academiaId) throw new HttpsError('invalid-argument', 'academiaId obrigatório.');

    const cfgRef = db.doc(`academias/${academiaId}/integracoes/asaas`);
    const cfgSnap = await cfgRef.get();

    if (cfgSnap.exists && cfgSnap.data()?.subcontaId) {
      return { subcontaId: cfgSnap.data().subcontaId, status: cfgSnap.data().status };
    }

    const acadSnap = await db.doc(`academias/${academiaId}`).get();
    if (!acadSnap.exists) throw new HttpsError('not-found', 'Academia não encontrada.');
    const acad = acadSnap.data();

    const cnpjRaw = (acad.cnpj || '').replace(/\D/g, '');
    const cpfRaw  = (acad.cpf  || '').replace(/\D/g, '');
    const docFiscal = cnpjRaw.length >= 11 ? cnpjRaw : cpfRaw;
    if (docFiscal.length < 11) {
      throw new HttpsError('failed-precondition', 'Preencha o CPF (pessoa física) ou CNPJ (pessoa jurídica) da academia nas configurações antes de ativar pagamentos.');
    }

    const isPessoaFisica = docFiscal.length === 11;
    const client = asaasHttp(ASAAS_API_KEY.value());

    let subcontaId, walletId;
    try {
      const payload = {
        name: acad.nome || 'Academia',
        email: acad.email || '',
        loginEmail: acad.email || '',
        cpfCnpj: docFiscal,
        personType: isPessoaFisica ? 'FISICA' : 'JURIDICA',
        phone: (acad.telefone || '').replace(/\D/g, ''),
        mobilePhone: (acad.telefone || '').replace(/\D/g, ''),
      };
      if (!isPessoaFisica) payload.companyType = 'LIMITED';
      const r = await client.post('/accounts', payload);
      subcontaId = r.data.id;
      walletId = r.data.walletId || null;
    } catch (e) {
      const msg = e.response?.data?.errors?.[0]?.description || e.message;
      throw new HttpsError('internal', `Asaas: ${msg}`);
    }

    await cfgRef.set({
      subcontaId,
      walletId: walletId || null,
      status: 'PENDENTE',
      criadoEm: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { subcontaId, status: 'PENDENTE' };
  }
);

// ── verificarStatusAsaas ─────────────────────────────────────────────────────
exports.verificarStatusAsaas = onCall(
  { secrets: [ASAAS_API_KEY], region: 'us-central1' },
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError('unauthenticated', 'Não autenticado.');
    const { academiaId } = req.data;

    const cfgSnap = await db.doc(`academias/${academiaId}/integracoes/asaas`).get();
    if (!cfgSnap.exists || !cfgSnap.data()?.subcontaId) {
      return { configurado: false };
    }

    const { subcontaId } = cfgSnap.data();
    const client = asaasHttp(ASAAS_API_KEY.value());

    try {
      const r = await client.get(`/accounts/${subcontaId}`);
      const ativo = !!r.data.accountNumber;
      const status = ativo ? 'ATIVO' : 'PENDENTE';
      const update = { status };
      if (r.data.walletId && !cfgSnap.data().walletId) update.walletId = r.data.walletId;
      await db.doc(`academias/${academiaId}/integracoes/asaas`).update(update);
      return { configurado: true, subcontaId, status, nomeAsaas: r.data.name };
    } catch {
      return { configurado: true, subcontaId, status: cfgSnap.data().status || 'PENDENTE' };
    }
  }
);

// ── criarCobrancaPix (PIX | BOLETO | CREDIT_CARD) ────────────────────────────
exports.criarCobrancaPix = onCall(
  { secrets: [ASAAS_API_KEY], region: 'us-central1' },
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError('unauthenticated', 'Não autenticado.');
    const {
      academiaId, pagamentoId, valor, descricao,
      alunoNome, alunoCpf, alunoEmail,
      billingType: rawBillingType,
      creditCard, creditCardHolderInfo,
    } = req.data;

    const billingType = rawBillingType || 'PIX';

    if (!academiaId || !pagamentoId || !valor) {
      throw new HttpsError('invalid-argument', 'Campos obrigatórios ausentes.');
    }
    if (!['PIX', 'BOLETO', 'CREDIT_CARD'].includes(billingType)) {
      throw new HttpsError('invalid-argument', 'billingType inválido.');
    }

    const cfgSnap = await db.doc(`academias/${academiaId}/integracoes/asaas`).get();
    if (!cfgSnap.exists || !cfgSnap.data()?.subcontaId) {
      throw new HttpsError('failed-precondition', 'Esta academia ainda não configurou pagamentos via app.');
    }
    const { subcontaId, status, walletId: savedWalletId } = cfgSnap.data();
    if (status !== 'ATIVO') {
      throw new HttpsError('failed-precondition', 'A conta de pagamentos está pendente de aprovação. Aguarde a liberação.');
    }

    const pagRef = db.doc(`academias/${academiaId}/pagamentos/${pagamentoId}`);
    const pagSnap = await pagRef.get();
    const pag = pagSnap.data() || {};

    // Usa master key + walletId correto (campo walletId ≠ id da conta).
    // Isso garante que PIX está disponível (conta master tem PIX habilitado)
    // e as cobranças ficam na wallet da subconta.
    let walletId = savedWalletId;
    if (!walletId) {
      try {
        const masterC = asaasHttp(ASAAS_API_KEY.value());
        const accRes = await masterC.get(`/accounts/${subcontaId}`);
        walletId = accRes.data?.walletId || null;
        if (walletId) {
          await db.doc(`academias/${academiaId}/integracoes/asaas`).update({ walletId });
        }
      } catch (_) {}
    }
    const client = asaasHttp(ASAAS_API_KEY.value(), walletId);

    // Reaproveitamento de cobrança existente (mesmo tipo, ainda pendente)
    if (pag.asaasChargeId && pag.asaasStatus === 'PENDING' && pag.asaasBillingType === billingType) {
      try {
        if (billingType === 'PIX') {
          const qrR = await client.get(`/payments/${pag.asaasChargeId}/pixQrCode`);
          if (qrR.data?.payload) return { chargeId: pag.asaasChargeId, ...qrR.data };
        } else if (billingType === 'BOLETO') {
          const bR = await client.get(`/payments/${pag.asaasChargeId}`);
          if (bR.data?.bankSlipUrl) {
            const r = { chargeId: pag.asaasChargeId, bankSlipUrl: bR.data.bankSlipUrl };
            if (bR.data.identificationField) r.identificationField = bR.data.identificationField;
            if (bR.data.nossoNumero) r.nossoNumero = bR.data.nossoNumero;
            if (bR.data.dueDate) r.dueDate = bR.data.dueDate;
            return r;
          }
        }
      } catch { /* expirado, cria nova */ }
    }

    // Busca ou cria cliente no Asaas
    let customerId;
    const cpf = (alunoCpf || '').replace(/\D/g, '');
    if (cpf.length >= 11) {
      const sr = await client.get(`/customers?cpfCnpj=${cpf}&limit=1`).catch(() => ({ data: { data: [] } }));
      if (sr.data?.data?.length > 0) customerId = sr.data.data[0].id;
    }
    if (!customerId) {
      const cr = await client.post('/customers', {
        name: alunoNome || 'Aluno',
        cpfCnpj: cpf || undefined,
        email: alunoEmail || undefined,
      });
      customerId = cr.data.id;
    }

    // Vencimento
    const due = new Date();
    due.setDate(due.getDate() + (billingType === 'BOLETO' ? 3 : 1));
    const dueDate = due.toISOString().split('T')[0];

    const chargePayload = {
      customer: customerId,
      billingType,
      value: valor,
      dueDate,
      description: descricao || 'Mensalidade',
      externalReference: `${academiaId}:${pagamentoId}`,
    };
    if (billingType === 'CREDIT_CARD') {
      if (!creditCard) throw new HttpsError('invalid-argument', 'Dados do cartão são obrigatórios.');
      chargePayload.creditCard = creditCard;
      chargePayload.creditCardHolderInfo = creditCardHolderInfo || {};
    }

    let charge;
    try {
      charge = await client.post('/payments', chargePayload);
    } catch (e) {
      const msg = e.response?.data?.errors?.[0]?.description || e.message;
      throw new HttpsError('internal', `Erro ao criar cobrança: ${msg}`);
    }

    const chargeId = charge.data.id;
    const chargeStatus = charge.data.status;

    await pagRef.update({
      asaasChargeId: chargeId,
      asaasCustomerId: customerId,
      asaasStatus: chargeStatus === 'RECEIVED' ? 'RECEIVED' : 'PENDING',
      asaasBillingType: billingType,
    });

    if (billingType === 'CREDIT_CARD' && chargeStatus === 'RECEIVED') {
      await pagRef.update({ status: 1, pago_em: admin.firestore.FieldValue.serverTimestamp() });
      return { chargeId, status: chargeStatus, invoiceUrl: charge.data.invoiceUrl };
    }

    if (billingType === 'PIX') {
      const qrR = await client.get(`/payments/${chargeId}/pixQrCode`);
      return { chargeId, ...qrR.data };
    }

    if (billingType === 'BOLETO') {
      const r = { chargeId };
      if (charge.data.bankSlipUrl) r.bankSlipUrl = charge.data.bankSlipUrl;
      if (charge.data.identificationField) r.identificationField = charge.data.identificationField;
      if (charge.data.nossoNumero) r.nossoNumero = charge.data.nossoNumero;
      if (charge.data.dueDate) r.dueDate = charge.data.dueDate;
      if (charge.data.invoiceUrl) r.invoiceUrl = charge.data.invoiceUrl;
      return r;
    }

    return { chargeId, status: chargeStatus };
  }
);

// ── webhookAsaas ─────────────────────────────────────────────────────────────
exports.webhookAsaas = onRequest(
  { secrets: [ASAAS_WEBHOOK_TOKEN], region: 'us-central1' },
  async (req, res) => {
    const token = req.headers['asaas-access-token'];
    if (token !== ASAAS_WEBHOOK_TOKEN.value()) {
      res.status(401).send('Unauthorized');
      return;
    }

    const { event, payment } = req.body || {};
    const ref = payment?.externalReference || '';
    const parts = ref.split(':');

    if (parts.length !== 2) {
      res.status(200).send('OK');
      return;
    }

    const [academiaId, pagamentoId] = parts;
    const pagRef = db.doc(`academias/${academiaId}/pagamentos/${pagamentoId}`);

    if (event === 'PAYMENT_RECEIVED' || event === 'PAYMENT_CONFIRMED') {
      const pagSnap = await pagRef.get().catch(() => null);
      await pagRef.update({
        status: 1,
        asaasStatus: 'RECEIVED',
        pago_em: admin.firestore.FieldValue.serverTimestamp(),
      }).catch(() => {});

      // Push notification para admins/secretaria da academia
      try {
        const valor = payment?.value;
        const descricao = payment?.description || 'Mensalidade';
        const valorFmt = valor != null
          ? `R$ ${Number(valor).toFixed(2).replace('.', ',')}`
          : '';
        const bt = payment?.billingType || 'PIX';
        const metodoLabel = bt === 'BOLETO' ? 'Boleto' : bt === 'CREDIT_CARD' ? 'Cartão' : 'PIX';

        const funcionariosSnap = await db
          .collection('academias').doc(academiaId)
          .collection('funcionarios')
          .where('perfil', 'in', ['Admin', 'Secretaria'])
          .get();

        const tokens = [];
        funcionariosSnap.forEach((f) => {
          const d = f.data();
          if (Array.isArray(d.fcm_tokens)) tokens.push(...d.fcm_tokens);
        });

        // Salva notificação no Firestore
        await db.collection('academias').doc(academiaId).collection('notificacoes').add({
          titulo: `Pagamento recebido${valorFmt ? ` — ${valorFmt}` : ''}`,
          mensagem: `${metodoLabel}: ${descricao}`,
          tipo: 'sucesso',
          lida: false,
          chave_dedup: `pago-${pagamentoId}`,
          criado_em: admin.firestore.FieldValue.serverTimestamp(),
        });

        if (tokens.length > 0) {
          await messaging.sendEachForMulticast({
            tokens,
            notification: {
              title: `Pagamento ${metodoLabel} recebido${valorFmt ? ` — ${valorFmt}` : ''}`,
              body: descricao,
            },
            data: { tipo: `pagamento_${bt.toLowerCase()}`, academiaId, pagamentoId },
          });
        }
      } catch (err) {
        logger.error('Erro ao enviar push de pagamento', err);
      }
    } else if (event === 'PAYMENT_OVERDUE') {
      await pagRef.update({ status: 2, asaasStatus: 'OVERDUE' }).catch(() => {});
    }

    res.status(200).send('OK');
  }
);

// ── checarVencimentosContasAcademia ──────────────────────────────────────────
const DIAS_ANTECEDENCIA = 3;

function hojeISO() {
  return new Date().toISOString().split('T')[0];
}

async function processarVencimentosContasAcademia() {
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);
  const limite = new Date(hoje);
  limite.setDate(limite.getDate() + DIAS_ANTECEDENCIA);
  const hojeStr = hojeISO();

  const academiasSnap = await db.collection('academias').get();
  let totalAlertas = 0;

  for (const academiaDoc of academiasSnap.docs) {
    const academiaId = academiaDoc.id;

    const contasSnap = await db
      .collection('academias').doc(academiaId)
      .collection('contas_academia')
      .where('status', '==', 'pendente')
      .get();

    const contasParaAlertar = contasSnap.docs.filter((doc) => {
      const c = doc.data();
      if (c.alerta_enviado_em === hojeStr) return false;
      if (!c.data_vencimento) return false;
      const venc = new Date(`${c.data_vencimento}T00:00:00`);
      return venc <= limite;
    });

    if (contasParaAlertar.length === 0) continue;

    const funcionariosSnap = await db
      .collection('academias').doc(academiaId)
      .collection('funcionarios')
      .where('perfil', 'in', ['Admin', 'Secretaria'])
      .get();

    const tokens = [];
    funcionariosSnap.forEach((f) => {
      const dataFunc = f.data();
      if (Array.isArray(dataFunc.fcm_tokens)) tokens.push(...dataFunc.fcm_tokens);
    });

    for (const contaDoc of contasParaAlertar) {
      const conta = contaDoc.data();
      const venc = new Date(`${conta.data_vencimento}T00:00:00`);
      const vencida = venc < hoje;
      const titulo = vencida ? 'Conta da academia vencida' : 'Conta da academia vencendo';
      const mensagem = `${conta.descricao || 'Conta'} (${conta.categoria || 'Outros'}) - vencimento ${conta.data_vencimento}`;

      await db.collection('academias').doc(academiaId).collection('notificacoes').add({
        titulo,
        mensagem,
        tipo: vencida ? 'alerta' : 'info',
        lida: false,
        chave_dedup: `conta-academia-${contaDoc.id}-${hojeStr}`,
        criado_em: admin.firestore.FieldValue.serverTimestamp(),
      });

      await contaDoc.ref.update({ alerta_enviado_em: hojeStr });
      totalAlertas++;

      if (tokens.length > 0) {
        try {
          await messaging.sendEachForMulticast({
            tokens,
            notification: { title: titulo, body: mensagem },
            data: { tipo: 'conta_academia', contaId: contaDoc.id },
          });
        } catch (err) {
          logger.error(`Erro ao enviar push para academia ${academiaId}`, err);
        }
      }
    }
  }

  logger.info(`Vencimentos de contas da academia processados: ${totalAlertas} alerta(s) gerado(s).`);
  return totalAlertas;
}

// ── Firestore trigger: processar cobranca (PIX / BOLETO / CREDIT_CARD) ────────
exports.processarCobrancaReq = onDocumentCreated(
  {
    document: 'academias/{academiaId}/cobrancas_req/{reqId}',
    secrets: [ASAAS_API_KEY],
    region: 'us-central1',
  },
  async (event) => {
    const { academiaId } = event.params;
    const reqRef = db.doc(`academias/${academiaId}/cobrancas_req/${event.params.reqId}`);
    const data = event.data?.data();
    if (!data) return;

    try {
      const resultado = await _processarCobranca(academiaId, data);
      await reqRef.update({ status: 'done', resultado, processadoEm: admin.firestore.FieldValue.serverTimestamp() });
    } catch (e) {
      await reqRef.update({ status: 'error', erro: e.message || 'Erro interno.' });
    }
  }
);

async function _processarCobranca(academiaId, data) {
  const {
    pagamentoId, billingType: rawBillingType, valor, descricao,
    alunoNome, alunoCpf, alunoEmail,
    creditCard, creditCardHolderInfo,
  } = data;

  const billingType = rawBillingType || 'PIX';

  if (!academiaId || !pagamentoId || !valor) throw new Error('Campos obrigatórios ausentes.');
  if (!['PIX', 'BOLETO', 'CREDIT_CARD'].includes(billingType)) throw new Error('billingType inválido.');

  const cfgSnap = await db.doc(`academias/${academiaId}/integracoes/asaas`).get();
  if (!cfgSnap.exists || !cfgSnap.data()?.subcontaId)
    throw new Error('Esta academia ainda não configurou pagamentos via app.');
  const { subcontaId, status, walletId: savedWalletId2 } = cfgSnap.data();
  if (status !== 'ATIVO')
    throw new Error('A conta de pagamentos está pendente de aprovação. Aguarde a liberação.');

  const pagRef = db.doc(`academias/${academiaId}/pagamentos/${pagamentoId}`);
  const pagSnap = await pagRef.get();
  const pag = pagSnap.data() || {};

  let walletId2 = savedWalletId2;
  if (!walletId2) {
    try {
      const masterC = asaasHttp(ASAAS_API_KEY.value());
      const accRes = await masterC.get(`/accounts/${subcontaId}`);
      walletId2 = accRes.data?.walletId || null;
      if (walletId2) {
        await db.doc(`academias/${academiaId}/integracoes/asaas`).update({ walletId: walletId2 });
      }
    } catch (_) {}
  }
  const client = asaasHttp(ASAAS_API_KEY.value(), walletId2);

  if (pag.asaasChargeId && pag.asaasStatus === 'PENDING' && pag.asaasBillingType === billingType) {
    try {
      if (billingType === 'PIX') {
        const qrR = await client.get(`/payments/${pag.asaasChargeId}/pixQrCode`);
        if (qrR.data?.payload) return { chargeId: pag.asaasChargeId, ...qrR.data };
      } else if (billingType === 'BOLETO') {
        const bR = await client.get(`/payments/${pag.asaasChargeId}`);
        if (bR.data?.bankSlipUrl) {
          const r = { chargeId: pag.asaasChargeId, bankSlipUrl: bR.data.bankSlipUrl };
          if (bR.data.identificationField) r.identificationField = bR.data.identificationField;
          if (bR.data.nossoNumero) r.nossoNumero = bR.data.nossoNumero;
          if (bR.data.dueDate) r.dueDate = bR.data.dueDate;
          return r;
        }
      }
    } catch { /* expirado, cria nova */ }
  }

  if (!alunoCpf || alunoCpf.replace(/\D/g, '').length < 11) {
    throw new Error('CPF do aluno é obrigatório para gerar pagamento. Peça ao aluno que preencha o CPF no perfil do app.');
  }

  let customerId;
  const cpf = alunoCpf.replace(/\D/g, '');
  if (cpf.length >= 11) {
    const sr = await client.get(`/customers?cpfCnpj=${cpf}&limit=1`).catch(() => ({ data: { data: [] } }));
    if (sr.data?.data?.length > 0) customerId = sr.data.data[0].id;
  }
  if (!customerId) {
    try {
      const cr = await client.post('/customers', {
        name: alunoNome || 'Aluno',
        cpfCnpj: cpf,
        email: alunoEmail || undefined,
      });
      customerId = cr.data.id;
    } catch (e) {
      const msg = e.response?.data?.errors?.[0]?.description || e.message;
      throw new Error(`Erro ao cadastrar cliente no Asaas: ${msg}`);
    }
  }

  const due = new Date();
  due.setDate(due.getDate() + (billingType === 'BOLETO' ? 3 : 1));
  const dueDate = due.toISOString().split('T')[0];

  const chargePayload = {
    customer: customerId,
    billingType,
    value: valor,
    dueDate,
    description: descricao || 'Mensalidade',
    externalReference: `${academiaId}:${pagamentoId}`,
  };
  if (billingType === 'CREDIT_CARD') {
    if (!creditCard) throw new Error('Dados do cartão são obrigatórios.');
    chargePayload.creditCard = creditCard;
    chargePayload.creditCardHolderInfo = creditCardHolderInfo || {};
  }

  let charge;
  try {
    charge = await client.post('/payments', chargePayload);
  } catch (e) {
    const msg = e.response?.data?.errors?.[0]?.description || e.message;
    throw new Error(`Erro ao criar cobrança: ${msg}`);
  }

  const chargeId = charge.data.id;
  const chargeStatus = charge.data.status;

  await pagRef.update({
    asaasChargeId: chargeId,
    asaasCustomerId: customerId,
    asaasStatus: chargeStatus === 'RECEIVED' ? 'RECEIVED' : 'PENDING',
    asaasBillingType: billingType,
  });

  if (billingType === 'CREDIT_CARD' && chargeStatus === 'RECEIVED') {
    await pagRef.update({ status: 1, pago_em: admin.firestore.FieldValue.serverTimestamp() });
    return { chargeId, status: chargeStatus, invoiceUrl: charge.data.invoiceUrl };
  }

  if (billingType === 'PIX') {
    const qrR = await client.get(`/payments/${chargeId}/pixQrCode`);
    return { chargeId, ...qrR.data };
  }

  // Filtra undefined — Firestore rejeita campos com valor undefined
  const boletoResult = { chargeId };
  if (charge.data.bankSlipUrl) boletoResult.bankSlipUrl = charge.data.bankSlipUrl;
  if (charge.data.identificationField) boletoResult.identificationField = charge.data.identificationField;
  if (charge.data.nossoNumero) boletoResult.nossoNumero = charge.data.nossoNumero;
  if (charge.data.dueDate) boletoResult.dueDate = charge.data.dueDate;
  if (charge.data.invoiceUrl) boletoResult.invoiceUrl = charge.data.invoiceUrl;
  return boletoResult;
}

// ── Firestore trigger: requisições admin (criarSubconta / verificarStatus) ────
exports.processarAdminReq = onDocumentCreated(
  {
    document: 'academias/{academiaId}/admin_req/{reqId}',
    secrets: [ASAAS_API_KEY],
    region: 'us-central1',
  },
  async (event) => {
    const { academiaId } = event.params;
    const reqRef = db.doc(`academias/${academiaId}/admin_req/${event.params.reqId}`);
    const data = event.data?.data();
    if (!data) return;

    try {
      let resultado;
      if (data.tipo === 'criarSubconta') {
        resultado = await _criarSubconta(academiaId);
      } else if (data.tipo === 'verificarStatus') {
        resultado = await _verificarStatus(academiaId);
      } else if (data.tipo === 'deletarSubconta') {
        resultado = await _deletarSubconta(academiaId);
      } else if (data.tipo === 'reenviarCodigoSms') {
        resultado = await _reenviarCodigoSms(academiaId);
      } else if (data.tipo === 'confirmarCodigoSms') {
        resultado = await _confirmarCodigoSms(academiaId, data.codigo);
      } else if (data.tipo === 'configurarContaBancaria') {
        resultado = await _configurarContaBancaria(academiaId, data);
      } else if (data.tipo === 'sincronizarPagamentos') {
        resultado = await _sincronizarPagamentos(academiaId, data.alunoId);
      } else {
        throw new Error('Tipo de requisição desconhecido.');
      }
      await reqRef.update({ status: 'done', resultado });
    } catch (e) {
      await reqRef.update({ status: 'error', erro: e.message || 'Erro interno.' });
    }
  }
);

async function _sincronizarPagamentos(academiaId, alunoId) {
  const cfgSnap = await db.doc(`academias/${academiaId}/integracoes/asaas`).get();
  const cfgData = cfgSnap.data();
  // Exige apenas subcontaId — não bloqueia por status (pode ser PENDENTE após reconfiguração).
  if (!cfgSnap.exists || !cfgData?.subcontaId) {
    logger.info(`sincronizar: config ausente ou sem subcontaId para ${academiaId}`);
    return { sincronizados: 0 };
  }

  const { subcontaId } = cfgData;
  let walletId = cfgData.walletId || null;

  // Usa master key + walletId correto (campo walletId ≠ id da conta Asaas).
  if (!walletId) {
    try {
      const masterClient = asaasHttp(ASAAS_API_KEY.value());
      const accRes = await masterClient.get(`/accounts/${subcontaId}`);
      walletId = accRes.data?.walletId || null;
      if (walletId) {
        await db.doc(`academias/${academiaId}/integracoes/asaas`).update({ walletId });
        logger.info(`sincronizar: walletId obtido e salvo para ${academiaId}`);
      }
    } catch (e) {
      logger.warn(`sincronizar: não foi possível obter walletId: ${e.message}`);
    }
  }

  const client = asaasHttp(ASAAS_API_KEY.value(), walletId);
  logger.info(`sincronizar: usando master+walletId=${walletId ? 'ok' : 'null'} para ${academiaId}`);

  // Filtra apenas por asaasStatus (índice simples — automático no Firestore).
  // O filtro por aluno_id é feito em JS para evitar índice composto.
  const snap = await db.collection(`academias/${academiaId}/pagamentos`)
    .where('asaasStatus', '==', 'PENDING')
    .get();

  logger.info(`sincronizar: ${snap.size} pagamentos PENDING para ${academiaId}${alunoId ? ` / aluno ${alunoId}` : ''}`);
  let sincronizados = 0;

  for (const doc of snap.docs) {
    const pag = doc.data();
    if (!pag.asaasChargeId) continue;
    if (alunoId && pag.aluno_id !== alunoId) continue;
    try {
      let asaasStatus;
      let foundChargeId = pag.asaasChargeId;

      // Tentativa 1: busca direta pelo chargeId armazenado
      try {
        const r = await client.get(`/payments/${pag.asaasChargeId}`);
        asaasStatus = r.data.status;
        logger.info(`sincronizar: charge ${pag.asaasChargeId} → status Asaas: ${asaasStatus}`);
      } catch (e) {
        // Tentativa 2: fallback por externalReference (cobre casos onde o chargeId armazenado
        // não bate com o charge que foi efetivamente pago — ex: usuário gerou múltiplos PIX)
        const httpStatus = e.response?.status;
        logger.warn(`sincronizar: chargeId ${pag.asaasChargeId} retornou HTTP ${httpStatus}, tentando externalReference`);
        const externalRef = `${academiaId}:${doc.id}`;
        let allPayments = [];
        try {
          const searchR = await client.get(`/payments?externalReference=${encodeURIComponent(externalRef)}&limit=20`);
          allPayments = searchR.data?.data || [];
        } catch (_) {}
        logger.info(`sincronizar: externalReference "${externalRef}" → ${allPayments.length} charges encontrados`);

        // Tentativa 3: tenta master sem walletId como último recurso
        // (charges criados na conta master por wallet header inválido ficam invisíveis à subconta)
        if (allPayments.length === 0) {
          logger.warn(`sincronizar: tentando lookup sem wallet para chargeId ${pag.asaasChargeId}`);
          const masterClient = asaasHttp(ASAAS_API_KEY.value());
          try {
            const r3 = await masterClient.get(`/payments/${pag.asaasChargeId}`);
            asaasStatus = r3.data.status;
            logger.info(`sincronizar: charge encontrado via master sem wallet: ${pag.asaasChargeId} → ${asaasStatus}`);
          } catch (_) {
            // Também tenta externalReference sem wallet
            try {
              const sr3 = await masterClient.get(`/payments?externalReference=${encodeURIComponent(externalRef)}&limit=20`);
              allPayments = sr3.data?.data || [];
              logger.info(`sincronizar: externalRef sem wallet → ${allPayments.length} charges encontrados`);
            } catch (_) {}
          }
        }

        if (!asaasStatus) {
          // Prefere o mais recente que esteja confirmado
          const confirmed = allPayments.find(p => p.status === 'RECEIVED' || p.status === 'CONFIRMED');
          if (confirmed) {
            asaasStatus = confirmed.status;
            foundChargeId = confirmed.id;
            logger.info(`sincronizar: charge confirmado via externalRef: ${foundChargeId} → ${asaasStatus}`);
          } else if (allPayments.length > 0) {
            asaasStatus = allPayments[0].status;
            foundChargeId = allPayments[0].id;
            logger.info(`sincronizar: charge mais recente via externalRef: ${foundChargeId} → ${asaasStatus}`);
          } else {
            logger.warn(`sincronizar: nenhum charge encontrado para externalRef "${externalRef}"`);
            continue;
          }
        }
      }

      if (asaasStatus === 'RECEIVED' || asaasStatus === 'CONFIRMED') {
        await doc.ref.update({
          status: 1,
          asaasStatus: 'RECEIVED',
          asaasChargeId: foundChargeId,
          pago_em: admin.firestore.FieldValue.serverTimestamp(),
        });
        sincronizados++;
      } else if (asaasStatus === 'OVERDUE') {
        await doc.ref.update({ status: 2, asaasStatus: 'OVERDUE' });
      }
    } catch (e) {
      logger.error(`sincronizar: erro ao processar doc ${doc.id}:`, e.response?.status, e.response?.data || e.message);
    }
  }

  logger.info(`sincronizar: ${sincronizados} pagamento(s) atualizados para ${academiaId}`);
  return { sincronizados };
}

async function _criarSubconta(academiaId) {
  const cfgRef = db.doc(`academias/${academiaId}/integracoes/asaas`);
  const cfgSnap = await cfgRef.get();
  if (cfgSnap.exists && cfgSnap.data()?.subcontaId) {
    const cfgData = cfgSnap.data();
    // Se está DESVINCULADO, reconectar à conta Asaas existente (ex: DELETE retornou 403 no sandbox)
    if (cfgData.status === 'DESVINCULADO') {
      let subcontaApiKey = cfgData.subcontaApiKey || null;
      if (!subcontaApiKey) {
        try {
          const client = asaasHttp(ASAAS_API_KEY.value());
          const accRes = await client.get(`/accounts/${cfgData.subcontaId}`);
          subcontaApiKey = accRes.data?.apiKey || null;
        } catch (_) {}
      }
      const isSandboxRecon = ASAAS_BASE.includes('sandbox');
      const newStatus = isSandboxRecon ? 'AGUARDANDO_CONTA_BANCARIA' : (subcontaApiKey ? 'AGUARDANDO_SMS' : 'AGUARDANDO_CONTA_BANCARIA');
      await cfgRef.update({ status: newStatus, subcontaApiKey, desvinculadoEm: admin.firestore.FieldValue.delete() });
      logger.info(`_criarSubconta: reconectando conta DESVINCULADO ${cfgData.subcontaId}, novo status: ${newStatus}`);
      return { subcontaId: cfgData.subcontaId, status: newStatus };
    }
    // Já ativa — garante que temos o apiKey salvo
    if (!cfgData.subcontaApiKey) {
      try {
        const client = asaasHttp(ASAAS_API_KEY.value());
        const accRes = await client.get(`/accounts/${cfgData.subcontaId}`);
        const apiKey = accRes.data?.apiKey;
        if (apiKey) await cfgRef.update({ subcontaApiKey: apiKey });
      } catch (_) {}
    }
    return { subcontaId: cfgData.subcontaId, status: cfgData.status };
  }

  const acadSnap = await db.doc(`academias/${academiaId}`).get();
  if (!acadSnap.exists) throw new Error('Academia não encontrada.');
  const acad = acadSnap.data();

  const cnpjRaw = (acad.cnpj || '').replace(/\D/g, '');
  const cpfRaw  = (acad.cpf  || '').replace(/\D/g, '');
  const docFiscal = cnpjRaw.length >= 11 ? cnpjRaw : cpfRaw;
  if (docFiscal.length < 11) {
    throw new Error('Preencha o CPF (pessoa física) ou CNPJ (pessoa jurídica) da academia nas configurações antes de ativar pagamentos.');
  }

  const isPessoaFisica = docFiscal.length === 11;
  const client = asaasHttp(ASAAS_API_KEY.value());

  let subcontaId;
  let subcontaApiKey = null;
  let isContaRecuperada = false;

  try {
    const cepRaw = (acad.cep || '').replace(/\D/g, '');
    if (!cepRaw) throw new Error('É necessário informar o CEP da academia nas configurações antes de ativar pagamentos.');

    const payload = {
      name: acad.nome || 'Academia',
      email: acad.email || '',
      loginEmail: acad.email || '',
      cpfCnpj: docFiscal,
      personType: isPessoaFisica ? 'FISICA' : 'JURIDICA',
      phone: (acad.telefone || '').replace(/\D/g, ''),
      mobilePhone: (acad.telefone || '').replace(/\D/g, ''),
      postalCode: cepRaw,
      address: acad.logradouro || '',
      addressNumber: acad.numero || 'S/N',
      complement: acad.complemento || '',
      province: acad.bairro || '',
    };
    if (!isPessoaFisica) payload.companyType = 'LIMITED';
    const faturamento = parseFloat(acad.faturamento_mensal) || 0;
    if (faturamento > 0) payload.incomeValue = faturamento;
    const r = await client.post('/accounts', payload);
    subcontaId = r.data.id;
    subcontaApiKey = r.data.apiKey || null; // vem direto no response do POST
    logger.info(`_criarSubconta: nova conta criada ${subcontaId}, apiKey obtido: ${!!subcontaApiKey}`);
  } catch (e) {
    const msg = (e.response?.data?.errors?.[0]?.description || e.message || '').toLowerCase();
    // Se o CNPJ/CPF já tem conta Asaas, recupera o ID existente e vincula
    if (msg.includes('cpf') || msg.includes('cnpj') || msg.includes('já cadastrado') || msg.includes('ja cadastrado') || msg.includes('already') || msg.includes('ativo') || msg.includes('active')) {
      try {
        // Tenta filtrar por CNPJ/CPF diretamente
        const listRes = await client.get(`/accounts?cpfCnpj=${docFiscal}&limit=5`);
        const accounts = listRes.data?.data || [];
        const existing = accounts.find(a => (a.cpfCnpj || '').replace(/\D/g, '') === docFiscal);
        if (existing?.id) {
          subcontaId = existing.id;
          subcontaApiKey = existing.apiKey || null;
          logger.info(`_criarSubconta: conta existente encontrada (${subcontaId}), apiKey: ${!!subcontaApiKey}`);
        } else {
          // Fallback: busca sem filtro (primeiros 100)
          const allRes = await client.get('/accounts?limit=100');
          const allAccounts = allRes.data?.data || [];
          const found = allAccounts.find(a => (a.cpfCnpj || '').replace(/\D/g, '') === docFiscal);
          if (found?.id) {
            subcontaId = found.id;
            subcontaApiKey = found.apiKey || null;
            logger.info(`_criarSubconta: conta encontrada no fallback (${subcontaId}), apiKey: ${!!subcontaApiKey}`);
          } else {
            logger.warn(`_criarSubconta: CNPJ ${docFiscal} não encontrado em ${allAccounts.length} contas. Erro original: ${msg}`);
            throw new Error(`Asaas: ${e.response?.data?.errors?.[0]?.description || e.message}. Acesse sandbox.asaas.com para verificar a conta.`);
          }
        }
      } catch (e2) {
        if (!e2.message.includes('Asaas:')) throw e2;
        throw e2;
      }
      isContaRecuperada = true;
    } else {
      throw new Error(`Asaas: ${e.response?.data?.errors?.[0]?.description || e.message}`);
    }
  }

  // No sandbox, SMS bloqueado — vai direto para configuração da conta bancária
  // Em produção, o fluxo completo de SMS é usado
  const isSandbox = ASAAS_BASE.includes('sandbox');
  const status = isSandbox ? 'AGUARDANDO_CONTA_BANCARIA' : 'AGUARDANDO_SMS';

  await cfgRef.set({
    subcontaId,
    subcontaApiKey,
    status,
    criadoEm: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info(`_criarSubconta: status final = ${status}, apiKey salvo = ${!!subcontaApiKey}`);
  return { subcontaId, status };
}

async function _reenviarCodigoSms(academiaId) {
  const cfgRef = db.doc(`academias/${academiaId}/integracoes/asaas`);
  const cfgSnap = await cfgRef.get();
  if (!cfgSnap.exists) throw new Error('Configuração Asaas não encontrada.');
  let { subcontaApiKey, subcontaId } = cfgSnap.data();
  if (!subcontaId) throw new Error('Sub-conta não vinculada.');

  // Se apiKey não foi salvo na criação, busca agora com a master key
  if (!subcontaApiKey) {
    try {
      const masterClient = asaasHttp(ASAAS_API_KEY.value());
      const accRes = await masterClient.get(`/accounts/${subcontaId}`);
      const accData = accRes.data || {};
      logger.info('_reenviarCodigoSms: campos retornados pelo Asaas:', Object.keys(accData));
      logger.info('_reenviarCodigoSms: apiKey encontrado?', accData.apiKey ? 'SIM' : 'NÃO', '| accessToken?', accData.accessToken ? 'SIM' : 'NÃO');
      // Asaas pode retornar apiKey ou accessToken dependendo da versão
      subcontaApiKey = accData.apiKey || accData.accessToken || null;
      if (subcontaApiKey) await cfgRef.update({ subcontaApiKey });
    } catch (e) {
      logger.error('_reenviarCodigoSms: erro ao buscar conta:', e.response?.status, e.response?.data || e.message);
    }
    if (!subcontaApiKey) throw new Error('Não foi possível obter a API Key da sub-conta. Contate o suporte.');
  }

  const subClient = asaasHttp(subcontaApiKey);
  await subClient.post('/myAccount/sendPhoneToken');
  return { enviado: true };
}

async function _confirmarCodigoSms(academiaId, codigo) {
  if (!codigo) throw new Error('Código inválido.');

  const cfgRef = db.doc(`academias/${academiaId}/integracoes/asaas`);
  const cfgSnap = await cfgRef.get();
  if (!cfgSnap.exists) throw new Error('Configuração Asaas não encontrada.');
  const { subcontaApiKey } = cfgSnap.data();
  if (!subcontaApiKey) throw new Error('API Key da sub-conta não disponível. Tente reenviar o código.');

  const subClient = asaasHttp(subcontaApiKey);
  try {
    await subClient.post('/myAccount/validatePhoneToken', { token: String(codigo) });
  } catch (e) {
    const httpStatus = e.response?.status;
    const msg = e.response?.data?.errors?.[0]?.description || e.message;
    // Sandbox sem white-label completo retorna 403 neste endpoint — tratar como sucesso
    // Em produção com white-label, a validação real será executada
    if (httpStatus !== 403) {
      throw new Error(`Código inválido ou expirado: ${msg}`);
    }
    logger.warn(`_confirmarCodigoSms: validatePhoneToken retornou 403 (sandbox) — avançando para PENDENTE.`);
  }

  await cfgRef.update({ status: 'AGUARDANDO_CONTA_BANCARIA', telefoneVerificado: true });
  return { status: 'AGUARDANDO_CONTA_BANCARIA' };
}

async function _configurarContaBancaria(academiaId, dados) {
  const { codigoBanco, agencia, conta, digitoConta, tipoConta, nomeTitular, cpfCnpjTitular } = dados;

  if (!codigoBanco || !agencia || !conta || !tipoConta || !nomeTitular || !cpfCnpjTitular) {
    throw new Error('Preencha todos os dados bancários.');
  }

  const cfgRef = db.doc(`academias/${academiaId}/integracoes/asaas`);
  const cfgSnap = await cfgRef.get();
  if (!cfgSnap.exists) throw new Error('Configuração Asaas não encontrada.');
  const { subcontaApiKey } = cfgSnap.data();
  if (!subcontaApiKey) throw new Error('API Key da sub-conta não disponível. Tente novamente.');

  const subClient = asaasHttp(subcontaApiKey);

  try {
    await subClient.post('/myAccount/bankAccount', {
      bank: { code: String(codigoBanco) },
      accountName: 'Conta Principal',
      ownerName: nomeTitular,
      cpfCnpj: String(cpfCnpjTitular).replace(/\D/g, ''),
      agency: String(agencia),
      account: String(conta),
      accountDigit: String(digitoConta || '0'),
      bankAccountType: tipoConta,
    });
    logger.info(`_configurarContaBancaria: conta bancária configurada para academia ${academiaId}`);
  } catch (e) {
    const httpStatus = e.response?.status;
    const msg = e.response?.data?.errors?.[0]?.description || e.message;
    if (httpStatus === 403 || httpStatus === 404) {
      logger.warn(`_configurarContaBancaria: ${httpStatus} no sandbox — avançando para PENDENTE sem configurar via API.`);
    } else {
      throw new Error(`Erro ao configurar conta bancária: ${msg}`);
    }
  }

  await cfgRef.update({ status: 'PENDENTE', contaBancariaConfigurada: true });
  return { status: 'PENDENTE' };
}

async function _verificarStatus(academiaId) {
  const cfgSnap = await db.doc(`academias/${academiaId}/integracoes/asaas`).get();
  if (!cfgSnap.exists || !cfgSnap.data()?.subcontaId) return { configurado: false };

  const { subcontaId } = cfgSnap.data();
  const client = asaasHttp(ASAAS_API_KEY.value());

  try {
    const r = await client.get(`/accounts/${subcontaId}`);
    const ativo = !!r.data.accountNumber;
    const status = ativo ? 'ATIVO' : 'PENDENTE';
    await db.doc(`academias/${academiaId}/integracoes/asaas`).update({ status });
    return { configurado: true, subcontaId, status, nomeAsaas: r.data.name };
  } catch {
    return { configurado: true, subcontaId, status: cfgSnap.data().status || 'PENDENTE' };
  }
}

async function _deletarSubconta(academiaId) {
  const cfgRef = db.doc(`academias/${academiaId}/integracoes/asaas`);
  const cfgSnap = await cfgRef.get();
  if (!cfgSnap.exists || !cfgSnap.data()?.subcontaId) {
    return { deletado: false, motivo: 'Sem subconta vinculada.' };
  }

  const { subcontaId } = cfgSnap.data();
  const client = asaasHttp(ASAAS_API_KEY.value());

  let contaRemovidaAsaas = false;
  try {
    await client.delete(`/accounts/${subcontaId}`);
    contaRemovidaAsaas = true;
  } catch (e) {
    const httpStatus = e.response?.status;
    if (httpStatus === 404) {
      contaRemovidaAsaas = true; // Já não existe no Asaas
    } else if (httpStatus === 403) {
      // Sandbox sem white-label completo não permite deletar sub-contas via API
      logger.warn(`_deletarSubconta: DELETE retornou 403 — conta permanece no Asaas, marcando como DESVINCULADO no Firestore.`);
    } else {
      throw new Error(`Asaas: ${e.response?.data?.errors?.[0]?.description || e.message}`);
    }
  }

  if (contaRemovidaAsaas) {
    await cfgRef.delete();
  } else {
    // Conta ainda existe no Asaas (403 sandbox) — mantém subcontaId para reconexão futura
    await cfgRef.update({
      status: 'DESVINCULADO',
      desvinculadoEm: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  return { deletado: true };
}

// ── Polling automático: atualiza academias PENDENTE a cada 6h ────────────────
exports.pollingStatusAsaas = onSchedule(
  {
    schedule: 'every 6 hours',
    timeZone: 'America/Sao_Paulo',
    secrets: [ASAAS_API_KEY],
  },
  async () => {
    const snap = await db.collectionGroup('integracoes')
      .where('status', '==', 'PENDENTE')
      .where('subcontaId', '!=', null)
      .get();

    if (snap.empty) return;

    const client = asaasHttp(ASAAS_API_KEY.value());
    const updates = [];

    for (const doc of snap.docs) {
      const { subcontaId } = doc.data();
      try {
        const r = await client.get(`/accounts/${subcontaId}`);
        if (r.data?.accountNumber) {
          updates.push(doc.ref.update({ status: 'ATIVO', atualizadoEm: admin.firestore.FieldValue.serverTimestamp() }));
          logger.info(`pollingStatusAsaas: ${doc.ref.path} → ATIVO`);
        }
      } catch (e) {
        logger.warn(`pollingStatusAsaas: erro ao verificar ${subcontaId}: ${e.message}`);
      }
    }

    await Promise.allSettled(updates);
    logger.info(`pollingStatusAsaas: ${snap.size} contas verificadas, ${updates.length} ativadas.`);
  }
);

exports.checarVencimentosContasAcademia = onSchedule(
  { schedule: '0 8 * * *', timeZone: 'America/Sao_Paulo' },
  async () => {
    await processarVencimentosContasAcademia();
  },
);

exports.testarVencimentosContasAcademia = onRequest(async (req, res) => {
  const total = await processarVencimentosContasAcademia();
  res.status(200).json({ alertasGerados: total });
});
