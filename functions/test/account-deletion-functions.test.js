"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const { initializeApp, deleteApp } = require("firebase/app");
const { connectAuthEmulator, createUserWithEmailAndPassword, getAuth, signOut } = require("firebase/auth");
const { connectFunctionsEmulator, getFunctions, httpsCallable } = require("firebase/functions");
const { initializeTestEnvironment } = require("@firebase/rules-unit-testing");

const projectId = "sensei-manager-test";
const AUTH_EMULATOR = "http://127.0.0.1:9099";
let environment;
let app;

function ref(academiaId, colecao, usuarioId, perfil, nome) {
  return { key: `${academiaId}|${colecao}|${usuarioId}`, academiaId, colecao, usuarioId, perfil_nome: perfil, nome };
}

function contaDoc(refs) {
  const roles = {};
  for (const r of refs) (roles[r.academiaId] ??= []).push(r.perfil_nome);
  return {
    schemaVersion: 2,
    primary_profile_key: refs[0].key,
    profile_keys: refs.map((r) => r.key),
    profile_refs: refs,
    academy_ids: Object.keys(roles).sort(),
    roles_by_academy: roles,
    academiaId: refs[0].academiaId,
  };
}

async function criarLogin(email) {
  const auth = getAuth(app);
  await createUserWithEmailAndPassword(auth, email, "SenhaFixture123");
  return auth.currentUser.uid;
}

async function loginExiste(uid) {
  const res = await fetch(
    `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:lookup`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: "Bearer owner" },
      body: JSON.stringify({ localId: [uid] }),
    },
  );
  const body = await res.json();
  return Array.isArray(body.users) && body.users.length > 0;
}

test.before(async () => {
  const rulesPath = path.join(__dirname, "..", "..", "scripts", "migrate-firestore", "firestore.rules");
  environment = await initializeTestEnvironment({
    projectId,
    firestore: { host: "127.0.0.1", port: 8080, rules: fs.readFileSync(rulesPath, "utf8") },
  });
  app = initializeApp({ projectId, apiKey: "fixture-api-key" }, "exclusao-conta-test");
  connectAuthEmulator(getAuth(app), AUTH_EMULATOR, { disableWarnings: true });
  connectFunctionsEmulator(getFunctions(app), "127.0.0.1", 5001);
});

test.after(async () => {
  await deleteApp(app);
  await environment.cleanup();
});

test("aluno não pode excluir a academia", async () => {
  const uid = await criarLogin("aluno-tenta-excluir@sensei.app");
  await environment.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await fs.doc("academias/acad-perm").set({ nome: "Academia Perm" });
    await fs.doc(`usuariosFirebase/${uid}`).set(contaDoc([ref("acad-perm", "usuarios", "aluno-p", "Aluno", "Aluno")]));
  });

  const excluir = httpsCallable(getFunctions(app), "excluirMinhaConta");
  await assert.rejects(
    () => excluir({ academiaId: "acad-perm", confirmacaoNome: "Academia Perm" }),
    (error) => error.code === "functions/permission-denied",
  );
  await environment.withSecurityRulesDisabled(async (ctx) => {
    assert.equal((await ctx.firestore().doc("academias/acad-perm").get()).exists, true);
  });
  await signOut(getAuth(app));
});

test("nome digitado errado não apaga nada", async () => {
  const uid = await criarLogin("admin-nome-errado@sensei.app");
  await environment.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await fs.doc("academias/acad-nome").set({ nome: "Academia Nome" });
    await fs.doc("academias/acad-nome/usuarios/admin-n").set({ nome: "Admin", perfil_nome: "Admin", firebaseUid: uid });
    await fs.doc(`usuariosFirebase/${uid}`).set(contaDoc([ref("acad-nome", "usuarios", "admin-n", "Admin", "Admin")]));
  });

  const excluir = httpsCallable(getFunctions(app), "excluirMinhaConta");
  await assert.rejects(
    () => excluir({ academiaId: "acad-nome", confirmacaoNome: "Outra Academia" }),
    (error) => error.code === "functions/failed-precondition",
  );
  await environment.withSecurityRulesDisabled(async (ctx) => {
    assert.equal((await ctx.firestore().doc("academias/acad-nome").get()).exists, true);
  });
  assert.equal(await loginExiste(uid), true);
  await signOut(getAuth(app));
});

