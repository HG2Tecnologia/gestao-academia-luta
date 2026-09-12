"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");
const { FieldValue } = require("firebase-admin/firestore");
const { generateTemporaryPassword } = require("./domain/temp-password");
const { syntheticAuthEmails, profileKey } = require("./domain/account");
const {
  loginIdentifiers,
  primaryLoginEmail,
  identityForAuthEmail,
  loginHint,
  decidirAcaoContasCompartilhadas,
} = require("./domain/access-provisioning");
const { findProfiles, upsertAccount } = require("./account-functions");

const db = admin.firestore();
const auth = admin.auth();
const IDENTITY_FUNCTION_OPTIONS = {
  serviceAccount: "identity-functions@sensei-manager-d64c0.iam.gserviceaccount.com",
};

const RESETTABLE_ROLES = new Set(["Admin", "Secretaria"]);
const MOTIVOS = new Set(["redefinicao", "provisao_criacao", "provisao_edicao"]);

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

/**
 * Descobre TODAS as contas do Firebase Auth alcançáveis a partir dos
 * identificadores (telefone/e-mail) do perfil alvo — inclusive as de outros
 * cadastros que compartilham o mesmo telefone/e-mail. O objetivo é redefinir a
 * senha em todas de uma vez: a pessoa pode logar por qualquer uma delas.
 */
async function collectRelatedUids(targetData) {
  const { realEmail, phoneCanonical, authEmails } = loginIdentifiers(targetData);
  const uids = new Set();

  const docUid = targetData.firebaseUid || targetData.firebase_uid;
  if (docUid) uids.add(docUid);

  // 1. Contas Auth pelos e-mails de login (real + sintéticos do telefone).
  for (const email of authEmails) {
    try {
      const user = await auth.getUserByEmail(email);
      if (user) uids.add(user.uid);
    } catch (error) {
      if (error.code !== "auth/user-not-found") throw error;
    }
  }

  // 2. Outros perfis (usuarios/funcionarios) que compartilham o mesmo
  //    telefone/e-mail — cada um pode apontar para uma conta Auth diferente
  //    (o cenário quebrado que queremos costurar). Reaproveita a busca já
  //    testada do fluxo de identidade.
  for (const identifier of [phoneCanonical, realEmail].filter(Boolean)) {
    try {
      const { profiles } = await findProfiles(identifier);
      for (const profile of profiles) {
        if (profile.firebaseUid) uids.add(profile.firebaseUid);
      }
    } catch (error) {
      if (error.code !== "invalid-argument") throw error;
    }
  }

  return { uids: [...uids], realEmail, phoneCanonical, authEmails };
}

/**
 * Vincula o perfil `academias/{academiaId}/{colecao}/{usuarioId}` à conta Auth
 * `uid` e garante o documento `usuariosFirebase/{uid}` (schema v2). Tenta o
 * `upsertAccount` transacional (que costura o grupo familiar inteiro); se ele
 * bater em conflito de identidade legado, faz o vínculo mínimo só deste perfil
 * e registra um aviso.
 */
async function linkProfileToAccount({ uid, authUserEmail, academiaId, colecao, usuarioId, targetData, realEmail, phoneCanonical }) {
  const identity = identityForAuthEmail(authUserEmail) || realEmail || phoneCanonical;
  const preferredKey = profileKey({ academiaId, colecao, usuarioId });
  if (identity) {
    try {
      await upsertAccount(uid, authUserEmail, identity, preferredKey);
      return;
    } catch (error) {
      if (error.code !== "failed-precondition" && error.code !== "permission-denied") throw error;
      logger.warn("upsertAccount não pôde costurar o grupo; vínculo mínimo aplicado", {
        uid, academiaId, colecao, usuarioId, motivo: error.message,
      });
    }
  }

  // Vínculo mínimo: só este perfil.
  const perfilNome = colecao === "funcionarios" ? "Professor" : "Aluno";
  const ref = db.collection("academias").doc(academiaId).collection(colecao).doc(usuarioId);
  await ref.set({
    firebaseUid: uid,
    conta_ativa: true,
    auth_account_schema_version: 2,
    atualizado_em: FieldValue.serverTimestamp(),
  }, { merge: true });

  const accRef = db.collection("usuariosFirebase").doc(uid);
  const existing = (await accRef.get()).data() || {};
  const newRef = {
    key: preferredKey, academiaId, colecao, usuarioId,
    perfil_nome: perfilNome, nome: String(targetData.nome || ""),
  };
  const refs = (Array.isArray(existing.profile_refs) ? existing.profile_refs : [])
    .filter((r) => r && r.key !== preferredKey);
  refs.push(newRef);
  await accRef.set({
    schemaVersion: 2,
    uid,
    status: "active",
    primary_profile_key: existing.primary_profile_key || preferredKey,
    profile_keys: refs.map((r) => r.key),
    profile_refs: refs,
    academiaId: existing.academiaId || academiaId,
    usuarioId: existing.usuarioId || usuarioId,
    colecao: existing.colecao || colecao,
    perfil: existing.perfil || perfilNome,
    nome: existing.nome || newRef.nome,
    ...(realEmail ? { email: realEmail, email_canonical: realEmail } : {}),
    ...(phoneCanonical ? { phone_canonical: phoneCanonical } : {}),
    criado_em: existing.criado_em || FieldValue.serverTimestamp(),
    atualizado_em: FieldValue.serverTimestamp(),
  }, { merge: true });
}

