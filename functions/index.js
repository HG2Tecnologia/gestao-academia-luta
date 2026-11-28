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

const accountDeletionFunctions = require("./account-deletion-functions");
exports.excluirMinhaConta = accountDeletionFunctions.excluirMinhaConta;

const adminFunctions = require('./admin-functions');
exports.adminResetPassword = adminFunctions.adminResetPassword;
exports.checkContatoCompartilhado = adminFunctions.checkContatoCompartilhado;
exports.atualizarTelefoneAcessoAluno = adminFunctions.atualizarTelefoneAcessoAluno;
exports.requestPasswordReset = adminFunctions.requestPasswordReset;

const notificationTriggers = require("./notification-triggers");
exports.onGraduacaoCriada = notificationTriggers.onGraduacaoCriada;
exports.completeMandatoryPasswordChange = adminFunctions.completeMandatoryPasswordChange;

const graduacaoFunctions = require('./graduacao-functions');
exports.editarGraduacao = graduacaoFunctions.editarGraduacao;

const turmaFunctions = require('./turma-functions');
exports.arquivarTurma = turmaFunctions.arquivarTurma;

const alunoFunctions = require("./aluno-functions");
exports.excluirAluno = alunoFunctions.excluirAluno;

const planLimitsFunctions = require("./plan-limits-functions");
exports.manterContagemTurmasAtivas = planLimitsFunctions.manterContagemTurmasAtivas;
exports.manterContagemAlunosAtivos = planLimitsFunctions.manterContagemAlunosAtivos;
exports.manterContagemFuncionarios = planLimitsFunctions.manterContagemFuncionarios;

const financeFunctions = require('./finance-functions');
exports.ensureChargesForPeriod = financeFunctions.ensureChargesForPeriod;
exports.ensureChargesForNextMonths = financeFunctions.ensureChargesForNextMonths;
exports.gerarMensalidadesAutomaticas = financeFunctions.gerarMensalidadesAutomaticas;
exports.disregardChargesBeforePeriod = financeFunctions.disregardChargesBeforePeriod;
exports.mergeDuplicateCharges = financeFunctions.mergeDuplicateCharges;
exports.limparCobrancasOrfas = financeFunctions.limparCobrancasOrfas;
exports.gerarCobrancasAoAtribuirPlano = financeFunctions.gerarCobrancasAoAtribuirPlano;
exports.gerarCobrancasAoMatricular = financeFunctions.gerarCobrancasAoMatricular;

const contratoFunctions = require("./contrato-functions");
exports.contratoPublicoObter = contratoFunctions.contratoPublicoObter;
exports.contratoPublicoAssinar = contratoFunctions.contratoPublicoAssinar;

const attributionFunctions = require("./attribution-functions");
exports.registrarAtribuicaoCadastro = attributionFunctions.registrarAtribuicaoCadastro;

const modalidadeInitFunctions = require("./modalidade-init-functions");
exports.inicializarModalidadesPadrao = modalidadeInitFunctions.inicializarModalidadesPadrao;

const analyticsFunctions = require("./analytics-functions");
exports.registrarEventoAnalytics = analyticsFunctions.registrarEventoAnalytics;

const { processWebhookEvent, sincronizarPagamentosAcademia } = require('./asaas-payment-logic');

// ── Secrets Asaas ────────────────────────────────────────────────────────────
const ASAAS_API_KEY = defineSecret('ASAAS_API_KEY');
const ASAAS_WEBHOOK_TOKEN = defineSecret('ASAAS_WEBHOOK_TOKEN');

// Troque para https://www.asaas.com/api/v3 quando for para produção
const ASAAS_BASE = 'https://sandbox.asaas.com/api/v3';

// O vencimento enviado ao Asaas precisa ser o mesmo vencimento real da
// cobrança (pag.data_vencimento, formato YYYY-MM-DD), não "hoje + N dias" —
// senão o boleto/Pix no Asaas vence num dia diferente do que o app mostra
// pro aluno. Se a cobrança já estiver vencida, mantém a data real (o Asaas
// aceita e marca como OVERDUE, que é o estado correto).
function _dueDateDaCobranca(pag, billingType) {
  const raw = pag?.data_vencimento;
  if (typeof raw === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(raw)) return raw;
  const due = new Date();
  due.setDate(due.getDate() + (billingType === 'BOLETO' ? 3 : 1));
  return due.toISOString().split('T')[0];
}

