"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { detectarConflitoDeOrdem } = require("./domain/graduacao");

const db = admin.firestore();
const IDENTITY_FUNCTION_OPTIONS = {
  serviceAccount: "identity-functions@sensei-manager-d64c0.iam.gserviceaccount.com",
};

// Quem já pode registrar uma graduação (permissão `acao_graduar`, ligada ao
// perfil) também pode corrigi-la — a edição não abre um poder novo.
const EDIT_ROLES = new Set(["Admin", "Secretaria", "Professor"]);
const EDITABLE_KEYS = ["faixa_id", "grau", "data_exame", "observacoes", "aprovado"];

/**
 * Verifica, a partir do schema v2 (nunca do cliente), se quem chama pode
 * editar graduações nesta academia: Admin sempre pode; Secretaria/Professor
 * precisam da mesma permissão `acao_graduar` já usada para criar graduações.
 */
async function loadEditorAuthority(callerUid, academiaId) {
  const accountSnap = await db.collection("usuariosFirebase").doc(callerUid).get();
  const account = accountSnap.data();
  if (!account) return null;

  // O dono/gestor que criou a academia é Admin dentro de `usuarios`, não de
  // `funcionarios` — só quem é adicionado depois pela tela de Equipe vira
  // `funcionarios`. Por isso o Admin não fica restrito à coleção aqui; só a
  // permissão granular de Secretaria/Professor (abaixo) exige `funcionarios`.
  const refs = Array.isArray(account.profile_refs) ? account.profile_refs : [];
  const staffRef = refs.find(
    (ref) => ref.academiaId === academiaId && EDIT_ROLES.has(ref.perfil_nome),
  );
  if (!staffRef) return null;

  if (staffRef.perfil_nome === "Admin") {
    return { usuarioId: staffRef.usuarioId, nome: staffRef.nome, perfil: "Admin" };
  }

  if (staffRef.colecao !== "funcionarios") return null;

  const funcSnap = await db
    .collection("academias").doc(academiaId)
    .collection("funcionarios").doc(staffRef.usuarioId)
    .get();
  if (funcSnap.data()?.permissoes?.acao_graduar !== true) return null;

  return { usuarioId: staffRef.usuarioId, nome: staffRef.nome, perfil: staffRef.perfil_nome };
}

function pickBefore(data) {
  const before = {};
  for (const key of EDITABLE_KEYS) before[key] = data[key] ?? null;
  return before;
}

function mensagemConflito(conflito) {
  const dataAnterior = conflito.anterior.data_exame ?? "uma data anterior";
  const dataAtual = conflito.atual.data_exame ?? "uma data posterior";
  return (
    `Depois desta correção, a graduação de ${dataAtual} ficou com progressão ` +
    `menor que a de ${dataAnterior} na mesma modalidade. Revise o histórico.`
  );
}

