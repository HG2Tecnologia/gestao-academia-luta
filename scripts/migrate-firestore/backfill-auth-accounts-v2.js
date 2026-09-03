#!/usr/bin/env node
"use strict";

/**
 * Backfill seguro de usuariosFirebase para o schema v2.
 *
 * Por padrão apenas analisa e gera relatório:
 *   node backfill-auth-accounts-v2.js
 *
 * Para aplicar depois de revisar o relatório:
 *   node backfill-auth-accounts-v2.js --apply
 */

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const {
  buildAccountDocument,
  canonicalizeEmail,
  identityFromAuthEmail,
  profileKey,
  profileRole,
} = require("../../functions/domain/account");
const { canonicalizePhone } = require("../../functions/domain/phone-normalizer");

const apply = process.argv.includes("--apply");
const projectId = process.env.GCLOUD_PROJECT || "sensei-manager-d64c0";
const serviceAccountPath = path.join(__dirname, "serviceAccount.json");
const credential = fs.existsSync(serviceAccountPath)
  ? admin.credential.cert(require(serviceAccountPath))
  : admin.credential.applicationDefault();

admin.initializeApp({ credential, projectId });
const db = admin.firestore();
const auth = admin.auth();

function hashIdentity(value) {
  return crypto.createHash("sha256").update(String(value)).digest("hex").slice(0, 16);
}

function identityForProfile(data) {
  const email = canonicalizeEmail(data.email);
  const phone = canonicalizePhone(
    data.telefone_canonical || data.telefone || data.telefone_digits,
  );
  return { email, phone };
}

function profileFromDoc(doc, academiaNome) {
  const data = doc.data();
  const colecao = doc.ref.parent.id;
  const academiaId = doc.ref.parent.parent.id;
  const perfilNome = profileRole(colecao, data);
  if (!perfilNome) return null;
  const profile = {
    academiaId,
    academiaNome,
    usuarioId: doc.id,
    colecao,
    perfil_nome: perfilNome,
    nome: String(data.nome || ""),
    linkedUid: data.firebaseUid || data.firebase_uid || null,
    active: data.ativo !== false,
    identity: identityForProfile(data),
    ref: doc.ref,
  };
  profile.key = profileKey(profile);
  return profile;
}

async function loadProfiles() {
  const academies = await db.collection("academias").get();
  const profiles = [];
  for (const academy of academies.docs) {
    for (const collection of ["usuarios", "funcionarios"]) {
      const snapshot = await academy.ref.collection(collection).get();
      for (const doc of snapshot.docs) {
        const profile = profileFromDoc(doc, academy.data().nome || "");
        if (profile?.active) profiles.push(profile);
      }
    }
  }
  return profiles;
}

async function run() {
  console.log(apply ? "APLICAÇÃO habilitada" : "DRY-RUN: nenhum documento será alterado");
  const profiles = await loadProfiles();
  const accounts = await db.collection("usuariosFirebase").get();
  const report = {
    generatedAt: new Date().toISOString(),
    projectId,
    mode: apply ? "apply" : "dry-run",
    totals: { accounts: accounts.size, ready: 0, conflicts: 0, withoutProfiles: 0 },
    conflicts: [],
    withoutProfiles: [],
  };

  for (const accountDoc of accounts.docs) {
    const uid = accountDoc.id;
    const current = accountDoc.data();
    let authUser;
    try {
      authUser = await auth.getUser(uid);
    } catch (error) {
      report.withoutProfiles.push({ uid, reason: `auth:${error.code || "not-found"}` });
      report.totals.withoutProfiles++;
      continue;
    }

    const authIdentity = identityFromAuthEmail(authUser.email);
    const email = current.email_canonical || (authIdentity?.type === "email" ? authIdentity.value : null);
    const phone = current.phone_canonical || (authIdentity?.type === "phone" ? authIdentity.value : null);
    const confirmed = profiles.filter((profile) => profile.linkedUid === uid);
    const candidates = profiles.filter((profile) =>
      (email && profile.identity.email === email) || (phone && profile.identity.phone === phone));
    const conflicts = candidates.filter((profile) => profile.linkedUid && profile.linkedUid !== uid);

    if (conflicts.length > 0) {
      report.totals.conflicts++;
      report.conflicts.push({
        uid,
        identityHash: hashIdentity(email || phone),
        confirmedProfileKeys: confirmed.map((profile) => profile.key),
        conflictingProfileKeys: conflicts.map((profile) => profile.key),
      });
      // Uma conta ambígua deve permanecer completamente intocada. Mesmo os
      // perfis já confirmados só serão migrados depois da revisão manual do
      // conflito, evitando produzir um estado v2 parcial em produção.
      continue;
    }

    const safeProfiles = [
      ...confirmed,
      ...candidates.filter((profile) => !profile.linkedUid),
    ];
    const uniqueProfiles = [...new Map(safeProfiles.map((profile) => [profile.key, profile])).values()];
    if (uniqueProfiles.length === 0) {
      report.totals.withoutProfiles++;
      report.withoutProfiles.push({ uid, reason: "no-confirmed-profile" });
      continue;
    }

    const account = buildAccountDocument({
      uid,
      profiles: uniqueProfiles,
      primaryProfileKey: current.primary_profile_key,
      emailCanonical: email,
      phoneCanonical: phone,
    });
    report.totals.ready++;

    if (apply) {
      const batch = db.batch();
      batch.set(accountDoc.ref, {
        ...account,
        criado_em: current.criado_em || FieldValue.serverTimestamp(),
        atualizado_em: FieldValue.serverTimestamp(),
      }, { merge: true });
      for (const profile of uniqueProfiles) {
        batch.update(profile.ref, {
          firebaseUid: uid,
          conta_ativa: true,
          auth_account_schema_version: 2,
          atualizado_em: FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  const reportPath = path.join(__dirname, "auth-account-v2-report.json");
  fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
  console.log(JSON.stringify(report.totals, null, 2));
  console.log(`Relatório: ${reportPath}`);
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
