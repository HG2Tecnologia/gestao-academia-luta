"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const { initializeApp, deleteApp } = require("firebase/app");
const { connectAuthEmulator, createUserWithEmailAndPassword, getAuth } = require("firebase/auth");
const { connectFunctionsEmulator, getFunctions, httpsCallable } = require("firebase/functions");
const { initializeTestEnvironment } = require("@firebase/rules-unit-testing");

const projectId = "sensei-manager-test";
let environment;
let app;

async function seed(context) {
  const firestore = context.firestore();
  await firestore.doc("academias/academy-a").set({ nome: "Academia A" });
  await firestore.doc("academias/academy-a/funcionarios/admin-a").set({
    nome: "Admin A",
    perfil: "Admin",
    ativo: true,
  });
  await firestore.doc("academias/academy-a/funcionarios/professor-a").set({
    nome: "Professor A",
    perfil: "Professor",
    ativo: true,
  });
  await firestore.doc("academias/academy-a/turmas/turma-1").set({
    nome: "Jiu-Jitsu Adulto",
    ativo: true,
  });
  await firestore.doc("academias/academy-a/matriculas/matricula-1").set({
    turma_id: "turma-1",
    aluno_id: "aluno-1",
    ativo: true,
  });
  await firestore.doc("academias/academy-a/matriculas/matricula-2").set({
    turma_id: "turma-1",
    aluno_id: "aluno-2",
    ativo: true,
  });
  // matrícula já encerrada antes da exclusão — não deve ser tocada de novo.
  await firestore.doc("academias/academy-a/matriculas/matricula-3").set({
    turma_id: "turma-1",
    aluno_id: "aluno-3",
    ativo: false,
    encerrado_em: new Date("2026-01-01"),
    encerrado_motivo: "aluno_saiu",
  });
  // presença histórica: precisa continuar íntegra depois da exclusão.
  await firestore.doc("academias/academy-a/presencas/presenca-1").set({
    turma_id: "turma-1",
    aluno_id: "aluno-1",
    criado_em: new Date("2026-01-05"),
  });
}

async function linkAccount(context, uid, academiaId, usuarioId, perfilNome, nome) {
  await context.firestore().doc(`usuariosFirebase/${uid}`).set({
    schemaVersion: 2,
    profile_refs: [
      { key: `${academiaId}|funcionarios|${usuarioId}`, academiaId, colecao: "funcionarios", usuarioId, perfil_nome: perfilNome, nome },
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

  app = initializeApp({ projectId, apiKey: "fixture-api-key" }, "turma-test");
  connectAuthEmulator(getAuth(app), "http://127.0.0.1:9099", { disableWarnings: true });
  connectFunctionsEmulator(getFunctions(app), "127.0.0.1", 5001);
});

test.after(async () => {
  await deleteApp(app);
  await environment.cleanup();
});

test("admin exclui turma com matrículas: encerra as ativas, preserva presença e não apaga o documento", async () => {
  await environment.withSecurityRulesDisabled((ctx) => seed(ctx));

  const auth = getAuth(app);
  await createUserWithEmailAndPassword(auth, "admin-a-turma@sensei.app", "SenhaFixtureAdmin1");
  const adminUid = auth.currentUser.uid;
  await environment.withSecurityRulesDisabled((ctx) =>
    linkAccount(ctx, adminUid, "academy-a", "admin-a", "Admin", "Admin A"),
  );

  const functions = getFunctions(app);
  const excluir = httpsCallable(functions, "arquivarTurma");
  const resultado = await excluir({ academiaId: "academy-a", turmaId: "turma-1" });

  assert.equal(resultado.data.ok, true);
  assert.equal(resultado.data.matriculasEncerradas, 2);

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const turma = await ctx.firestore().doc("academias/academy-a/turmas/turma-1").get();
    assert.equal(turma.exists, true, "o documento da turma não deve ser apagado");
    assert.equal(turma.data().ativo, false);
    assert.ok(turma.data().deleted_at);
    assert.ok(turma.data().deleted_by);

    const m1 = await ctx.firestore().doc("academias/academy-a/matriculas/matricula-1").get();
    assert.equal(m1.data().ativo, false);
    assert.equal(m1.data().encerrado_motivo, "turma_excluida");

    const m2 = await ctx.firestore().doc("academias/academy-a/matriculas/matricula-2").get();
    assert.equal(m2.data().ativo, false);

    // já estava encerrada por outro motivo — a function não deve sobrescrever.
    const m3 = await ctx.firestore().doc("academias/academy-a/matriculas/matricula-3").get();
    assert.equal(m3.data().encerrado_motivo, "aluno_saiu");

    const presenca = await ctx.firestore().doc("academias/academy-a/presencas/presenca-1").get();
    assert.equal(presenca.exists, true);
    assert.equal(presenca.data().turma_id, "turma-1");

    const auditoria = await ctx.firestore().collection("academias/academy-a/auditoria").get();
    assert.equal(auditoria.size, 1);
    assert.equal(auditoria.docs[0].data().tipo, "exclusao_turma");
    assert.equal(auditoria.docs[0].data().matriculas_encerradas, 2);
  });
});

test("excluir a mesma turma de novo falha com failed-precondition", async () => {
  const functions = getFunctions(app);
  const excluir = httpsCallable(functions, "arquivarTurma");
  await assert.rejects(
    () => excluir({ academiaId: "academy-a", turmaId: "turma-1" }),
    (error) => {
      assert.equal(error.code, "functions/failed-precondition");
      return true;
    },
  );
});

test("professor não pode excluir turma (ação restrita a Admin/Secretaria)", async () => {
  await environment.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc("academias/academy-a/turmas/turma-2").set({ nome: "Judo Kids", ativo: true });
  });

  const auth = getAuth(app);
  await createUserWithEmailAndPassword(auth, "professor-a-turma@sensei.app", "SenhaFixtureProf1");
  const profUid = auth.currentUser.uid;
  await environment.withSecurityRulesDisabled((ctx) =>
    linkAccount(ctx, profUid, "academy-a", "professor-a", "Professor", "Professor A"),
  );

  const functions = getFunctions(app);
  const excluir = httpsCallable(functions, "arquivarTurma");
  await assert.rejects(
    () => excluir({ academiaId: "academy-a", turmaId: "turma-2" }),
    (error) => {
      assert.equal(error.code, "functions/permission-denied");
      return true;
    },
  );
});