exports.editarGraduacao = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "É necessário autenticar antes de editar uma graduação.");
  }

  const academiaId = String(request.data?.academiaId ?? "").trim();
  const graduacaoId = String(request.data?.graduacaoId ?? "").trim();
  const faixaId = String(request.data?.faixaId ?? "").trim();
  const grauRaw = request.data?.grau;
  const grau = Number.isInteger(grauRaw) ? grauRaw : (parseInt(grauRaw, 10) || 0);
  const dataExame = String(request.data?.dataExame ?? "").trim();
  const observacoes = typeof request.data?.observacoes === "string" ? request.data.observacoes.trim() : "";

  if (!academiaId || !graduacaoId || !faixaId || !dataExame) {
    throw new HttpsError("invalid-argument", "Informe a faixa, a data do exame e a graduação a editar.");
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dataExame)) {
    throw new HttpsError("invalid-argument", "Data do exame inválida.");
  }
  if (grau < 0 || grau > 10) {
    throw new HttpsError("invalid-argument", "Grau inválido.");
  }

  const authority = await loadEditorAuthority(request.auth.uid, academiaId);
  if (!authority) {
    throw new HttpsError(
      "permission-denied",
      "Você não tem permissão para editar graduações nesta academia.",
    );
  }

  const graduacaoRef = db.collection("academias").doc(academiaId).collection("graduacoes").doc(graduacaoId);
  const faixaRef = db.collection("academias").doc(academiaId).collection("faixas").doc(faixaId);

  const { before, after, alunoId, modalidadeId } = await db.runTransaction(async (transaction) => {
    const [graduacaoSnap, faixaSnap] = await Promise.all([
      transaction.get(graduacaoRef),
      transaction.get(faixaRef),
    ]);
    if (!graduacaoSnap.exists) throw new HttpsError("not-found", "Graduação não encontrada.");
    if (!faixaSnap.exists) throw new HttpsError("not-found", "Faixa não encontrada.");

    const graduacaoData = graduacaoSnap.data();
    const faixaData = faixaSnap.data();
    const modalidadeAtual = String(graduacaoData.modalidade_id ?? "");
    const modalidadeFaixa = String(faixaData.modalidadeId ?? faixaData.modalidade_id ?? "");
    if (modalidadeAtual && modalidadeFaixa && modalidadeAtual !== modalidadeFaixa) {
      throw new HttpsError(
        "failed-precondition",
        "Não é possível trocar a modalidade de uma graduação existente. Remova e crie uma nova.",
      );
    }

    const before = pickBefore(graduacaoData);
    const after = { faixa_id: faixaId, grau, data_exame: dataExame, observacoes, aprovado: true };

    transaction.update(graduacaoRef, {
      ...after,
      nomeFaixa: faixaData.nome || "",
      corFaixa: faixaData.cor || "#FFFFFF",
      corBarraFaixa: faixaData.cor_barra || "#000000",
      faixaOrdem: faixaData.ordem ?? 0,
      faixaTemGraus: faixaData.tem_graus === true,
      faixaMaxGraus: faixaData.max_graus ?? 0,
      editado_em: FieldValue.serverTimestamp(),
      editado_por: { uid: request.auth.uid, usuarioId: authority.usuarioId, nome: authority.nome },
    });

    transaction.set(db.collection("academias").doc(academiaId).collection("auditoria").doc(), {
      tipo: "edicao_graduacao",
      alvo: { graduacaoId, alunoId: graduacaoData.aluno_id ?? "" },
      antes: before,
      depois: after,
      realizado_por: {
        uid: request.auth.uid,
        usuarioId: authority.usuarioId,
        nome: authority.nome,
        perfil: authority.perfil,
      },
      criado_em: FieldValue.serverTimestamp(),
    });

    return {
      before,
      after,
      alunoId: String(graduacaoData.aluno_id ?? ""),
      modalidadeId: modalidadeAtual || modalidadeFaixa,
    };
  });

  // Fora da transação: só leitura, para avisar sem bloquear a correção —
  // a regra de progressão ascendente não se aplica a uma edição corretiva.
  let conflito = null;
  if (alunoId && modalidadeId) {
    try {
      const irmasSnap = await db
        .collection("academias").doc(academiaId)
        .collection("graduacoes")
        .where("aluno_id", "==", alunoId)
        .where("modalidade_id", "==", modalidadeId)
        .get();
      const graduacoes = irmasSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
      const conflitoDetectado = detectarConflitoDeOrdem(graduacoes);
      if (conflitoDetectado) conflito = { mensagem: mensagemConflito(conflitoDetectado) };
    } catch (error) {
      logger.warn("Não foi possível checar conflito de ordem após editar graduação", { academiaId, graduacaoId, error: String(error) });
    }
  }

  logger.info("Graduação editada", {
    academiaId,
    graduacaoId,
    realizadoPor: request.auth.uid,
    conflito: Boolean(conflito),
  });

  return { ok: true, before, after, conflito };
});

exports._test = { loadEditorAuthority };