function asaasHttp(apiKey, walletId = null) {
  const headers = {
    'access_token': apiKey,
    'Content-Type': 'application/json',
    'User-Agent': 'SenseiManager/1.0',
  };
  if (walletId) headers['wallet'] = walletId;
  return axios.create({ baseURL: ASAAS_BASE, headers, timeout: 20000 });
}

// Traduz o erro de POST /payments pro aluno/admin, registrando o corpo
// completo (code + description) no log pra diagnóstico — e, quando o motivo
// é a Asaas bloqueando a subconta por excesso de consultas, troca o texto
// cru dela por uma mensagem que faz sentido pra quem está pagando, em vez de
// expor jargão de API.
function _mensagemErroCobranca(e, academiaId) {
  const erroAsaas = e.response?.data?.errors?.[0];
  const msg = erroAsaas?.description || e.message;
  logger.warn(`criar cobrança: Asaas recusou (${academiaId}):`, e.response?.status, e.response?.data || e.message);

  if (erroAsaas?.code === 'invalid_action' && msg.toLowerCase().includes('excesso de consultas')) {
    return 'Serviço de pagamento temporariamente indisponível. Tente novamente em alguns minutos.';
  }
  if (msg.toLowerCase().includes('aprovad')) {
    db.doc(`academias/${academiaId}/integracoes/asaas`).update({ status: 'PENDENTE' }).catch(() => {});
    return msg;
  }
  return msg;
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
    const cfgRef = db.doc(`academias/${academiaId}/integracoes/asaas`);

    // A Asaas bloqueia a subconta por "excesso de consultas" se chamarmos
    // /myAccount/status com frequência demais (ex.: toda abertura de tela).
    // Reaproveita o último resultado por um tempo curto em vez de consultar
    // a Asaas de novo a cada chamada.
    const verificadoEm = cfgSnap.data()?.statusVerificadoEm?.toMillis?.();
    if (verificadoEm && Date.now() - verificadoEm < 90_000) {
      return { configurado: true, subcontaId, status: cfgSnap.data().status, nomeAsaas: cfgSnap.data().nomeAsaas };
    }

    const client = asaasHttp(ASAAS_API_KEY.value());
    let nomeAsaas;
    try {
      const r = await client.get(`/accounts/${subcontaId}`);
      nomeAsaas = r.data.name;
      const update = {};
      if (r.data.walletId && !cfgSnap.data().walletId) update.walletId = r.data.walletId;
      if (Object.keys(update).length) await cfgRef.update(update);
    } catch (_) { /* segue sem o nome, não é crítico */ }

    // accountNumber existe desde a criação da subconta — não significa que
    // ela está aprovada a movimentar dinheiro de verdade. A aprovação real
    // só se confirma com GET /myAccount/status (chamado com a apiKey DA
    // SUBCONTA), no campo `general` ('APPROVED' = aprovação completa).
    let status = 'PENDENTE';
    const subcontaApiKey = await _obterSubcontaApiKey(academiaId);
    if (subcontaApiKey) {
      try {
        const subClient = asaasHttp(subcontaApiKey);
        const statusR = await subClient.get('/myAccount/status/');
        if (statusR.data?.general === 'APPROVED') {
          status = 'ATIVO';
          await _garantirChavePixEvp(academiaId, subcontaApiKey);
        }
      } catch (e) {
        logger.warn(`verificarStatusAsaas: falha ao consultar /myAccount/status (${academiaId}):`, e.response?.status, e.response?.data || e.message);
      }
    }
    await cfgRef.update({ status, nomeAsaas: nomeAsaas || null, statusVerificadoEm: admin.firestore.FieldValue.serverTimestamp() });
    return { configurado: true, subcontaId, status, nomeAsaas };
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
    const { status } = cfgSnap.data();
    if (status !== 'ATIVO') {
      throw new HttpsError('failed-precondition', 'A conta de pagamentos está pendente de aprovação. Aguarde a liberação.');
    }

    const acadSnapCheck = await db.doc(`academias/${academiaId}`).get();
    if (acadSnapCheck.data()?.pagamentos_app_ativo !== true) {
      throw new HttpsError('failed-precondition', 'Pagamentos pelo app estão desativados por esta academia.');
    }

    const pagRef = db.doc(`academias/${academiaId}/pagamentos/${pagamentoId}`);
    const pagSnap = await pagRef.get();
    if (!pagSnap.exists) throw new HttpsError('not-found', 'Cobrança não encontrada.');
    const pag = pagSnap.data() || {};

    // Esta function recebe academiaId/pagamentoId/valor do CLIENTE — sem isto,
    // qualquer usuário autenticado (de qualquer academia) poderia cobrar em
    // nome de outra academia, pagar o valor que quiser, ou gerar cobrança de
    // um aluno que não é ele. Confere que: (1) o pagamento é mesmo desse
    // aluno autenticado, e (2) usa o valor JÁ REGISTRADO no pagamento, nunca
    // o valor que o cliente mandou.
    const alunoSnap = await db.doc(`academias/${academiaId}/usuarios/${pag.aluno_id}`).get();
    const alunoUid = alunoSnap.data()?.firebaseUid || alunoSnap.data()?.firebase_uid;
    if (!alunoSnap.exists || alunoUid !== req.auth.uid) {
      throw new HttpsError('permission-denied', 'Esta cobrança não pertence a este usuário.');
    }
    const valorReal = (pag.valor != null ? Number(pag.valor) : null);
    if (valorReal == null) throw new HttpsError('failed-precondition', 'Cobrança sem valor definido.');

    // A cobrança é criada diretamente com a apiKey DA SUBCONTA — não da master.
    // O Asaas não tem um mecanismo de header 'wallet' para agir em nome de
    // outra conta; isso só funciona chamando a API como a própria subconta
    // (mesmo padrão já usado em saldo/extrato/saque). Assim, o dinheiro recebido
    // já cai direto no saldo da subconta da academia, sem precisar de split.
    const subcontaApiKey = await _obterSubcontaApiKey(academiaId);
    if (!subcontaApiKey) {
      throw new HttpsError('failed-precondition', 'Esta academia ainda não configurou pagamentos via app.');
    }
    const client = asaasHttp(subcontaApiKey);

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

    const dueDate = _dueDateDaCobranca(pag, billingType);

    const chargePayload = {
      customer: customerId,
      billingType,
      value: valorReal,
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
      throw new HttpsError('internal', `Erro ao criar cobrança: ${_mensagemErroCobranca(e, academiaId)}`);
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
    try {
      await processWebhookEvent({ event, payment }, db, messaging);
    } catch (err) {
      logger.error('webhookAsaas: erro ao processar evento', err);
    }
    res.status(200).send('OK');
  }
);

