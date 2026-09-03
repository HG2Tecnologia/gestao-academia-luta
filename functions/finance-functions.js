"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const {
  addBillingMonths,
  dueDateForPeriod,
  monthlyChargeDocumentId,
  parseBillingPeriod,
} = require("./domain/billing");

const db = admin.firestore();
const IDENTITY_FUNCTION_OPTIONS = {
  serviceAccount: "identity-functions@sensei-manager-d64c0.iam.gserviceaccount.com",
};

const FINANCE_ROLES = new Set(["Admin", "Secretaria"]);
const DEFAULT_DUE_DAY = 10;

async function loadFinanceAuthority(callerUid, academiaId) {
  const accountSnap = await db.collection("usuariosFirebase").doc(callerUid).get();
  const account = accountSnap.data();
  if (!account) return null;

  // O dono/gestor que criou a academia é Admin dentro de `usuarios`, não de
  // `funcionarios` — só quem é adicionado depois pela tela de Equipe vira
  // `funcionarios`. Financeiro não tem permissão granular (Admin ou
  // Secretaria, ponto), então nenhum dos dois fica restrito à coleção aqui.
  const refs = Array.isArray(account.profile_refs) ? account.profile_refs : [];
  const staffRef = refs.find(
    (ref) => ref.academiaId === academiaId && FINANCE_ROLES.has(ref.perfil_nome),
  );
  return staffRef ? { usuarioId: staffRef.usuarioId, nome: staffRef.nome, perfil: staffRef.perfil_nome } : null;
}

/**
 * Garante que todo aluno ativo com plano tenha a mensalidade da competência
 * dada — idempotente: um `pagamentos/{id}` já existente nunca é sobrescrito
 * ou duplicado, porque o ID é determinístico (`monthlyChargeDocumentId`) e a
 * criação é condicionada, dentro de uma transação, à ausência prévia do
 * documento. Chamar de novo para a mesma competência é sempre seguro.
 */
async function ensureChargesForPeriodCore(academiaId, periodValue) {
  const period = parseBillingPeriod(periodValue).value;

  const [alunosSnap, planosSnap] = await Promise.all([
    db.collection("academias").doc(academiaId).collection("usuarios").where("ativo", "==", true).get(),
    db.collection("academias").doc(academiaId).collection("planos").get(),
  ]);

  const planosPorId = new Map();
  for (const doc of planosSnap.docs) planosPorId.set(doc.id, doc.data());

  let criadas = 0;
  let ignoradas = 0;

  for (const alunoDoc of alunosSnap.docs) {
    const aluno = alunoDoc.data();
    const planoId = String(aluno.plano_id ?? "").trim();
    if (!planoId) continue; // sem plano: nada a cobrar automaticamente.
    const plano = planosPorId.get(planoId);
    if (!plano) continue;

    const alunoId = alunoDoc.id;
    const diaVencimento = Number.isInteger(aluno.dia_vencimento) ? aluno.dia_vencimento : DEFAULT_DUE_DAY;
    const valor = Number(plano.valor_mensal ?? 0);
    const chargeId = monthlyChargeDocumentId(alunoId, period);
    const chargeRef = db.collection("academias").doc(academiaId).collection("pagamentos").doc(chargeId);

    const criado = await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(chargeRef);
      if (snapshot.exists) return false;
      transaction.create(chargeRef, {
        id: chargeId,
        aluno_id: alunoId,
        aluno_nome: aluno.nome || "",
        plano_id: planoId,
        plano_nome: plano.nome || "",
        tipo: "Mensalidade",
        valor,
        data_vencimento: dueDateForPeriod(period, diaVencimento),
        status: 0,
        mes_referencia: period,
        origem: "auto",
        criado_em: FieldValue.serverTimestamp(),
      });
      return true;
    });

    if (criado) criadas++;
    else ignoradas++;
  }

  return { period, criadas, ignoradas };
}

exports.ensureChargesForPeriod = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "É necessário autenticar antes de gerar cobranças.");
  }

  const academiaId = String(request.data?.academiaId ?? "").trim();
  const periodValue = String(request.data?.period ?? "").trim();
  if (!academiaId || !periodValue) {
    throw new HttpsError("invalid-argument", "Informe a academia e a competência (YYYY-MM).");
  }

  const authority = await loadFinanceAuthority(request.auth.uid, academiaId);
  if (!authority) {
    throw new HttpsError("permission-denied", "Você não tem permissão para gerenciar o financeiro desta academia.");
  }

  let result;
  try {
    result = await ensureChargesForPeriodCore(academiaId, periodValue);
  } catch (error) {
    if (error instanceof TypeError) throw new HttpsError("invalid-argument", error.message);
    throw error;
  }

  logger.info("Mensalidades garantidas", { academiaId, ...result, chamadoPor: request.auth.uid });
  return { ok: true, ...result };
});

/**
 * Roda todo dia às 06:00 (horário de Brasília) e garante a competência atual
 * e a próxima para todas as academias — assim a virada de mês já chega com
 * as mensalidades geradas, sem depender de alguém abrir o Financeiro antes.
 */
exports.gerarMensalidadesAutomaticas = onSchedule(
  { schedule: "0 6 * * *", timeZone: "America/Sao_Paulo" },
  async () => {
    const hoje = new Date();
    const periodoAtual = `${hoje.getFullYear()}-${String(hoje.getMonth() + 1).padStart(2, "0")}`;
    const periodoSeguinte = addBillingMonths(periodoAtual, 1);

    const academiasSnap = await db.collection("academias").get();
    let totalCriadas = 0;
    for (const academiaDoc of academiasSnap.docs) {
      for (const period of [periodoAtual, periodoSeguinte]) {
        try {
          const resultado = await ensureChargesForPeriodCore(academiaDoc.id, period);
          totalCriadas += resultado.criadas;
        } catch (error) {
          logger.error("Falha ao gerar mensalidades automáticas", {
            academiaId: academiaDoc.id,
            period,
            error: String(error),
          });
        }
      }
    }
    logger.info(`Mensalidades automáticas processadas: ${totalCriadas} cobrança(s) criada(s).`);
  },
);

exports._test = { ensureChargesForPeriodCore, loadFinanceAuthority };