test("único admin: apaga a academia inteira, logins exclusivos dela e preserva perfis em outra academia", async () => {
  const alunoSoAquiUid = await criarLogin("aluno-so-aqui@sensei.app");
  const alunoDuasUid = await criarLogin("aluno-duas@sensei.app");
  const adminUid = await criarLogin("admin-unico@sensei.app");

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await fs.doc("academias/acad-x").set({ nome: "Academia  X" });
    await fs.doc("academias/acad-x/usuarios/admin-x").set({ nome: "Dono", perfil_nome: "Admin", firebaseUid: adminUid });
    await fs.doc("academias/acad-x/usuarios/aluno-1").set({ nome: "Aluno 1", perfil_nome: "Aluno", firebaseUid: alunoSoAquiUid });
    await fs.doc("academias/acad-x/usuarios/aluno-2").set({ nome: "Aluno 2", perfil_nome: "Aluno", firebaseUid: alunoDuasUid });
    await fs.doc("academias/acad-x/turmas/turma-1").set({ nome: "Kids" });
    await fs.doc("academias/acad-x/pagamentos/pag-1").set({ aluno_id: "aluno-1", valor: 100 });
    // Admin inativo, ou sem login, não conta como "outro admin".
    await fs.doc("academias/acad-x/funcionarios/ex-admin").set({ nome: "Ex", perfil: "Admin", ativo: false, firebaseUid: "x" });
    await fs.doc("academias/acad-x/usuarios/admin-sem-login").set({ nome: "Sem login", perfil: 0 });

    await fs.doc("academias/acad-y").set({ nome: "Academia Y" });
    await fs.doc("academias/acad-y/usuarios/aluno-y").set({ nome: "Aluno 2", perfil_nome: "Aluno" });

    await fs.doc(`usuariosFirebase/${adminUid}`).set(contaDoc([ref("acad-x", "usuarios", "admin-x", "Admin", "Dono")]));
    await fs.doc(`usuariosFirebase/${alunoSoAquiUid}`).set(contaDoc([ref("acad-x", "usuarios", "aluno-1", "Aluno", "Aluno 1")]));
    await fs.doc(`usuariosFirebase/${alunoDuasUid}`).set(contaDoc([
      ref("acad-x", "usuarios", "aluno-2", "Aluno", "Aluno 2"),
      ref("acad-y", "usuarios", "aluno-y", "Aluno", "Aluno 2"),
    ]));
  });

  const excluir = httpsCallable(getFunctions(app), "excluirMinhaConta");
  // Caixa e espaços diferentes do nome salvo ainda conferem.
  const resultado = await excluir({ academiaId: "acad-x", confirmacaoNome: " academia x " });
  assert.equal(resultado.data.ok, true);
  assert.equal(resultado.data.modo, "academia");
  assert.equal(resultado.data.loginApagado, true);

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    assert.equal((await fs.doc("academias/acad-x").get()).exists, false);
    assert.equal((await fs.collection("academias/acad-x/usuarios").get()).size, 0);
    assert.equal((await fs.collection("academias/acad-x/turmas").get()).size, 0);
    assert.equal((await fs.collection("academias/acad-x/pagamentos").get()).size, 0);

    assert.equal((await fs.doc(`usuariosFirebase/${adminUid}`).get()).exists, false);
    assert.equal((await fs.doc(`usuariosFirebase/${alunoSoAquiUid}`).get()).exists, false);

    const contaDuas = (await fs.doc(`usuariosFirebase/${alunoDuasUid}`).get()).data();
    assert.deepEqual(contaDuas.academy_ids, ["acad-y"]);
    assert.equal(contaDuas.primary_profile_key, "acad-y|usuarios|aluno-y");

    assert.equal((await fs.doc("academias/acad-y/usuarios/aluno-y").get()).exists, true);
  });

  assert.equal(await loginExiste(adminUid), false);
  assert.equal(await loginExiste(alunoSoAquiUid), false);
  assert.equal(await loginExiste(alunoDuasUid), true);
});

test("com outro admin ativo: apaga só o perfil de quem pediu e mantém a academia", async () => {
  const outroUid = await criarLogin("outro-admin@sensei.app");
  const adminUid = await criarLogin("admin-sai@sensei.app");

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await fs.doc("academias/acad-z").set({ nome: "Academia Z" });
    await fs.doc("academias/acad-z/usuarios/admin-sai").set({ nome: "Sai", perfil_nome: "Admin", firebaseUid: adminUid });
    await fs.doc("academias/acad-z/funcionarios/admin-fica").set({ nome: "Fica", perfil: "Admin", ativo: true, firebaseUid: outroUid });
    await fs.doc("academias/acad-z/turmas/turma-1").set({ nome: "Adulto" });
    await fs.doc(`usuariosFirebase/${adminUid}`).set(contaDoc([ref("acad-z", "usuarios", "admin-sai", "Admin", "Sai")]));
    await fs.doc(`usuariosFirebase/${outroUid}`).set(contaDoc([ref("acad-z", "funcionarios", "admin-fica", "Admin", "Fica")]));
  });

  const excluir = httpsCallable(getFunctions(app), "excluirMinhaConta");
  const resultado = await excluir({ academiaId: "acad-z", confirmacaoNome: "Academia Z" });
  assert.equal(resultado.data.modo, "perfil");
  assert.equal(resultado.data.loginApagado, true);

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    assert.equal((await fs.doc("academias/acad-z").get()).exists, true);
    assert.equal((await fs.doc("academias/acad-z/turmas/turma-1").get()).exists, true);
    assert.equal((await fs.doc("academias/acad-z/usuarios/admin-sai").get()).exists, false);
    assert.equal((await fs.doc("academias/acad-z/funcionarios/admin-fica").get()).exists, true);
    assert.equal((await fs.doc(`usuariosFirebase/${adminUid}`).get()).exists, false);
    assert.equal((await fs.doc(`usuariosFirebase/${outroUid}`).get()).exists, true);
    const auditoria = await fs.collection("academias/acad-z/auditoria").get();
    assert.equal(auditoria.docs[0].data().tipo, "exclusao_conta_admin");
  });
  assert.equal(await loginExiste(adminUid), false);
  assert.equal(await loginExiste(outroUid), true);
});
