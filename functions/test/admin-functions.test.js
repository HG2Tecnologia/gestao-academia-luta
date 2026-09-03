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
  signInWithEmailAndPassword,
  signOut,
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

async function seed(context, overrides = {}) {
  const firestore = context.firestore();
  await firestore.doc("academias/academy-a").set({ nome: "Academia A" });
  await firestore.doc("academias/academy-a/funcionarios/admin-a").set({
    nome: "Admin A",
    perfil: "Admin",
    ativo: true,
    firebaseUid: "uid-admin",
  });
  await firestore.doc("academias/academy-a/funcionarios/secretaria-a").set({
    nome: "Secretaria A",
    perfil: "Secretaria",
    ativo: true,
    firebaseUid: "uid-secretaria",
    permissoes: { acesso_redefinir_senha: overrides.secretariaPodeRedefinir ?? false },
  });
  await firestore.doc("academias/academy-a/usuarios/aluno-a").set({
    nome: "Aluno A",
    perfil: 3,
    ativo: true,
    firebaseUid: "uid-aluno",
  });
  await firestore.doc("usuariosFirebase/uid-admin").set({
    schemaVersion: 2,
    profile_refs: [
      { key: "academy-a|funcionarios|admin-a", academiaId: "academy-a", colecao: "funcionarios", usuarioId: "admin-a", perfil_nome: "Admin", nome: "Admin A" },
    ],
  });
  await firestore.doc("usuariosFirebase/uid-secretaria").set({
    schemaVersion: 2,
    profile_refs: [
      { key: "academy-a|funcionarios|secretaria-a", academiaId: "academy-a", colecao: "funcionarios", usuarioId: "secretaria-a", perfil_nome: "Secretaria", nome: "Secretaria A" },
    ],
  });
  await firestore.doc("usuariosFirebase/uid-aluno").set({
    schemaVersion: 2,
    profile_refs: [
      { key: "academy-a|usuarios|aluno-a", academiaId: "academy-a", colecao: "usuarios", usuarioId: "aluno-a", perfil_nome: "Aluno", nome: "Aluno A" },
    ],
  });
}

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

  app = initializeApp({ projectId, apiKey: "fixture-api-key" }, "admin-test");
  connectAuthEmulator(getAuth(app), "http://127.0.0.1:9099", { disableWarnings: true });
  connectFunctionsEmulator(getFunctions(app), "127.0.0.1", 5001);
});

test.after(async () => {
  await deleteApp(app);
  await environment.cleanup();
});

test("admin redefine a senha do aluno: gera senha temporária e força troca", async (t) => {
  await environment.withSecurityRulesDisabled((ctx) => seed(ctx));

  const auth = getAuth(app);
  await createUserWithEmailAndPassword(auth, "admin-a@sensei.app", "SenhaFixtureAdmin1");
  // UID real gerado pelo emulador difere do fixture "uid-admin"; religa o
  // documento à credencial recém-criada para o teste ficar autocontido.
  const adminUid = auth.currentUser.uid;
  await environment.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc("usuariosFirebase/uid-admin").delete();
    await ctx.firestore().doc(`usuariosFirebase/${adminUid}`).set({
      schemaVersion: 2,
      profile_refs: [
        { key: "academy-a|funcionarios|admin-a", academiaId: "academy-a", colecao: "funcionarios", usuarioId: "admin-a", perfil_nome: "Admin", nome: "Admin A" },
      ],
    });
  });

  await createUserWithEmailAndPassword(auth, "aluno-a@sensei.app", "SenhaFixtureAluno1");
  const alunoUid = auth.currentUser.uid;
  await environment.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc("academias/academy-a/usuarios/aluno-a").update({ firebaseUid: alunoUid });
  });
  await signOut(auth);
  await signInWithEmailAndPassword(auth, "admin-a@sensei.app", "SenhaFixtureAdmin1");

  const functions = getFunctions(app);
  const resetar = httpsCallable(functions, "adminResetPassword");
  const resultado = await resetar({ academiaId: "academy-a", colecao: "usuarios", usuarioId: "aluno-a" });
  assert.equal(typeof resultado.data.temporaryPassword, "string");
  assert.ok(resultado.data.temporaryPassword.length >= 6);

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const flag = await ctx.firestore().doc(`usuariosFirebase/${alunoUid}`).get();
    assert.equal(flag.data().must_change_password, true);
    const auditoria = await ctx.firestore().collection("academias/academy-a/auditoria").get();
    assert.equal(auditoria.size, 1);
    assert.equal(auditoria.docs[0].data().tipo, "redefinicao_senha");
  });

  await signOut(auth);
  await signInWithEmailAndPassword(auth, "aluno-a@sensei.app", resultado.data.temporaryPassword);

  const concluir = httpsCallable(functions, "completeMandatoryPasswordChange");
  await concluir();
  await environment.withSecurityRulesDisabled(async (ctx) => {
    const flag = await ctx.firestore().doc(`usuariosFirebase/${alunoUid}`).get();
    assert.equal(flag.data().must_change_password, false);
  });
});

test("secretaria sem a permissão granular não pode redefinir senha", async () => {
  await environment.withSecurityRulesDisabled((ctx) => seed(ctx, { secretariaPodeRedefinir: false }));

  const auth = getAuth(app);
  await createUserWithEmailAndPassword(auth, "secretaria-a@sensei.app", "SenhaFixtureSec1");
  const secUid = auth.currentUser.uid;
  await environment.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc("usuariosFirebase/uid-secretaria").delete();
    await ctx.firestore().doc(`usuariosFirebase/${secUid}`).set({
      schemaVersion: 2,
      profile_refs: [
        { key: "academy-a|funcionarios|secretaria-a", academiaId: "academy-a", colecao: "funcionarios", usuarioId: "secretaria-a", perfil_nome: "Secretaria", nome: "Secretaria A" },
      ],
    });
  });

  const functions = getFunctions(app);
  const resetar = httpsCallable(functions, "adminResetPassword");
  await assert.rejects(
    () => resetar({ academiaId: "academy-a", colecao: "usuarios", usuarioId: "aluno-a" }),
    (error) => {
      assert.equal(error.code, "functions/permission-denied");
      return true;
    },
  );
});
