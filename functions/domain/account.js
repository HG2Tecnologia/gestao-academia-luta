"use strict";

const { canonicalizePhone, canonicalPhoneDigits } = require("./phone-normalizer");

const ACCOUNT_SCHEMA_VERSION = 2;
const PROFILE_NAMES = new Set(["Admin", "Secretaria", "Professor", "Aluno"]);
const LEGACY_PROFILE_NAMES = {
  0: "Admin",
  1: "Secretaria",
  2: "Professor",
  3: "Aluno",
};

function canonicalizeEmail(value) {
  const email = String(value ?? "").trim().toLowerCase();
  return email.includes("@") ? email : null;
}

function profileRole(collection, data) {
  const explicit = String(data.perfil_nome || "").trim();
  if (PROFILE_NAMES.has(explicit)) return explicit;
  if (typeof data.perfil === "string" && PROFILE_NAMES.has(data.perfil)) return data.perfil;
  if (collection === "usuarios" && Number.isInteger(data.perfil)) {
    return LEGACY_PROFILE_NAMES[data.perfil] || null;
  }
  return collection === "funcionarios" ? "Professor" : null;
}

function syntheticAuthEmails(value) {
  const canonical = canonicalPhoneDigits(value);
  if (!canonical) return [];

  const candidates = new Set([`${canonical}@sensei.app`]);
  if (canonical.startsWith("55") && (canonical.length === 12 || canonical.length === 13)) {
    candidates.add(`${canonical.slice(2)}@sensei.app`);
  }
  return [...candidates];
}

function profileKey({ academiaId, colecao, usuarioId }) {
  if (!academiaId || !colecao || !usuarioId) {
    throw new TypeError("Referência de perfil incompleta.");
  }
  return `${academiaId}|${colecao}|${usuarioId}`;
}

function normalizeProfileRef(profile) {
  const ref = {
    key: profile.key || profileKey(profile),
    academiaId: String(profile.academiaId),
    usuarioId: String(profile.usuarioId),
    colecao: profile.colecao === "funcionarios" ? "funcionarios" : "usuarios",
    perfil_nome: String(profile.perfil_nome || "Aluno"),
    nome: String(profile.nome || ""),
  };
  return ref;
}

function dedupeProfileRefs(profiles) {
  const byKey = new Map();
  for (const profile of profiles) {
    const normalized = normalizeProfileRef(profile);
    byKey.set(normalized.key, normalized);
  }
  return [...byKey.values()].sort((a, b) => a.key.localeCompare(b.key));
}

function buildAccountDocument({
  uid,
  profiles,
  primaryProfileKey,
  emailCanonical,
  phoneCanonical,
}) {
  const refs = dedupeProfileRefs(profiles);
  if (refs.length === 0) throw new TypeError("A conta precisa possuir ao menos um perfil.");

  const primary = refs.find((profile) => profile.key === primaryProfileKey) || refs[0];
  const rolesByAcademy = {};
  for (const profile of refs) {
    rolesByAcademy[profile.academiaId] ??= [];
    if (!rolesByAcademy[profile.academiaId].includes(profile.perfil_nome)) {
      rolesByAcademy[profile.academiaId].push(profile.perfil_nome);
      rolesByAcademy[profile.academiaId].sort();
    }
  }

  return {
    schemaVersion: ACCOUNT_SCHEMA_VERSION,
    uid,
    status: "active",
    primary_profile_key: primary.key,
    profile_keys: refs.map((profile) => profile.key),
    profile_refs: refs,
    academy_ids: Object.keys(rolesByAcademy).sort(),
    roles_by_academy: rolesByAcademy,
    ...(emailCanonical ? { email_canonical: canonicalizeEmail(emailCanonical) } : {}),
    ...(phoneCanonical ? { phone_canonical: canonicalizePhone(phoneCanonical) } : {}),

    // Compatibilidade temporária com versões publicadas antes do schema v2.
    academiaId: primary.academiaId,
    usuarioId: primary.usuarioId,
    colecao: primary.colecao,
    perfil: primary.perfil_nome,
    nome: primary.nome,
    email: canonicalizeEmail(emailCanonical) || "",
    perfis: refs,
  };
}

/**
 * Remove UM `profile_ref` (pelo `key`) de uma conta compartilhada, sem afetar
 * os demais perfis — usado ao excluir um aluno cujo telefone/e-mail é
 * compartilhado com outro aluno (ex.: irmãos com o mesmo responsável), pra
 * não derrubar o acesso de quem continua ativo. Pura, sem Firestore, pra
 * poder testar sem emulador.
 *
 * Retorna `{ deleted: true }` quando o perfil removido era o único (a conta
 * inteira deve ser apagada); caso contrário `{ deleted: false, data }` com os
 * campos recalculados (profile_refs, profile_keys, academy_ids,
 * roles_by_academy, primary_profile_key e os campos de compatibilidade v1).
 */
function removeProfileRef(account, keyToRemove) {
  const refs = (Array.isArray(account.profile_refs) ? account.profile_refs : [])
    .filter((ref) => ref.key !== keyToRemove);

  if (refs.length === 0) return { deleted: true };

  const rolesByAcademy = {};
  for (const profile of refs) {
    rolesByAcademy[profile.academiaId] ??= [];
    if (!rolesByAcademy[profile.academiaId].includes(profile.perfil_nome)) {
      rolesByAcademy[profile.academiaId].push(profile.perfil_nome);
      rolesByAcademy[profile.academiaId].sort();
    }
  }

  const primaryAindaValido = refs.some((ref) => ref.key === account.primary_profile_key);
  const primary = primaryAindaValido
    ? refs.find((ref) => ref.key === account.primary_profile_key)
    : refs[0];

  return {
    deleted: false,
    data: {
      profile_refs: refs,
      profile_keys: refs.map((ref) => ref.key),
      academy_ids: Object.keys(rolesByAcademy).sort(),
      roles_by_academy: rolesByAcademy,
      primary_profile_key: primary.key,
      // Compatibilidade v1, mesmo formato de `buildAccountDocument`.
      academiaId: primary.academiaId,
      usuarioId: primary.usuarioId,
      colecao: primary.colecao,
      perfil: primary.perfil_nome,
      nome: primary.nome,
      perfis: refs,
    },
  };
}

function identityFromAuthEmail(authEmail) {
  const email = canonicalizeEmail(authEmail);
  if (!email) return null;
  if (!email.endsWith("@sensei.app")) {
    return { type: "email", value: email };
  }

  const phone = canonicalizePhone(email.slice(0, -"@sensei.app".length));
  return phone ? { type: "phone", value: phone } : null;
}

function authEmailMatchesIdentifier(authEmail, identifier) {
  const identity = String(identifier ?? "").includes("@")
    ? { type: "email", value: canonicalizeEmail(identifier) }
    : { type: "phone", value: canonicalizePhone(identifier) };

  if (!identity.value) return false;
  if (identity.type === "email") return canonicalizeEmail(authEmail) === identity.value;
  return syntheticAuthEmails(identity.value).includes(canonicalizeEmail(authEmail));
}

module.exports = {
  ACCOUNT_SCHEMA_VERSION,
  authEmailMatchesIdentifier,
  buildAccountDocument,
  canonicalizeEmail,
  dedupeProfileRefs,
  identityFromAuthEmail,
  normalizeProfileRef,
  profileKey,
  profileRole,
  removeProfileRef,
  syntheticAuthEmails,
};
