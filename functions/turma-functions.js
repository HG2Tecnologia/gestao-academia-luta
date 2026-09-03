"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

const db = admin.firestore();
const IDENTITY_FUNCTION_OPTIONS = {
  serviceAccount: "identity-functions@sensei-manager-d64c0.iam.gserviceaccount.com",
};

// Exclusão de turma é um ato administrativo — diferente da edição de
// graduação, aqui Professor não participa.
const DELETE_ROLES = new Set(["Admin", "Secretaria"]);

async function loadDeleterAuthority(callerUid, academiaId) {
  const accountSnap = await db.collection("usuariosFirebase").doc(callerUid).get();
  const account = accountSnap.data();
  if (!account) return null;

  // O dono/gestor que criou a academia é Admin dentro de `usuarios`, não de
  // `funcionarios` — só quem é adicionado depois pela tela de Equipe vira
  // `funcionarios`. Exclusão de turma não tem permissão granular (Admin ou
  // Secretaria, ponto), então nenhum dos dois fica restrito à coleção aqui.
  const refs = Array.isArray(account.profile_refs) ? account.profile_refs : [];
  const staffRef = refs.find(
    (ref) => ref.academiaId === academiaId && DELETE_ROLES.has(ref.perfil_nome),
  );
  if (!staffRef) return null;
  return { usuarioId: staffRef.usuarioId, nome: staffRef.nome, perfil: staffRef.perfil_nome };
}

/**
 * Exclusão lógica (soft delete) de turma: nunca apaga o documento. Marca
 * `deleted_at`/`deleted_by`, encerra as matrículas ativas na mesma
 * transação e preserva presenças, graduações e horários históricos —
 * eles continuam resolvendo o nome da turma normalmente pelo `turma_id`.
 */
exports.arquivarTurma = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "É necessário autenticar antes de excluir uma turma.");
  }

  const academiaId = String(request.data?.academiaId ?? "").trim();
  const turmaId = String(request.data?.turmaId ?? "").trim();
  if (!academiaId || !turmaId) {
    throw new HttpsError("invalid-argument", "Informe a academia e a turma a excluir.");
  }

  const authority = await loadDeleterAuthority(request.auth.uid, academiaId);
  if (!authority) {
    throw new HttpsError("permission-denied", "Você não tem permissão para excluir turmas nesta academia.");
  }

  const turmaRef = db.collection("academias").doc(academiaId).collection("turmas").doc(turmaId);
  const matriculasQuery = db
    .collection("academias").doc(academiaId)
    .collection("matriculas")
    .where("turma_id", "==", turmaId)
    .where("ativo", "==", true);

  const matriculasEncerradas = await db.runTransaction(async (transaction) => {
    const [turmaSnap, matriculasSnap] = await Promise.all([
      transaction.get(turmaRef),
      transaction.get(matriculasQuery),
    ]);
    if (!turmaSnap.exists) throw new HttpsError("not-found", "Turma não encontrada.");
    const turmaData = turmaSnap.data();
    if (turmaData.deleted_at) {
      throw new HttpsError("failed-precondition", "Esta turma já foi excluída.");
    }

    for (const matriculaDoc of matriculasSnap.docs) {
      transaction.update(matriculaDoc.ref, {
        ativo: false,
        encerrado_em: FieldValue.serverTimestamp(),
        encerrado_motivo: "turma_excluida",
      });
    }

    transaction.update(turmaRef, {
      ativo: false,
      deleted_at: FieldValue.serverTimestamp(),
      deleted_by: { uid: request.auth.uid, usuarioId: authority.usuarioId, nome: authority.nome },
    });

    transaction.set(db.collection("academias").doc(academiaId).collection("auditoria").doc(), {
      tipo: "exclusao_turma",
      alvo: { turmaId, nome: turmaData.nome || "" },
      matriculas_encerradas: matriculasSnap.size,
      realizado_por: {
        uid: request.auth.uid,
        usuarioId: authority.usuarioId,
        nome: authority.nome,
        perfil: authority.perfil,
      },
      criado_em: FieldValue.serverTimestamp(),
    });

    return matriculasSnap.size;
  });

  logger.info("Turma excluída (soft delete)", {
    academiaId,
    turmaId,
    realizadoPor: request.auth.uid,
    matriculasEncerradas,
  });

  return { ok: true, matriculasEncerradas };
});

exports._test = { loadDeleterAuthority };