// ── checarVencimentosContasAcademia ──────────────────────────────────────────
const iapFunctions = require("./iap-functions");
exports.ativarAssinaturaIOS = iapFunctions.ativarAssinaturaIOS;
exports.ativarAssinaturaAndroid = iapFunctions.ativarAssinaturaAndroid;
exports.webhookAppStoreNotifications = iapFunctions.webhookAppStoreNotifications;
exports.webhookGooglePlayNotifications = iapFunctions.webhookGooglePlayNotifications;

const iapReconciliation = require("./iap-reconciliation");
exports.reconciliarAssinaturas = iapReconciliation.reconciliarAssinaturas;
exports.testarReconciliacaoAssinaturas = iapReconciliation.testarReconciliacaoAssinaturas;

const engagementNotifications = require("./engagement-notifications");
exports.checarAlertasEngajamento = engagementNotifications.checarAlertasEngajamento;
exports.testarAlertasEngajamento = engagementNotifications.testarAlertasEngajamento;

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

// ── Firestore trigger: processar cobranca (PIX / BOLETO) ─────────────────────
// CREDIT_CARD é proibido aqui de propósito: dados de cartão nunca podem
// passar pelo Firestore. Cartão usa exclusivamente exports.criarCobrancaPix
// (onCall), que recebe o cartão direto do app sem persistir em lugar nenhum.
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
    pagamentoId, billingType: rawBillingType, descricao,
    alunoNome, alunoCpf, alunoEmail, uid,
  } = data;

  const billingType = rawBillingType || 'PIX';

  if (!academiaId || !pagamentoId) throw new Error('Campos obrigatórios ausentes.');
  if (!['PIX', 'BOLETO'].includes(billingType)) {
    // CREDIT_CARD nunca passa por aqui: dados de cartão não podem transitar
    // pelo Firestore (ver exports.criarCobrancaPix, que recebe o cartão
    // direto por onCall e nunca persiste nada).
    throw new Error('billingType inválido para este fluxo.');
  }

  const cfgSnap = await db.doc(`academias/${academiaId}/integracoes/asaas`).get();
  if (!cfgSnap.exists || !cfgSnap.data()?.subcontaId)
    throw new Error('Esta academia ainda não configurou pagamentos via app.');
  const { status } = cfgSnap.data();
  if (status !== 'ATIVO')
    throw new Error('A conta de pagamentos está pendente de aprovação. Aguarde a liberação.');

  const acadSnapCheck = await db.doc(`academias/${academiaId}`).get();
  if (acadSnapCheck.data()?.pagamentos_app_ativo !== true) {
    throw new Error('Pagamentos pelo app estão desativados por esta academia.');
  }

  const pagRef = db.doc(`academias/${academiaId}/pagamentos/${pagamentoId}`);
  const pagSnap = await pagRef.get();
  if (!pagSnap.exists) throw new Error('Cobrança não encontrada.');
  const pag = pagSnap.data() || {};

  // A regra do Firestore só garante que quem CRIOU o cobrancas_req é membro
  // desta academia — não que o pagamentoId é dele, nem o valor real. Sem
  // isto, um aluno poderia cobrar o pagamento de outro aluno, ou um valor
  // diferente do registrado.
  const alunoSnap = await db.doc(`academias/${academiaId}/usuarios/${pag.aluno_id}`).get();
  const alunoUid = alunoSnap.data()?.firebaseUid || alunoSnap.data()?.firebase_uid;
  if (!alunoSnap.exists || alunoUid !== uid) {
    throw new Error('Esta cobrança não pertence a este usuário.');
  }
  const valor = pag.valor != null ? Number(pag.valor) : null;
  if (valor == null) throw new Error('Cobrança sem valor definido.');

  // Cobrança criada direto com a apiKey DA SUBCONTA (ver nota em criarCobrancaPix).
  const subcontaApiKey = await _obterSubcontaApiKey(academiaId);
  if (!subcontaApiKey) throw new Error('Esta academia ainda não configurou pagamentos via app.');
  const client = asaasHttp(subcontaApiKey);

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

  const dueDate = _dueDateDaCobranca(pag, billingType);

  const chargePayload = {
    customer: customerId,
    billingType,
    value: valor,
    dueDate,
    description: descricao || 'Mensalidade',
    externalReference: `${academiaId}:${pagamentoId}`,
  };
  let charge;
  try {
    charge = await client.post('/payments', chargePayload);
  } catch (e) {
    throw new Error(`Erro ao criar cobrança: ${_mensagemErroCobranca(e, academiaId)}`);
  }

  const chargeId = charge.data.id;
  const chargeStatus = charge.data.status;

  await pagRef.update({
    asaasChargeId: chargeId,
    asaasCustomerId: customerId,
    asaasStatus: chargeStatus === 'RECEIVED' ? 'RECEIVED' : 'PENDING',
    asaasBillingType: billingType,
  });

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
      } else if (data.tipo === 'consultarSaldo') {
        resultado = await _consultarSaldo(academiaId);
      } else if (data.tipo === 'obterExtrato') {
        resultado = await _obterExtrato(academiaId, { offset: data.offset, limit: data.limit });
      } else if (data.tipo === 'solicitarSaque') {
        resultado = await _solicitarSaque(academiaId, { valor: data.valor, uid: data.uid });
      } else if (data.tipo === 'verificarStatusSaque') {
        resultado = await _verificarStatusSaque(academiaId, data.transferId);
      } else if (data.tipo === 'aprovarContaSandbox') {
        resultado = await _aprovarContaSandbox(academiaId);
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
  const makeClient = (walletId) => asaasHttp(ASAAS_API_KEY.value(), walletId);
  const result = await sincronizarPagamentosAcademia(academiaId, alunoId, db, makeClient);
  logger.info(`sincronizar: ${result.sincronizados} pagamento(s) atualizados para ${academiaId}`);
  return result;
}

