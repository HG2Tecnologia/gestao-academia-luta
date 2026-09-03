"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const { initializeApp, deleteApp } = require("firebase/app");
const {
  connectAuthEmulator,
  createUserWithEmailAndPassword,
  getAuth,
} = require("firebase/auth");
const {
  connectFunctionsEmulator,
  getFunctions,
  httpsCallable,
} = require("firebase/functions");
const { initializeTestEnvironment } = require("@firebase/rules-unit-testing");

const projectId = "sensei-manager-test";
let environment;
let app;

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
    await firestore.doc("academias/academy-a").set({ nome: "Academia A" });
    await firestore.doc("academias/academy-a/usuarios/student-a").set({
      nome: "Irmã A",
      perfil: 3,
      ativo: true,
      telefone: "(21) 99999-9999",
      telefone_digits: "21999999999",
    });
  });

  app = initializeApp({ projectId, apiKey: "fixture-api-key" }, "identity-test");
  connectAuthEmulator(getAuth(app), "http://127.0.0.1:9099", { disableWarnings: true });
  connectFunctionsEmulator(getFunctions(app), "127.0.0.1", 5001);
});

test.after(async () => {
  await deleteApp(app);
  await environment.cleanup();
});

test("primeiro acesso cria uma conta e refresh inclui irmã sem novo cadastro", async () => {
  await createUserWithEmailAndPassword(
    getAuth(app),
    "5521999999999@sensei.app",
    "SenhaFixture123",
  );

  const functions = getFunctions(app);
  const activate = httpsCallable(functions, "activateAccessAccount");
  const activated = await activate({
    identifier: "(21) 99999-9999",
    primaryProfileKey: "academy-a|usuarios|student-a",
  });
  assert.equal(activated.data.account.schemaVersion, 2);
  assert.equal(activated.data.account.profile_refs.length, 1);

  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("academias/academy-a/usuarios/student-b").set({
      nome: "Irmã B",
      perfil: 3,
      ativo: true,
      telefone: "+55 21 99999-9999",
      telefone_digits: "5521999999999",
    });
  });

  const refresh = httpsCallable(functions, "refreshAccessAccount");
  const refreshed = await refresh();
  assert.deepEqual(
    refreshed.data.account.profile_keys,
    ["academy-a|usuarios|student-a", "academy-a|usuarios|student-b"],
  );
  assert.deepEqual(refreshed.data.account.roles_by_academy, {
    "academy-a": ["Aluno"],
  });
});
