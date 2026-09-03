"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { canonicalizePhone, canonicalPhoneDigits } = require("./domain/phone-normalizer");
const {
  authEmailMatchesIdentifier,
  buildAccountDocument,
  canonicalizeEmail,
  identityFromAuthEmail,
  profileKey,
  profileRole,
  syntheticAuthEmails,
} = require("./domain/account");

const db = admin.firestore();
const auth = admin.auth();
const IDENTITY_FUNCTION_OPTIONS = {
  serviceAccount: "identity-functions@sensei-manager-d64c0.iam.gserviceaccount.com",
};

function publicProfile(profile) {
  return {
    profileKey: profile.key,
    usuarioId: profile.usuarioId,
    academiaId: profile.academiaId,
    academiaNome: profile.academiaNome || "",
    colecao: profile.colecao,
    perfil_nome: profile.perfil_nome,
    nome: profile.nome,
  };
}

function phoneQueryValues(value) {
  const canonicalDigits = canonicalPhoneDigits(value);
  if (!canonicalDigits) return [];
  const values = new Set([canonicalDigits]);
  if (canonicalDigits.startsWith("55")) values.add(canonicalDigits.slice(2));
  return [...values];
}

function legacyPhoneValues(value) {
  const canonicalDigits = canonicalPhoneDigits(value);
  if (!canonicalDigits || !canonicalDigits.startsWith("55")) return [];
  const national = canonicalDigits.slice(2);
  const values = new Set([national, canonicalDigits, `+${canonicalDigits}`]);
  if (national.length === 11) {
    values.add(`(${national.slice(0, 2)}) ${national.slice(2, 7)}-${national.slice(7)}`);
  } else if (national.length === 10) {
    values.add(`(${national.slice(0, 2)}) ${national.slice(2, 6)}-${national.slice(6)}`);
  }
  return [...values];
}

function profileMatchesIdentity(data, identity) {
  if (identity.type === "email") {
    return canonicalizeEmail(data.email) === identity.value;
  }
  return [data.telefone_canonical, data.telefone, data.telefone_digits]
    .some((value) => canonicalizePhone(value) === identity.value);
}

async function findProfiles(identifier) {
  const raw = String(identifier ?? "").trim();
  const identity = raw.includes("@")
    ? { type: "email", value: canonicalizeEmail(raw) }
    : { type: "phone", value: canonicalizePhone(raw) };
  if (!identity.value) throw new HttpsError("invalid-argument", "E-mail ou telefone inválido.");

  const docs = new Map();
  const addQuery = async (collection, field, value) => {
    if (!value) return;
    const snap = await db.collectionGroup(collection).where(field, "==", value).get();
    for (const doc of snap.docs) docs.set(doc.ref.path, doc);
  };

  if (identity.type === "email") {
    await Promise.all([
      addQuery("usuarios", "email", identity.value),
      addQuery("funcionarios", "email", identity.value),
    ]);
  } else {
    const digits = phoneQueryValues(identity.value);
    const queries = [];
    for (const value of digits) {
      queries.push(addQuery("usuarios", "telefone_digits", value));
      queries.push(addQuery("funcionarios", "telefone_digits", value));
    }
    for (const value of legacyPhoneValues(identity.value)) {
      queries.push(addQuery("usuarios", "telefone", value));
      queries.push(addQuery("funcionarios", "telefone", value));
    }
    queries.push(addQuery("usuarios", "telefone_canonical", identity.value));
    queries.push(addQuery("funcionarios", "telefone_canonical", identity.value));
    await Promise.all(queries);
  }

  const academyNames = new Map();
  const profiles = [];
  for (const doc of docs.values()) {
    const data = doc.data();
    if (data.ativo === false || !profileMatchesIdentity(data, identity)) continue;

    const colecao = doc.ref.parent.id;
    const academiaId = doc.ref.parent.parent?.id;
    if (!academiaId) continue;
    const perfilNome = profileRole(colecao, data);
    if (!perfilNome) continue;

    if (!academyNames.has(academiaId)) {
      const academy = await db.collection("academias").doc(academiaId).get();
      academyNames.set(academiaId, academy.data()?.nome || "");
    }
    const profile = {
      academiaId,
      academiaNome: academyNames.get(academiaId),
      usuarioId: doc.id,
      colecao,
      perfil_nome: perfilNome,
      nome: String(data.nome || ""),
      firebaseUid: data.firebaseUid || data.firebase_uid || null,
      ref: doc.ref,
    };
    profile.key = profileKey(profile);
    profiles.push(profile);
  }

  profiles.sort((a, b) => a.key.localeCompare(b.key));
  return { identity, profiles };
}

