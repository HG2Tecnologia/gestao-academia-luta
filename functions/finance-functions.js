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
  resolveDuplicateGroup,
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

/**
 * Desconsidera (nunca exclui, nunca marca como paga) toda cobrança com
 * competência ANTERIOR a `periodValue` — usado para "limpar" pendências
 * retroativas geradas por engano (ex.: bug de geração de mensalidade para
 * meses em que o aluno nem estava com o plano ativo). Cobrança já paga
 * (status 1) ou já desconsiderada (status 4) nunca é tocada — preserva
 * histórico de receita e é idempotente para reprocessamento.
 */
async function disregardChargesBeforePeriodCore(academiaId, periodValue) {
  const period = parseBillingPeriod(periodValue).value;

  const snap = await db
    .collection("academias")
    .doc(academiaId)
    .collection("pagamentos")
    .where("mes_referencia", "<", period)
    .get();

  let desconsideradas = 0;
  let ignoradas = 0;
  let batch = db.batch();
  let opsNoBatch = 0;
  const TAMANHO_LOTE = 400; // margem sob o limite de 500 do Firestore

  for (const doc of snap.docs) {
    const status = doc.data().status;
    if (status === 1 || status === 4) {
      ignoradas++;
      continue;
    }
    batch.update(doc.ref, {
      status: 4,
      desconsiderado_em: FieldValue.serverTimestamp(),
      desconsiderado_motivo: "limpeza_retroativa",
    });
    desconsideradas++;
    opsNoBatch++;
    if (opsNoBatch >= TAMANHO_LOTE) {
      await batch.commit();
      batch = db.batch();
      opsNoBatch = 0;
    }
  }
  if (opsNoBatch > 0) await batch.commit();

  return { period, desconsideradas, ignoradas };
}

exports.disregardChargesBeforePeriod = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "É necessário autenticar antes de limpar cobranças.");
  }

  const academiaId = String(request.data?.academiaId ?? "").trim();
  const periodValue = String(request.data?.period ?? "").trim();
  if (!academiaId || !periodValue) {
    throw new HttpsError("invalid-argument", "Informe a academia e a competência de corte (YYYY-MM).");
  }

  const authority = await loadFinanceAuthority(request.auth.uid, academiaId);
  if (!authority) {
    throw new HttpsError("permission-denied", "Você não tem permissão para gerenciar o financeiro desta academia.");
  }

  let result;
  try {
    result = await disregardChargesBeforePeriodCore(academiaId, periodValue);
  } catch (error) {
    if (error instanceof TypeError) throw new HttpsError("invalid-argument", error.message);
    throw error;
  }

  logger.info("Cobranças retroativas desconsideradas", { academiaId, ...result, chamadoPor: request.auth.uid });
  return { ok: true, ...result };
});

function mesReferenciaEfetiva(pagamento) {
  const direto = String(pagamento.mes_referencia ?? "").trim();
  if (/^\d{4}-\d{2}$/.test(direto)) return direto;
  const venc = String(pagamento.data_vencimento ?? "");
  const match = /^(\d{4}-\d{2})/.exec(venc);
  return match ? match[1] : null;
}

// Mensalidade "de verdade" — o que pode duplicar por engano. Cobrança avulsa
// (`tipo` como "Taxa de Matrícula") ou taxa de graduação (`tipo` numérico)
// legitimamente coexiste com a mensalidade no mesmo mês; nunca é considerada
// duplicata. Documentos antigos, gerados pelo caminho ad-hoc já removido do
// app (sem `tipo` nenhum), são tratados como mensalidade — é exatamente o
// formato do bug que gerou as duplicatas reais em produção.
function eMensalidade(pagamento) {
  const tipo = pagamento.tipo;
  return tipo === undefined || tipo === null || tipo === "Mensalidade";
}