/**
 * Cria (ou reaproveita) a conta Auth do contato e aplica a senha temporária.
 * Retorna o uid usado.
 */
async function provisionAccount({ academiaId, colecao, usuarioId, targetData, realEmail, phoneCanonical, temporaryPassword }) {
  const loginEmail = primaryLoginEmail({ realEmail, phoneCanonical });
  if (!loginEmail) {
    throw new HttpsError(
      "failed-precondition",
      "Cadastre um telefone ou e-mail para o aluno antes de gerar o acesso ao app.",
    );
  }

  // Reaproveita conta existente (irmão no mesmo número, corrida, recadastro).
  const candidates = new Set([loginEmail, ...syntheticAuthEmails(phoneCanonical || ""), realEmail].filter(Boolean));
  let uid = null;
  for (const email of candidates) {
    try {
      const user = await auth.getUserByEmail(email);
      if (user) { uid = user.uid; break; }
    } catch (error) {
      if (error.code !== "auth/user-not-found") throw error;
    }
  }

  let authUserEmail = loginEmail;
  if (uid) {
    authUserEmail = (await auth.getUser(uid)).email || loginEmail;
    await auth.updateUser(uid, { password: temporaryPassword });
    await auth.revokeRefreshTokens(uid);
  } else {
    const created = await auth.createUser({
      email: loginEmail,
      password: temporaryPassword,
      displayName: targetData.nome ? String(targetData.nome).slice(0, 60) : undefined,
    });
    uid = created.uid;
  }

  await linkProfileToAccount({
    uid, authUserEmail, academiaId, colecao, usuarioId, targetData, realEmail, phoneCanonical,
  });

  return uid;
}

async function marcarTrocaObrigatoria(uid, authorityNome, callerUid) {
  await db.collection("usuariosFirebase").doc(uid).set({
    must_change_password: true,
    must_change_password_at: FieldValue.serverTimestamp(),
    must_change_password_by: { uid: callerUid, nome: authorityNome },
  }, { merge: true });
}

/**
 * Redefine (ou provisiona) a senha de acesso ao app de um aluno/funcionário.
 *
 * - Gera UMA senha temporária e aplica em TODAS as contas Auth do contato
 *   (e-mail real + sintéticos de telefone + contas de outros cadastros com o
 *   mesmo telefone/e-mail). Assim a pessoa entra por telefone OU e-mail.
 * - Se o contato ainda não tem nenhuma conta, cria uma (ou vincula à conta de
 *   um irmão que já exista) — é o fluxo usado quando a academia cadastra o
 *   aluno ou adiciona um telefone/e-mail depois.
 * - Marca `must_change_password` para forçar a troca no primeiro login.
 *
 * A senha só existe na resposta; nunca é persistida em texto claro.
 */