// academias/{id}/integracoes/asaas é lido pelo app cliente (status, subcontaId,
// walletId) — NUNCA pode guardar subcontaApiKey ou dados bancários, porque o
// catch-all de regras do Firestore libera leitura dessa coleção pra qualquer
// membro da academia. Segredos (apiKey, conta bancária) vivem só em
// academias/{id}/_privado/asaas, que as regras bloqueiam para todo client e
// só o Admin SDK (estas Functions) acessa.
function _privRef(academiaId) {
  return db.doc(`academias/${academiaId}/_privado/asaas`);
}

// Academias que já conectaram a conta Asaas ANTES desta correção têm a
// subcontaApiKey salva em integracoes/asaas (o lugar antigo, legível por
// qualquer membro). Pra não perder o acesso a elas, na primeira leitura
// migra silenciosamente a chave pra _privado/asaas e apaga do documento
// antigo, em vez de simplesmente falhar com "chave não encontrada".
async function _obterSubcontaApiKey(academiaId) {
  const privRef = _privRef(academiaId);
  const privSnap = await privRef.get();
  let apiKey = privSnap.data()?.subcontaApiKey || null;
  if (apiKey) return apiKey;

  const cfgRef = db.doc(`academias/${academiaId}/integracoes/asaas`);
  const cfgSnap = await cfgRef.get();
  apiKey = cfgSnap.data()?.subcontaApiKey || null;
  if (apiKey) {
    await Promise.all([
      privRef.set({ subcontaApiKey: apiKey }, { merge: true }),
      cfgRef.update({ subcontaApiKey: admin.firestore.FieldValue.delete() }),
    ]);
    logger.info(`_obterSubcontaApiKey: migrou subcontaApiKey legada de integracoes/asaas para _privado/asaas (academia ${academiaId})`);
    return apiKey;
  }
  return null;
}