/**
 * Acha grupos de mensalidade duplicada (mesmo aluno + mesma competência, mais
 * de um documento ativo) e resolve automaticamente os casos inequívocos,
 * mantendo sempre UM documento por aluno/mês e desconsiderando (nunca
 * excluindo, nunca marcando como paga) os demais:
 *
 *  * Se exatamente um dos duplicados está `Pago`, esse é o que fica — os
 *    outros (nunca pagos de verdade) viram Desconsiderado.
 *  * Se nenhum está pago, fica o de ID determinístico
 *    (`mensalidade__{aluno}__{mês}`, o gerado pelo caminho oficial) ou, na
 *    falta desse, o mais antigo — os demais viram Desconsiderado.
 *  * Se DOIS OU MAIS estão `Pago`, o grupo é ignorado (fica para revisão
 *    manual) — decidir sozinho ali apagaria receita já recebida de verdade,
 *    o que exige critério humano, não automação.
 */
async function mergeDuplicateChargesCore(academiaId) {
  const snap = await db.collection("academias").doc(academiaId).collection("pagamentos").get();

  const grupos = new Map(); // "alunoId|mes" -> [{ref, data}]
  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.status === 4) continue; // já desconsiderada: não conta pra duplicidade
    if (!eMensalidade(data)) continue;
    const alunoId = String(data.aluno_id ?? "").trim();
    const mes = mesReferenciaEfetiva(data);
    if (!alunoId || !mes) continue;
    const chave = `${alunoId}|${mes}`;
    if (!grupos.has(chave)) grupos.set(chave, []);
    grupos.get(chave).push({ ref: doc.ref, data });
  }

  let gruposComDuplicata = 0;
  let resolvidasAutomaticamente = 0;
  let ignoradasRevisaoManual = 0;
  let batch = db.batch();
  let opsNoBatch = 0;
  const TAMANHO_LOTE = 400;

  for (const docs of grupos.values()) {
    if (docs.length < 2) continue;
    gruposComDuplicata++;

    const refPorId = new Map(docs.map((d) => [d.ref.id, d.ref]));
    const decisao = resolveDuplicateGroup(
      docs.map((d) => ({
        id: d.ref.id,
        status: d.data.status,
        criadoEmMillis: d.data.criado_em?.toMillis?.() ?? 0,
      })),
    );

    if (decisao.ignorar) {
      ignoradasRevisaoManual++;
      continue;
    }

    for (const id of decisao.desconsiderarIds) {
      batch.update(refPorId.get(id), {
        status: 4,
        desconsiderado_em: FieldValue.serverTimestamp(),
        desconsiderado_motivo: "duplicata_mensalidade",
      });
      resolvidasAutomaticamente++;
      opsNoBatch++;
      if (opsNoBatch >= TAMANHO_LOTE) {
        await batch.commit();
        batch = db.batch();
        opsNoBatch = 0;
      }
    }
  }
  if (opsNoBatch > 0) await batch.commit();

  return { gruposComDuplicata, resolvidasAutomaticamente, ignoradasRevisaoManual };
}

exports.mergeDuplicateCharges = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "É necessário autenticar antes de corrigir duplicatas.");
  }

  const academiaId = String(request.data?.academiaId ?? "").trim();
  if (!academiaId) {
    throw new HttpsError("invalid-argument", "Informe a academia.");
  }

  const authority = await loadFinanceAuthority(request.auth.uid, academiaId);
  if (!authority) {
    throw new HttpsError("permission-denied", "Você não tem permissão para gerenciar o financeiro desta academia.");
  }

  const result = await mergeDuplicateChargesCore(academiaId);

  logger.info("Mensalidades duplicadas corrigidas", { academiaId, ...result, chamadoPor: request.auth.uid });
  return { ok: true, ...result };
});

exports._test = {
  ensureChargesForPeriodCore,
  disregardChargesBeforePeriodCore,
  mergeDuplicateChargesCore,
  loadFinanceAuthority,
};