exports.adminResetPassword = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "É necessário autenticar antes de redefinir uma senha.");
  }

  const academiaId = String(request.data?.academiaId ?? "").trim();
  const colecao = request.data?.colecao === "funcionarios" ? "funcionarios" : "usuarios";
  const usuarioId = String(request.data?.usuarioId ?? "").trim();
  const motivo = MOTIVOS.has(request.data?.motivo) ? request.data.motivo : "redefinicao";
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

  const { uids, realEmail, phoneCanonical, authEmails } = await collectRelatedUids(targetData);

  if (uids.length === 1 && uids[0] === request.auth.uid) {
    throw new HttpsError("failed-precondition", 'Use "Alterar senha" no seu próprio perfil.');
  }
  if (authEmails.length === 0 && uids.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "Cadastre um telefone ou e-mail para o aluno antes de gerar o acesso ao app.",
    );
  }

  const alvo = uids.filter((uid) => uid !== request.auth.uid);
  const docUid = targetData.firebaseUid || targetData.firebase_uid;
  // "outros" são contas de OUTROS cadastros que caíram no grupo só por
  // coincidência/erro de telefone-e-mail — a própria conta do alvo (se já
  // provisionada) não conta como conflito.
  const outros = alvo.filter((uid) => uid !== docUid);

  const confirmarSobrescrita = request.data?.confirmarSobrescrita === true;
  const apenasVincular = request.data?.apenasVincular === true;

  // Bug reportado: cadastrar um aluno novo com o mesmo telefone/e-mail de
  // outro que já tinha definido a própria senha derrubava o acesso de ambos
  // (a senha temporária nova sobrescrevia a conta compartilhada sem avisar).
  // Só checamos isso no provisionamento automático (criação/edição) — nunca
  // num clique explícito em "Redefinir senha", que já é intencional.
  let algumJaDefiniuSenha = false;
  if (outros.length > 0 && motivo !== "redefinicao" && !confirmarSobrescrita && !apenasVincular) {
    const contas = await Promise.all(
      outros.map((uid) => db.collection("usuariosFirebase").doc(uid).get()),
    );
    algumJaDefiniuSenha = contas.some((snap) => snap.data()?.must_change_password === false);
  }

  const acao = decidirAcaoContasCompartilhadas({
    motivo, confirmarSobrescrita, apenasVincular, algumJaDefiniuSenha,
  });

  if (acao === "bloquear") {
    throw new HttpsError(
      "failed-precondition",
      "Já existe outra pessoa cadastrada com esse telefone ou e-mail, e ela já definiu a própria senha de acesso.",
      { code: "senha_ja_definida", contas: outros.length },
    );
  }

  const contasAtingidas = [];
  let temporaryPassword = "";

  if (acao === "vincular_sem_senha") {
    // A academia escolheu não mexer na senha de quem já tem uma — só vincula
    // este perfil novo à conta existente (compartilham o mesmo login).
    const uidExistente = outros[0] || alvo[0];
    const authUserEmail = (await auth.getUser(uidExistente)).email
      || primaryLoginEmail({ realEmail, phoneCanonical });
    await linkProfileToAccount({
      uid: uidExistente, authUserEmail, academiaId, colecao, usuarioId, targetData, realEmail, phoneCanonical,
    });
    contasAtingidas.push(uidExistente);
  } else {
    temporaryPassword = generateTemporaryPassword((max) => crypto.randomInt(max));
    if (alvo.length === 0) {
      // Ninguém ainda tem acesso — provisiona.
      const uid = await provisionAccount({
        academiaId, colecao, usuarioId, targetData, realEmail, phoneCanonical, temporaryPassword,
      });
      await marcarTrocaObrigatoria(uid, authority.nome, request.auth.uid);
      contasAtingidas.push(uid);
    } else {
      for (const uid of alvo) {
        await auth.updateUser(uid, { password: temporaryPassword });
        await auth.revokeRefreshTokens(uid);
        await marcarTrocaObrigatoria(uid, authority.nome, request.auth.uid);
        contasAtingidas.push(uid);
      }
      // O perfil alvo não estava vinculado a nenhuma conta, mas achamos uma
      // (irmão) — vincula para o login desse perfil funcionar.
      if (!docUid) {
        const uid = alvo[0];
        const authUserEmail = (await auth.getUser(uid)).email || primaryLoginEmail({ realEmail, phoneCanonical });
        await linkProfileToAccount({
          uid, authUserEmail, academiaId, colecao, usuarioId, targetData, realEmail, phoneCanonical,
        });
      }
    }

    // A senha temporária fica visível para a academia na ficha do aluno até
    // ele entrar pela primeira vez e definir a própria senha (quando
    // `completeMandatoryPasswordChange` a apaga). É forçada a trocar no 1º login.
    await targetRef.set({
      acesso_senha_temporaria: temporaryPassword,
      acesso_senha_temporaria_em: FieldValue.serverTimestamp(),
      acesso_senha_temporaria_por: authority.nome,
    }, { merge: true });
  }

  await db.collection("academias").doc(academiaId).collection("auditoria").add({
    tipo: acao === "vincular_sem_senha" ? "vinculo_acesso_sem_senha" : "redefinicao_senha",
    motivo,
    alvo: { colecao, usuarioId, nome: targetData.nome || "" },
    contas_atingidas: contasAtingidas.length,
    realizado_por: {
      uid: request.auth.uid,
      usuarioId: authority.usuarioId,
      nome: authority.nome,
      perfil: authority.perfil,
    },
    criado_em: FieldValue.serverTimestamp(),
  });

  logger.info("Senha de acesso redefinida/provisionada", {
    academiaId, colecao, usuarioId, motivo, acao,
    contasAtingidas: contasAtingidas.length,
    realizadoPor: request.auth.uid,
  });

  return {
    temporaryPassword,
    nome: targetData.nome || "",
    loginHint: loginHint({ realEmail, phoneCanonical }, targetData.telefone),
    contas: contasAtingidas.length,
    vinculadoSemSenha: acao === "vincular_sem_senha",
  };
});