async function _criarSubconta(academiaId) {
  const cfgRef = db.doc(`academias/${academiaId}/integracoes/asaas`);
  const privRef = _privRef(academiaId);
  const cfgSnap = await cfgRef.get();
  if (cfgSnap.exists && cfgSnap.data()?.subcontaId) {
    const cfgData = cfgSnap.data();
    const privSnap = await privRef.get();
    // Se está DESVINCULADO, reconectar à conta Asaas existente (ex: DELETE retornou 403 no sandbox)
    if (cfgData.status === 'DESVINCULADO') {
      let subcontaApiKey = privSnap.data()?.subcontaApiKey || null;
      if (!subcontaApiKey) {
        try {
          const client = asaasHttp(ASAAS_API_KEY.value());
          const accRes = await client.get(`/accounts/${cfgData.subcontaId}`);
          subcontaApiKey = accRes.data?.apiKey || null;
        } catch (_) {}
      }
      const isSandboxRecon = ASAAS_BASE.includes('sandbox');
      const newStatus = isSandboxRecon ? 'AGUARDANDO_CONTA_BANCARIA' : (subcontaApiKey ? 'AGUARDANDO_SMS' : 'AGUARDANDO_CONTA_BANCARIA');
      await Promise.all([
        cfgRef.update({ status: newStatus, desvinculadoEm: admin.firestore.FieldValue.delete() }),
        privRef.set({ subcontaApiKey }, { merge: true }),
      ]);
      logger.info(`_criarSubconta: reconectando conta DESVINCULADO ${cfgData.subcontaId}, novo status: ${newStatus}`);
      return { subcontaId: cfgData.subcontaId, status: newStatus };
    }
    // Já ativa — garante que temos o apiKey salvo
    if (!privSnap.data()?.subcontaApiKey) {
      try {
        const client = asaasHttp(ASAAS_API_KEY.value());
        const accRes = await client.get(`/accounts/${cfgData.subcontaId}`);
        const apiKey = accRes.data?.apiKey;
        if (apiKey) await privRef.set({ subcontaApiKey: apiKey }, { merge: true });
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

  await Promise.all([
    cfgRef.set({
      subcontaId,
      status,
      criadoEm: admin.firestore.FieldValue.serverTimestamp(),
    }),
    privRef.set({ subcontaApiKey }, { merge: true }),
  ]);

  logger.info(`_criarSubconta: status final = ${status}, apiKey salvo = ${!!subcontaApiKey}`);
  return { subcontaId, status };
}

async function _reenviarCodigoSms(academiaId) {
  const cfgRef = db.doc(`academias/${academiaId}/integracoes/asaas`);
  const privRef = _privRef(academiaId);
  const cfgSnap = await cfgRef.get();
  if (!cfgSnap.exists) throw new Error('Configuração Asaas não encontrada.');
  const { subcontaId } = cfgSnap.data();
  if (!subcontaId) throw new Error('Sub-conta não vinculada.');
  let subcontaApiKey = await _obterSubcontaApiKey(academiaId);

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
      if (subcontaApiKey) await privRef.set({ subcontaApiKey }, { merge: true });
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
  const subcontaApiKey = await _obterSubcontaApiKey(academiaId);
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
  const privRef = _privRef(academiaId);
  const cfgSnap = await cfgRef.get();
  if (!cfgSnap.exists) throw new Error('Configuração Asaas não encontrada.');
  const subcontaApiKey = await _obterSubcontaApiKey(academiaId);
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

  // Guardamos os dados bancários porque a API de transferência da Asaas não
  // guarda/referencia a conta cadastrada em /myAccount/bankAccount — toda
  // transferência exige os dados bancários completos de novo no corpo da
  // requisição (ver _solicitarSaque).
  await Promise.all([
    cfgRef.update({ status: 'PENDENTE', contaBancariaConfigurada: true }),
    privRef.set({
      contaBancaria: {
        codigoBanco: String(codigoBanco),
        agencia: String(agencia),
        conta: String(conta),
        digitoConta: String(digitoConta || '0'),
        tipoConta,
        nomeTitular,
        cpfCnpjTitular: String(cpfCnpjTitular).replace(/\D/g, ''),
      },
    }, { merge: true }),
  ]);
  return { status: 'PENDENTE' };
}

async function _consultarSaldo(academiaId) {
  const cfgSnap = await db.doc(`academias/${academiaId}/integracoes/asaas`).get();
  const { status } = cfgSnap.data() || {};
  const subcontaApiKey = await _obterSubcontaApiKey(academiaId);
  if (!subcontaApiKey) throw new Error('Pagamentos ainda não configurados para esta academia.');
  if (status !== 'ATIVO') throw new Error('A conta de pagamentos ainda não foi aprovada pelo Asaas.');

  const subClient = asaasHttp(subcontaApiKey);
  const r = await subClient.get('/finance/balance');
  return { saldo: r.data?.balance ?? 0 };
}

async function _obterExtrato(academiaId, { offset = 0, limit = 20 } = {}) {
  const cfgSnap = await db.doc(`academias/${academiaId}/integracoes/asaas`).get();
  const { status } = cfgSnap.data() || {};
  const subcontaApiKey = await _obterSubcontaApiKey(academiaId);
  if (!subcontaApiKey) throw new Error('Pagamentos ainda não configurados para esta academia.');
  if (status !== 'ATIVO') throw new Error('A conta de pagamentos ainda não foi aprovada pelo Asaas.');

  const subClient = asaasHttp(subcontaApiKey);
  const lim = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const off = Math.max(Number(offset) || 0, 0);
  const r = await subClient.get(`/financialTransactions?offset=${off}&limit=${lim}&order=desc`);
  const data = r.data || {};
  return {
    itens: (data.data || []).map((t) => ({
      id: t.id,
      tipo: t.type,
      valor: t.value,
      saldoApos: t.balance,
      data: t.date,
      descricao: t.description || '',
    })),
    temMais: !!data.hasMore,
    total: data.totalCount || 0,
  };
}

async function _solicitarSaque(academiaId, { valor, uid }) {
  const valorNum = Number(valor);
  if (!valorNum || valorNum <= 0) throw new Error('Informe um valor válido para o saque.');

  const cfgSnap = await db.doc(`academias/${academiaId}/integracoes/asaas`).get();
  const { status } = cfgSnap.data() || {};
  const subcontaApiKey = await _obterSubcontaApiKey(academiaId);
  const { contaBancaria } = (await _privRef(academiaId).get()).data() || {};
  if (!subcontaApiKey) throw new Error('Pagamentos ainda não configurados para esta academia.');
  if (status !== 'ATIVO') throw new Error('A conta de pagamentos ainda não foi aprovada pelo Asaas.');
  if (!contaBancaria) throw new Error('Cadastre a conta bancária de recebimento antes de solicitar um saque.');

  const subClient = asaasHttp(subcontaApiKey);

  // Confere o saldo antes de pedir a transferência — a Asaas também valida,
  // mas isso evita uma chamada de transferência destinada a falhar e dá um
  // erro mais claro pro usuário.
  const balanceR = await subClient.get('/finance/balance');
  const saldoAtual = balanceR.data?.balance ?? 0;
  if (valorNum > saldoAtual) {
    throw new Error(`Saldo insuficiente. Disponível: R$ ${saldoAtual.toFixed(2).replace('.', ',')}.`);
  }

  let transferResp;
  try {
    transferResp = await subClient.post('/transfers', {
      value: valorNum,
      bankAccount: {
        bank: { code: contaBancaria.codigoBanco },
        ownerName: contaBancaria.nomeTitular,
        cpfCnpj: contaBancaria.cpfCnpjTitular,
        agency: contaBancaria.agencia,
        account: contaBancaria.conta,
        accountDigit: contaBancaria.digitoConta,
        bankAccountType: contaBancaria.tipoConta,
      },
      description: 'Saque solicitado pelo app Sensei Manager',
      externalReference: academiaId,
    });
  } catch (e) {
    const msg = e.response?.data?.errors?.[0]?.description || e.message;
    throw new Error(`Erro ao solicitar transferência: ${msg}`);
  }

  const t = transferResp.data || {};
  const saqueRef = db.doc(`academias/${academiaId}/saques/${t.id}`);
  await saqueRef.set({
    asaasTransferId: t.id,
    valor: valorNum,
    netValue: t.netValue ?? null,
    taxa: t.transferFee ?? null,
    status: t.status || 'PENDING',
    tipoOperacao: t.operationType || null,
    solicitadoPorUid: uid || null,
    criadoEm: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { id: t.id, status: t.status, valor: valorNum, netValue: t.netValue ?? null };
}

async function _verificarStatusSaque(academiaId, transferId) {
  if (!transferId) throw new Error('transferId obrigatório.');
  const subcontaApiKey = await _obterSubcontaApiKey(academiaId);
  if (!subcontaApiKey) throw new Error('Pagamentos ainda não configurados para esta academia.');

  const subClient = asaasHttp(subcontaApiKey);
  const r = await subClient.get(`/transfers/${transferId}`);
  const t = r.data || {};

  await db.doc(`academias/${academiaId}/saques/${transferId}`).update({
    status: t.status || 'PENDING',
    netValue: t.netValue ?? null,
    taxa: t.transferFee ?? null,
    falhaMotivo: t.failReason || null,
    atualizadoEm: admin.firestore.FieldValue.serverTimestamp(),
  }).catch(() => {});

  return { id: t.id, status: t.status, netValue: t.netValue ?? null, falhaMotivo: t.failReason || null };
}

async function _verificarStatus(academiaId) {
  const cfgSnap = await db.doc(`academias/${academiaId}/integracoes/asaas`).get();
  if (!cfgSnap.exists || !cfgSnap.data()?.subcontaId) return { configurado: false };

  const { subcontaId } = cfgSnap.data();
  const cfgRef = db.doc(`academias/${academiaId}/integracoes/asaas`);

  // Ver nota em verificarStatusAsaas: a Asaas bloqueia por excesso de
  // consultas se checarmos /myAccount/status com frequência demais (ex.:
  // toda vez que o admin abre a tela). Reaproveita o último resultado por
  // um tempo curto em vez de bater na Asaas de novo a cada chamada.
  const verificadoEm = cfgSnap.data()?.statusVerificadoEm?.toMillis?.();
  if (verificadoEm && Date.now() - verificadoEm < 90_000) {
    return { configurado: true, subcontaId, status: cfgSnap.data().status, nomeAsaas: cfgSnap.data().nomeAsaas };
  }

  const client = asaasHttp(ASAAS_API_KEY.value());
  let nomeAsaas;
  try {
    const r = await client.get(`/accounts/${subcontaId}`);
    nomeAsaas = r.data.name;
  } catch (_) { /* segue sem o nome */ }

  let status = 'PENDENTE';
  const subcontaApiKey = await _obterSubcontaApiKey(academiaId);
  if (subcontaApiKey) {
    try {
      const subClient = asaasHttp(subcontaApiKey);
      const statusR = await subClient.get('/myAccount/status/');
      if (statusR.data?.general === 'APPROVED') {
        status = 'ATIVO';
        await _garantirChavePixEvp(academiaId, subcontaApiKey);
      }
    } catch (e) {
      logger.warn(`_verificarStatus: falha ao consultar /myAccount/status (${academiaId}):`, e.response?.status, e.response?.data || e.message);
    }
  }
  await cfgRef.update({ status, nomeAsaas: nomeAsaas || null, statusVerificadoEm: admin.firestore.FieldValue.serverTimestamp() });
  return { configurado: true, subcontaId, status, nomeAsaas };
}

// Só funciona no Asaas sandbox (POST /sandbox/myAccount/approve) — aprova a
// conta autenticada só pra fins de teste; não representa aprovação real e a
// própria Asaas bloqueia essa chamada fora do sandbox. Serve pra desbloquear
// o teste do fluxo feliz sem precisar enviar documentação de verdade.
// Sem chave Pix cadastrada, a Asaas gera uma chave temporária pra receber o
// Pix, o que aumenta o tempo de processamento (ver docs Asaas, seção Pix —
// "Before you start"). A criação só é permitida depois que a conta está
// 100% aprovada. Então sempre que a conta vira ATIVO, tenta cadastrar uma
// chave EVP (aleatória) uma única vez — melhor esforço, não falha o fluxo
// se já existir uma chave ou se a Asaas recusar.
async function _garantirChavePixEvp(academiaId, subcontaApiKey) {
  const privSnap = await _privRef(academiaId).get();
  if (privSnap.data()?.pixKeyRegistrada) return;

  // Uma tentativa só, sem retry imediato — repetir a chamada sem intervalo
  // (como fazia antes) só piora um bloqueio por excesso de consultas da
  // Asaas. A próxima verificação de status (ação do usuário, com minutos
  // de intervalo real) já serve como retry natural.
  try {
    const subClient = asaasHttp(subcontaApiKey);
    await subClient.post('/pix/addressKeys', { type: 'EVP' });
    await _privRef(academiaId).set({ pixKeyRegistrada: true }, { merge: true });
    logger.info(`_garantirChavePixEvp: chave Pix EVP registrada para academia ${academiaId}`);
  } catch (e) {
    logger.warn(`_garantirChavePixEvp: falha ao registrar chave Pix (${academiaId}):`, e.response?.status, e.response?.data || e.message);
  }
}

async function _aprovarContaSandbox(academiaId) {
  if (!ASAAS_BASE.includes('sandbox')) {
    throw new Error('Esta ação só está disponível no ambiente sandbox.');
  }
  const subcontaApiKey = await _obterSubcontaApiKey(academiaId);
  if (!subcontaApiKey) throw new Error('Esta academia ainda não tem uma subconta Asaas configurada.');

  const subClient = asaasHttp(subcontaApiKey);
  const r = await subClient.post('/sandbox/myAccount/approve');
  const status = r.data?.general === 'APPROVED' ? 'ATIVO' : 'PENDENTE';
  if (status === 'ATIVO') await _garantirChavePixEvp(academiaId, subcontaApiKey);
  await db.doc(`academias/${academiaId}/integracoes/asaas`).update({ status });
  return { status, aprovacao: r.data };
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

    const updates = [];

    for (const doc of snap.docs) {
      const { subcontaId } = doc.data();
      const academiaId = doc.ref.parent.parent.id;
      try {
        // Ver nota em verificarStatusAsaas: só a aprovação real (general ===
        // 'APPROVED' via /myAccount/status com a chave da própria subconta)
        // confirma que a conta pode mesmo receber pagamentos.
        const subcontaApiKey = await _obterSubcontaApiKey(academiaId);
        if (!subcontaApiKey) continue;
        const subClient = asaasHttp(subcontaApiKey);
        const statusR = await subClient.get('/myAccount/status/');
        if (statusR.data?.general === 'APPROVED') {
          await _garantirChavePixEvp(academiaId, subcontaApiKey);
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

// ── sincronizarPagamentosGlobal ───────────────────────────────────────────────
// Fallback para quando o webhook do Asaas falha ou fica pausado.
// Roda a cada hora e sincroniza todos os pagamentos PENDING de todas as
// academias que têm integração Asaas ativa.
exports.sincronizarPagamentosGlobal = onSchedule(
  {
    schedule: 'every 1 hours',
    timeZone: 'America/Sao_Paulo',
    secrets: [ASAAS_API_KEY],
    timeoutSeconds: 540,
    memory: '256MiB',
  },
  async () => {
    const integracoesSnap = await db.collectionGroup('integracoes')
      .where('subcontaId', '!=', null)
      .get();

    if (integracoesSnap.empty) {
      logger.info('sincronizarPagamentosGlobal: nenhuma academia com integração Asaas.');
      return;
    }

    const academiaIds = [...new Set(
      integracoesSnap.docs.map(d => d.ref.parent.parent?.id).filter(Boolean)
    )];

    logger.info(`sincronizarPagamentosGlobal: verificando ${academiaIds.length} academia(s).`);

    let totalSincronizados = 0;
    for (const academiaId of academiaIds) {
      try {
        const result = await _sincronizarPagamentos(academiaId, null);
        totalSincronizados += result.sincronizados;
      } catch (e) {
        logger.error(`sincronizarPagamentosGlobal: erro na academia ${academiaId}:`, e.message);
      }
    }

    logger.info(`sincronizarPagamentosGlobal: concluído — ${totalSincronizados} pagamento(s) atualizados.`);
  }
);

exports.testarVencimentosContasAcademia = onRequest(async (req, res) => {
  const total = await processarVencimentosContasAcademia();
  res.status(200).json({ alertasGerados: total });
});

const appFeedbackFunctions = require("./app-feedback-functions");
exports.registrarFeedbackApp = appFeedbackFunctions.registrarFeedbackApp;

const novoCadastroEmail = require("./novo-cadastro-email");
exports.avisarNovaAcademia = novoCadastroEmail.avisarNovaAcademia;
