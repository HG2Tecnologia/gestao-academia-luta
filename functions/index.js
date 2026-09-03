const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
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

    const cnpj = (acad.cnpj || '').replace(/\D/g, '');
    if (!cnpj) throw new HttpsError('failed-precondition', 'Preencha o CNPJ da academia nas configurações antes de ativar pagamentos.');

    const client = asaasHttp(ASAAS_API_KEY.value());

    let subcontaId;
    try {
      const r = await client.post('/accounts', {
        name: acad.nome || 'Academia',
        email: acad.email || '',
        loginEmail: acad.email || '',
        cpfCnpj: cnpj,
        personType: 'JURIDICA',
        companyType: 'LIMITED',
        phone: (acad.telefone || '').replace(/\D/g, ''),
        mobilePhone: (acad.telefone || '').replace(/\D/g, ''),
      });
      subcontaId = r.data.id;
    } catch (e) {
      const msg = e.response?.data?.errors?.[0]?.description || e.message;
      throw new HttpsError('internal', `Asaas: ${msg}`);
    }

    await cfgRef.set({
      subcontaId,
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
      await db.doc(`academias/${academiaId}/integracoes/asaas`).update({ status });
      return { configurado: true, subcontaId, status, nomeAsaas: r.data.name };
    } catch {
      return { configurado: true, subcontaId, status: cfgSnap.data().status || 'PENDENTE' };
    }
  }
);

// ── criarCobrancaPix ─────────────────────────────────────────────────────────
exports.criarCobrancaPix = onCall(
  { secrets: [ASAAS_API_KEY], region: 'us-central1' },
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError('unauthenticated', 'Não autenticado.');
    const { academiaId, pagamentoId, valor, descricao, alunoNome, alunoCpf, alunoEmail } = req.data;

    if (!academiaId || !pagamentoId || !valor) {
      throw new HttpsError('invalid-argument', 'Campos obrigatórios ausentes.');
    }

    const cfgSnap = await db.doc(`academias/${academiaId}/integracoes/asaas`).get();
    if (!cfgSnap.exists || !cfgSnap.data()?.subcontaId) {
      throw new HttpsError('failed-precondition', 'Esta academia ainda não configurou pagamentos via app.');
    }

    const { subcontaId, status } = cfgSnap.data();
    if (status !== 'ATIVO') {
      throw new HttpsError('failed-precondition', 'A conta de pagamentos está pendente de aprovação. Aguarde a liberação.');
    }

    const pagRef = db.doc(`academias/${academiaId}/pagamentos/${pagamentoId}`);
    const pagSnap = await pagRef.get();
    const pag = pagSnap.data() || {};

    const client = asaasHttp(ASAAS_API_KEY.value(), subcontaId);

    if (pag.asaasChargeId && pag.asaasStatus === 'PENDING') {
      try {
        const qrR = await client.get(`/payments/${pag.asaasChargeId}/pixQrCode`);
        if (qrR.data?.payload) {
          return { chargeId: pag.asaasChargeId, ...qrR.data };
        }
      } catch { /* QR expirado, cria nova cobrança */ }
    }

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

    const due = new Date();
    due.setDate(due.getDate() + 1);
    const dueDate = due.toISOString().split('T')[0];
    const extRef = `${academiaId}:${pagamentoId}`;

    let charge;
    try {
      charge = await client.post('/payments', {
        customer: customerId,
        billingType: 'PIX',
        value: valor,
        dueDate,
        description: descricao || 'Mensalidade',
        externalReference: extRef,
      });
    } catch (e) {
      const msg = e.response?.data?.errors?.[0]?.description || e.message;
      throw new HttpsError('internal', `Erro ao criar cobrança: ${msg}`);
    }

    const chargeId = charge.data.id;
    const qrR = await client.get(`/payments/${chargeId}/pixQrCode`);

    await pagRef.update({
      asaasChargeId: chargeId,
      asaasCustomerId: customerId,
      asaasStatus: 'PENDING',
    });

    return { chargeId, ...qrR.data };
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
      await pagRef.update({
        status: 1,
        asaasStatus: 'RECEIVED',
        pago_em: admin.firestore.FieldValue.serverTimestamp(),
      }).catch(() => {});
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