async function authAccountExists(identity, rawIdentifier) {
  const candidates = identity.type === "email"
    ? [identity.value]
    : [...syntheticAuthEmails(identity.value), `${String(rawIdentifier).replace(/\D/g, "")}@sensei.app`];

  for (const email of new Set(candidates.filter(Boolean))) {
    try {
      const user = await auth.getUserByEmail(email);
      if (user) return true;
    } catch (error) {
      if (error.code !== "auth/user-not-found") throw error;
    }
  }
  return false;
}

async function upsertAccount(uid, authEmail, identifier, preferredProfileKey) {
  if (!authEmailMatchesIdentifier(authEmail, identifier)) {
    throw new HttpsError("permission-denied", "A credencial autenticada não corresponde ao contato informado.");
  }

  const { identity, profiles } = await findProfiles(identifier);
  if (profiles.length === 0) {
    throw new HttpsError("not-found", "Nenhum perfil ativo foi encontrado para esta conta.");
  }

  const accountRef = db.collection("usuariosFirebase").doc(uid);
  await db.runTransaction(async (transaction) => {
    const accountSnapshot = await transaction.get(accountRef);
    const currentAccount = accountSnapshot.data() || {};
    const verifiedProfiles = [];
    const conflicts = [];

    for (const candidate of profiles) {
      const snapshot = await transaction.get(candidate.ref);
      const data = snapshot.data();
      if (!snapshot.exists || data.ativo === false || !profileMatchesIdentity(data, identity)) continue;
      const linkedUid = data.firebaseUid || data.firebase_uid;
      if (linkedUid && linkedUid !== uid) {
        conflicts.push(candidate.key);
      } else {
        verifiedProfiles.push(candidate);
      }
    }

    if (conflicts.length > 0) {
      logger.warn("Conflito de identidade durante associação", { uid, profileKeys: conflicts });
      throw new HttpsError(
        "failed-precondition",
        "Há perfis vinculados a outra conta. A academia precisa revisar esse acesso.",
      );
    }

    const primaryProfileKey = preferredProfileKey || currentAccount.primary_profile_key;
    const account = buildAccountDocument({
      uid,
      profiles: verifiedProfiles,
      primaryProfileKey,
      emailCanonical: identity.type === "email" ? identity.value : null,
      phoneCanonical: identity.type === "phone" ? identity.value : null,
    });

    transaction.set(accountRef, {
      ...account,
      criado_em: currentAccount.criado_em || FieldValue.serverTimestamp(),
      atualizado_em: FieldValue.serverTimestamp(),
    }, { merge: true });

    for (const profile of verifiedProfiles) {
      transaction.update(profile.ref, {
        firebaseUid: uid,
        conta_ativa: true,
        auth_account_schema_version: 2,
        atualizado_em: FieldValue.serverTimestamp(),
      });
    }
  });

  const updated = await accountRef.get();
  return updated.data();
}

exports.discoverAccessProfiles = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  const identifier = String(request.data?.identifier ?? "").trim();
  const { identity, profiles } = await findProfiles(identifier);
  return {
    profiles: profiles.map(publicProfile),
    accountExists: await authAccountExists(identity, identifier),
  };
});

exports.activateAccessAccount = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "É necessário autenticar a conta antes de ativá-la.");
  }
  const identifier = String(request.data?.identifier ?? "").trim();
  const authEmail = request.auth.token.email;
  if (!authEmail) throw new HttpsError("failed-precondition", "A conta autenticada não possui e-mail de acesso.");

  const account = await upsertAccount(
    request.auth.uid,
    authEmail,
    identifier,
    request.data?.primaryProfileKey,
  );
  return { account };
});

exports.refreshAccessAccount = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "Sessão inválida.");
  }

  const accountSnapshot = await db.collection("usuariosFirebase").doc(request.auth.uid).get();
  const current = accountSnapshot.data() || {};
  const authIdentity = identityFromAuthEmail(request.auth.token.email);
  const identifier = current.phone_canonical || current.email_canonical || authIdentity?.value;
  if (!identifier) {
    throw new HttpsError("failed-precondition", "Não foi possível identificar o contato desta conta.");
  }

  const account = await upsertAccount(
    request.auth.uid,
    request.auth.token.email,
    identifier,
    current.primary_profile_key,
  );
  return { account };
});

exports._test = {
  findProfiles,
  legacyPhoneValues,
  phoneQueryValues,
  profileMatchesIdentity,
  upsertAccount,
};