/**
 * Verificação PRÉVIA (sem criar/editar nada), usada antes de cadastrar um
 * aluno: diz se o telefone/e-mail informado já pertence a outra conta que já
 * completou o primeiro acesso. Existe pra academia poder decidir ANTES de o
 * cadastro ser criado — cancelar aqui não deixa rastro nenhum, diferente de
 * cancelar depois do aluno já existir no banco.
 */
exports.checkContatoCompartilhado = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "É necessário autenticar para esta verificação.");
  }

  const academiaId = String(request.data?.academiaId ?? "").trim();
  if (!academiaId) {
    throw new HttpsError("invalid-argument", "Informe a academia.");
  }
  const authority = await loadCallerAuthority(request.auth.uid, academiaId);
  if (!authority) {
    throw new HttpsError("permission-denied", "Você não tem permissão para esta ação nesta academia.");
  }

  const telefone = String(request.data?.telefone ?? "").trim();
  const email = String(request.data?.email ?? "").trim();
  if (!telefone && !email) return { conflito: false, contas: 0 };

  const { uids } = await collectRelatedUids({ telefone, email });
  const outros = uids.filter((uid) => uid !== request.auth.uid);
  if (outros.length === 0) return { conflito: false, contas: 0 };

  const contas = await Promise.all(
    outros.map((uid) => db.collection("usuariosFirebase").doc(uid).get()),
  );
  const conflito = contas.some((snap) => snap.data()?.must_change_password === false);
  return { conflito, contas: outros.length };
});

exports.completeMandatoryPasswordChange = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "Sessão inválida.");
  }

  const accRef = db.collection("usuariosFirebase").doc(request.auth.uid);
  const accSnap = await accRef.get();
  await accRef.set(
    {
      must_change_password: false,
      must_change_password_completed_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  // Agora que a pessoa definiu a própria senha, some com a temporária das
  // fichas dos perfis vinculados — a academia deixa de ver aquela senha.
  const acc = accSnap.data() || {};
  const refs = Array.isArray(acc.profile_refs) && acc.profile_refs.length > 0
    ? acc.profile_refs
    : (acc.academiaId && acc.usuarioId
      ? [{ academiaId: acc.academiaId, colecao: acc.colecao || "usuarios", usuarioId: acc.usuarioId }]
      : []);
  await Promise.all(refs.map((ref) => {
    const colecao = ref.colecao === "funcionarios" ? "funcionarios" : "usuarios";
    return db
      .collection("academias").doc(String(ref.academiaId))
      .collection(colecao).doc(String(ref.usuarioId))
      .set({
        acesso_senha_temporaria: FieldValue.delete(),
        acesso_senha_temporaria_em: FieldValue.delete(),
        acesso_senha_temporaria_por: FieldValue.delete(),
      }, { merge: true })
      .catch(() => {});
  }));

  return { ok: true };
});

exports._test = { loadCallerAuthority, collectRelatedUids, provisionAccount, linkProfileToAccount };
