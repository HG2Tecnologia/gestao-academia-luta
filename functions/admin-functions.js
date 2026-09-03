"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");
const { FieldValue } = require("firebase-admin/firestore");
const { generateTemporaryPassword } = require("./domain/temp-password");

const db = admin.firestore();
const auth = admin.auth();
const IDENTITY_FUNCTION_OPTIONS = {
  serviceAccount: "identity-functions@sensei-manager-d64c0.iam.gserviceaccount.com",
};

const RESETTABLE_ROLES = new Set(["Admin", "Secretaria"]);

/**
 * Verifica, a partir do schema v2 (fonte de verdade server-side, nunca do
 * cliente), se quem está chamando é Admin — ou Secretaria com a permissão
 * granular `acesso_redefinir_senha` — na academia informada. Retorna null quando
 * não autorizado.
 */
async function loadCallerAuthority(callerUid, academiaId) {
  const accountSnap = await db.collection("usuariosFirebase").doc(callerUid).get();
  const account = accountSnap.data();
  if (!account) return null;

  // O dono/gestor que criou a academia é Admin dentro de `usuarios`, não de
  // `funcionarios` — só quem é adicionado depois pela tela de Equipe vira
  // `funcionarios`. Por isso o Admin não fica restrito à coleção aqui; só a
  // permissão granular de Secretaria (abaixo) exige o cadastro em `funcionarios`.
  const refs = Array.isArray(account.profile_refs) ? account.profile_refs : [];
  const staffRef = refs.find(
    (ref) => ref.academiaId === academiaId && RESETTABLE_ROLES.has(ref.perfil_nome),
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
  if (funcSnap.data()?.permissoes?.acesso_redefinir_senha !== true) return null;

  return { usuarioId: staffRef.usuarioId, nome: staffRef.nome, perfil: "Secretaria" };
}

exports.adminResetPassword = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "É necessário autenticar antes de redefinir uma senha.");
  }

  const academiaId = String(request.data?.academiaId ?? "").trim();
  const colecao = request.data?.colecao === "funcionarios" ? "funcionarios" : "usuarios";
  const usuarioId = String(request.data?.usuarioId ?? "").trim();
  if (!academiaId || !usuarioId) {
    throw new HttpsError("invalid-argument", "Informe a academia e o perfil a redefinir.");
  }

  const authority = await loadCallerAuthority(request.auth.uid, academiaId);
  if (!authority) {
    throw new HttpsError(
      "permission-denied",
      "Você não tem permissão para redefinir senhas nesta academia.",
    );
  }

  const targetRef = db
    .collection("academias").doc(academiaId)
    .collection(colecao).doc(usuarioId);
  const targetSnap = await targetRef.get();
  if (!targetSnap.exists) {
    throw new HttpsError("not-found", "Perfil não encontrado.");
  }
  const targetData = targetSnap.data();
  const targetUid = targetData.firebaseUid || targetData.firebase_uid;
  if (!targetUid) {
    throw new HttpsError(
      "failed-precondition",
      "Esta pessoa ainda não ativou o acesso ao app — não há senha para redefinir.",
    );
  }
  if (targetUid === request.auth.uid) {
    throw new HttpsError("failed-precondition", 'Use "Alterar senha" no seu próprio perfil.');
  }

  const temporaryPassword = generateTemporaryPassword((max) => crypto.randomInt(max));

  // Atualiza a credencial e revoga qualquer sessão anterior — a pessoa
  // precisa entrar de novo com a senha temporária.
  await auth.updateUser(targetUid, { password: temporaryPassword });
  await auth.revokeRefreshTokens(targetUid);

  // Nunca persiste a senha em texto claro: só a flag e a data.
  await db.collection("usuariosFirebase").doc(targetUid).set(
    {
      must_change_password: true,
      must_change_password_at: FieldValue.serverTimestamp(),
      must_change_password_by: { uid: request.auth.uid, nome: authority.nome },
    },
    { merge: true },
  );

  await db.collection("academias").doc(academiaId).collection("auditoria").add({
    tipo: "redefinicao_senha",
    alvo: { colecao, usuarioId, nome: targetData.nome || "" },
    realizado_por: {
      uid: request.auth.uid,
      usuarioId: authority.usuarioId,
      nome: authority.nome,
      perfil: authority.perfil,
    },
    criado_em: FieldValue.serverTimestamp(),
  });

  logger.info("Senha redefinida por administrador", {
    academiaId,
    colecao,
    usuarioId,
    realizadoPor: request.auth.uid,
  });

  // A senha só existe nesta resposta, exibida uma única vez ao chamador.
  return { temporaryPassword, nome: targetData.nome || "" };
});

exports.completeMandatoryPasswordChange = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "Sessão inválida.");
  }

  await db.collection("usuariosFirebase").doc(request.auth.uid).set(
    {
      must_change_password: false,
      must_change_password_completed_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { ok: true };
});

exports._test = { loadCallerAuthority };
