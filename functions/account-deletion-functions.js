"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { profileRole, removeAcademyProfiles, removeProfileRef } = require("./domain/account");

const db = admin.firestore();
const auth = admin.auth();
const IDENTITY_FUNCTION_OPTIONS = {
  serviceAccount: "identity-functions@sensei-manager-d64c0.iam.gserviceaccount.com",
  timeoutSeconds: 540,
  memory: "512MiB",
};

/** Compara nomes ignorando caixa e espaços extras. */
function normalizarNome(value) {
  return String(value ?? "").trim().replace(/\s+/g, " ").toLocaleLowerCase("pt-BR");
}

async function apagarUsuarioAuth(uid) {
  try {
    await auth.deleteUser(uid);
    return true;
  } catch (error) {
    if (error.code === "auth/user-not-found") return true;
    logger.warn("Falha ao apagar usuário do Firebase Auth", { uid, error: error.message });
    return false;
  }
}

/**
 * Outros Admins ativos da academia, com login vinculado (sem login ninguém
 * conseguiria administrar a academia depois). Admins podem estar em
 * `usuarios` (cadastro inicial, `perfil: 0` legado ou `perfil_nome`) ou em
 * `funcionarios` (`perfil: "Admin"`).
 */
async function outrosAdmins(academiaId, proprio) {
  const academiaRef = db.collection("academias").doc(academiaId);
  const consultas = [
    academiaRef.collection("usuarios").where("perfil_nome", "==", "Admin"),
    academiaRef.collection("usuarios").where("perfil", "==", 0),
    academiaRef.collection("usuarios").where("perfil", "==", "Admin"),
    academiaRef.collection("funcionarios").where("perfil", "==", "Admin"),
    academiaRef.collection("funcionarios").where("perfil_nome", "==", "Admin"),
  ];
  const docs = new Map();
  for (const snap of await Promise.all(consultas.map((q) => q.get()))) {
    for (const doc of snap.docs) docs.set(doc.ref.path, doc);
  }

  return [...docs.values()].filter((doc) => {
    const colecao = doc.ref.parent.id;
    if (colecao === proprio.colecao && doc.id === proprio.usuarioId) return false;
    const data = doc.data();
    return data.ativo !== false
      && profileRole(colecao, data) === "Admin"
      && Boolean(data.firebaseUid || data.firebase_uid);
  });
}

/** Contas de acesso com algum perfil na academia (schema v2 e legado v1). */
async function contasDaAcademia(academiaId) {
  const contas = db.collection("usuariosFirebase");
  const [v2, v1] = await Promise.all([
    contas.where("academy_ids", "array-contains", academiaId).get(),
    contas.where("academiaId", "==", academiaId).get(),
  ]);
  const docs = new Map();
  for (const doc of [...v2.docs, ...v1.docs]) docs.set(doc.id, doc);
  return [...docs.values()];
}

/**
 * Tira da conta os perfis da academia; se não sobrar nenhum, apaga a conta e
 * o login. Retorna `true` quando o login foi apagado.
 */
async function desvincularConta(doc, academiaId) {
  const resultado = removeAcademyProfiles(doc.data(), academiaId);
  if (!resultado.deleted) {
    await doc.ref.update(resultado.data);
    return false;
  }
  await doc.ref.delete();
  return apagarUsuarioAuth(doc.id);
}

/** Há outro Admin: remove só o perfil de quem pediu a exclusão. */
async function excluirSoPerfil({ uid, conta, perfil, academiaId }) {
  const academiaRef = db.collection("academias").doc(academiaId);
  await academiaRef.collection("auditoria").doc().set({
    tipo: "exclusao_conta_admin",
    alvo: { usuarioId: perfil.usuarioId, colecao: perfil.colecao, nome: perfil.nome || "" },
    realizado_por: { uid, usuarioId: perfil.usuarioId, nome: perfil.nome || "", perfil: "Admin" },
    criado_em: FieldValue.serverTimestamp(),
  });
  await academiaRef.collection(perfil.colecao).doc(perfil.usuarioId).delete();

  const resultado = removeProfileRef(conta, perfil.key);
  let loginApagado = false;
  if (resultado.deleted) {
    await db.collection("usuariosFirebase").doc(uid).delete();
    loginApagado = await apagarUsuarioAuth(uid);
  } else {
    await db.collection("usuariosFirebase").doc(uid).update(resultado.data);
  }
  return { modo: "perfil", loginApagado };
}

/**
 * Único Admin: apaga a academia inteira (doc + todas as subcoleções) e
 * desvincula todas as contas de acesso dela, apagando os logins que não têm
 * perfil em nenhuma outra academia. Idempotente: se uma tentativa anterior
 * parou no meio, chamar de novo termina o serviço.
 */
async function excluirAcademia({ uid, academiaId }) {
  const academiaRef = db.collection("academias").doc(academiaId);
  await db.recursiveDelete(academiaRef);

  const contas = await contasDaAcademia(academiaId);
  let loginsApagados = 0;
  let loginApagado = false;
  // A conta de quem pediu vai por último: se algo falhar antes, ela ainda
  // tem o perfil Admin e pode repetir a chamada pra terminar a limpeza.
  const ordenadas = [...contas.filter((d) => d.id !== uid), ...contas.filter((d) => d.id === uid)];
  for (const doc of ordenadas) {
    const apagou = await desvincularConta(doc, academiaId);
    if (apagou) loginsApagados++;
    if (doc.id === uid) loginApagado = apagou;
  }
  return { modo: "academia", loginApagado, contasDesvinculadas: contas.length, loginsApagados };
}

exports.excluirMinhaConta = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "É necessário autenticar antes de excluir a conta.");
  }
  const uid = request.auth.uid;
  const academiaId = String(request.data?.academiaId ?? "").trim();
  if (!academiaId) throw new HttpsError("invalid-argument", "Informe a academia.");

  const contaSnap = await db.collection("usuariosFirebase").doc(uid).get();
  const conta = contaSnap.data();
  const refs = Array.isArray(conta?.profile_refs) ? conta.profile_refs : [];
  const perfil = refs.find((ref) => ref.academiaId === academiaId && ref.perfil_nome === "Admin");
  if (!perfil) {
    throw new HttpsError("permission-denied", "Só o administrador da academia pode excluir esta conta.");
  }

  const academiaSnap = await db.collection("academias").doc(academiaId).get();
  if (academiaSnap.exists) {
    const nome = academiaSnap.data()?.nome;
    if (normalizarNome(request.data?.confirmacaoNome) !== normalizarNome(nome)) {
      throw new HttpsError("failed-precondition", "O nome digitado não confere com o nome da academia.");
    }
    const outros = await outrosAdmins(academiaId, perfil);
    if (outros.length > 0) {
      const resultado = await excluirSoPerfil({ uid, conta, perfil, academiaId });
      logger.info("Conta de admin excluída (academia mantida)", { academiaId, uid, ...resultado });
      return { ok: true, ...resultado };
    }
  }

  // Academia já apagada numa tentativa anterior: só termina a limpeza.
  const resultado = await excluirAcademia({ uid, academiaId });
  logger.info("Academia excluída pelo admin", { academiaId, uid, ...resultado });
  return { ok: true, ...resultado };
});

exports._test = { normalizarNome };
