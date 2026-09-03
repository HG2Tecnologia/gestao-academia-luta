"use strict";

const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");

const projectId = "sensei-manager-test";
let environment;

test.before(async () => {
  const rulesPath = path.join(__dirname, "..", "..", "scripts", "migrate-firestore", "firestore.rules");
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: fs.readFileSync(rulesPath, "utf8"),
    },
  });

  await environment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await firestore.doc("academias/academy-fixture").set({ nome: "Academia Fixture" });
    await firestore.doc("academias/academy-secondary").set({ nome: "Academia Secondary" });
    await firestore.doc("academias/academy-fixture/usuarios/student-a").set({
      nome: "Maria Fixture",
      perfil: 3,
      telefone_digits: "21999999999",
    });
  });
});

test.after(async () => {
  await environment?.cleanup();
});

test.afterEach(async () => {
  await environment?.clearFirestore();
  await environment?.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await firestore.doc("academias/academy-fixture").set({ nome: "Academia Fixture" });
    await firestore.doc("academias/academy-secondary").set({ nome: "Academia Secondary" });
    await firestore.doc("academias/academy-fixture/usuarios/student-a").set({
      nome: "Maria Fixture",
      perfil: 3,
      telefone_digits: "21999999999",
    });
  });
});

test("sessão anônima não consegue ler perfil no Primeiro Acesso", async () => {
  const firestore = environment
    .authenticatedContext("anonymous-fixture", {
      firebase: { sign_in_provider: "anonymous" },
    })
    .firestore();

  await assertFails(
    firestore.doc("academias/academy-fixture/usuarios/student-a").get(),
  );
});

test("cliente não pode criar lookup próprio declarando perfil Admin", async () => {
  const firestore = environment
    .authenticatedContext("attacker-fixture", { email: "fixture@example.invalid" })
    .firestore();

  await assertFails(
    firestore.doc("usuariosFirebase/attacker-fixture").set({
      academiaId: "academy-fixture",
      usuarioId: "attacker-profile",
      perfil: "Admin",
      nome: "Fixture",
    }),
  );
});

test("conta v2 lê duas academias sem herdar Admin para o segundo tenant", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("usuariosFirebase/account-v2").set({
      schemaVersion: 2,
      academiaId: "academy-fixture",
      perfil: "Admin",
      academy_ids: ["academy-fixture", "academy-secondary"],
      roles_by_academy: {
        "academy-fixture": ["Admin"],
        "academy-secondary": ["Aluno"],
      },
    });
  });
  const firestore = environment.authenticatedContext("account-v2").firestore();

  await assertSucceeds(firestore.doc("academias/academy-secondary").get());
  await assertSucceeds(
    firestore.doc("academias/academy-fixture/turmas/class-a").set({ nome: "Permitida" }),
  );
  await assertFails(
    firestore.doc("academias/academy-secondary/turmas/class-b").set({ nome: "Negada" }),
  );
});

test("cadastro da academia cria apenas o próprio Admin em batch validado", async () => {
  const uid = "new-academy-owner";
  const firestore = environment.authenticatedContext(uid, {
    email: "owner@example.invalid",
  }).firestore();
  const academyId = "new-academy";
  const userId = "new-admin";
  const key = `${academyId}|usuarios|${userId}`;
  const batch = firestore.batch();
  batch.set(firestore.doc(`academias/${academyId}`), {
    nome: "Nova Academia",
    created_by_uid: uid,
  });
  batch.set(firestore.doc(`academias/${academyId}/usuarios/${userId}`), {
    nome: "Novo Admin",
    perfil: 0,
    firebase_uid: uid,
  });
  batch.set(firestore.doc(`usuariosFirebase/${uid}`), {
    schemaVersion: 2,
    uid,
    status: "active",
    academiaId: academyId,
    usuarioId: userId,
    perfil: "Admin",
    academy_ids: [academyId],
    profile_keys: [key],
    roles_by_academy: { [academyId]: ["Admin"] },
  });

  await assertSucceeds(batch.commit());
});
