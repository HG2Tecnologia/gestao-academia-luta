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

const SHARED_UID = "irmaos-conta-compartilhada-uid";

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

  // Dois "irmãos" com o mesmo telefone/e-mail, compartilhando a mesma conta
  // de acesso (mesmo firebaseUid) — excluir o aluno-1 NUNCA pode derrubar o
  // acesso do aluno-2.
  await firestore.doc("academias/academy-a/usuarios/aluno-1").set({
    nome: "Irmão Um",
    ativo: true,
    firebaseUid: SHARED_UID,
  });
  await firestore.doc("academias/academy-a/usuarios/aluno-2").set({
    nome: "Irmão Dois",
    ativo: true,
    firebaseUid: SHARED_UID,
  });
  await firestore.doc(`usuariosFirebase/${SHARED_UID}`).set({
    schemaVersion: 2,
    primary_profile_key: "academy-a|usuarios|aluno-1",
    profile_keys: ["academy-a|usuarios|aluno-1", "academy-a|usuarios|aluno-2"],
    academy_ids: ["academy-a"],
    roles_by_academy: { "academy-a": ["Aluno"] },
    profile_refs: [
      { key: "academy-a|usuarios|aluno-1", academiaId: "academy-a", colecao: "usuarios", usuarioId: "aluno-1", perfil_nome: "Aluno", nome: "Irmão Um" },
      { key: "academy-a|usuarios|aluno-2", academiaId: "academy-a", colecao: "usuarios", usuarioId: "aluno-2", perfil_nome: "Aluno", nome: "Irmão Dois" },
    ],
  });

  // Vínculos do aluno-1 espalhados pelas coleções que a exclusão precisa limpar.
  await firestore.doc("academias/academy-a/matriculas/matricula-1").set({ aluno_id: "aluno-1", turma_id: "turma-1", ativo: true });
  await firestore.doc("academias/academy-a/pagamentos/pagamento-1").set({ aluno_id: "aluno-1", valor: 100, status: 0 });
  await firestore.doc("academias/academy-a/presencas/presenca-1").set({ aluno_id: "aluno-1", turma_id: "turma-1", data: "2026-01-05" });
  await firestore.doc("academias/academy-a/graduacoes/graduacao-1").set({ aluno_id: "aluno-1", faixa: "Azul" });
  await firestore.doc("academias/academy-a/notificacoes/notificacao-1").set({ aluno_id: "aluno-1", titulo: "Oi", lida: false });
  await firestore.doc("academias/academy-a/conquistas_aluno/conquista-1").set({ aluno_id: "aluno-1", conquista_id: "c1" });
  await firestore.doc("academias/academy-a/contratos/contrato-1").set({ aluno_id: "aluno-1", assinado: true });
  await firestore.doc("academias/academy-a/respostas_pesquisa/resposta-1").set({ aluno_id: "aluno-1", nota: 5 });
  await firestore.doc("academias/academy-a/planos_modalidade/matricula-jiujitsu").set({ aluno_id: "aluno-1", modalidade_id: "jiujitsu", plano_id: "plano-x", ativo: true });

  // Vínculo do aluno-2 numa mesma coleção — nunca pode ser tocado.
  await firestore.doc("academias/academy-a/presencas/presenca-2").set({ aluno_id: "aluno-2", turma_id: "turma-1", data: "2026-01-05" });

  // Grupo familiar com os dois irmãos, aluno-1 como responsável.
  await firestore.doc("academias/academy-a/grupos_familiares/grupo-1").set({
    responsavel_id: "aluno-1",
    membros: [{ id: "aluno-1", nome: "Irmão Um" }, { id: "aluno-2", nome: "Irmão Dois" }],
  });

  // Registros imutáveis (não podem ser apagados nem pela function).
  await firestore.doc("academias/academy-a/atestados/atestado-1").set({ aluno_id: "aluno-1", url: "x" });
  await firestore.doc("academias/academy-a/par_qs/parq-1").set({ aluno_id: "aluno-1", respostas: {} });
}

async function linkAdmin(context, uid) {
  await context.firestore().doc(`usuariosFirebase/${uid}`).set({
    schemaVersion: 2,
    profile_refs: [
      { key: "academy-a|funcionarios|admin-a", academiaId: "academy-a", colecao: "funcionarios", usuarioId: "admin-a", perfil_nome: "Admin", nome: "Admin A" },
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

  app = initializeApp({ projectId, apiKey: "fixture-api-key" }, "aluno-test");
  connectAuthEmulator(getAuth(app), "http://127.0.0.1:9099", { disableWarnings: true });
  connectFunctionsEmulator(getFunctions(app), "127.0.0.1", 5001);
});

test.after(async () => {
  await deleteApp(app);
  await environment.cleanup();
});

test("professor não pode excluir aluno (ação restrita a Admin/Secretaria)", async () => {
  await environment.withSecurityRulesDisabled((ctx) => seed(ctx));

  const auth = getAuth(app);
  await createUserWithEmailAndPassword(auth, "professor-a-aluno@sensei.app", "SenhaFixtureProf1");
  await environment.withSecurityRulesDisabled((ctx) =>
    ctx.firestore().doc(`usuariosFirebase/${auth.currentUser.uid}`).set({
      schemaVersion: 2,
      profile_refs: [
        { key: "academy-a|funcionarios|professor-a", academiaId: "academy-a", colecao: "funcionarios", usuarioId: "professor-a", perfil_nome: "Professor", nome: "Professor A" },
      ],
    }),
  );

  const functions = getFunctions(app);
  const excluir = httpsCallable(functions, "excluirAluno");
  await assert.rejects(
    () => excluir({ academiaId: "academy-a", alunoId: "aluno-1" }),
    (error) => {
      assert.equal(error.code, "functions/permission-denied");
      return true;
    },
  );
});

test("admin exclui aluno: apaga cascata, preserva registros imutáveis e não afeta o irmão com conta compartilhada", async () => {
  const auth = getAuth(app);
  await createUserWithEmailAndPassword(auth, "admin-a-aluno@sensei.app", "SenhaFixtureAdmin1");
  await environment.withSecurityRulesDisabled((ctx) => linkAdmin(ctx, auth.currentUser.uid));

  const functions = getFunctions(app);
  const excluir = httpsCallable(functions, "excluirAluno");
  const resultado = await excluir({ academiaId: "academy-a", alunoId: "aluno-1" });

  assert.equal(resultado.data.ok, true);

  await environment.withSecurityRulesDisabled(async (ctx) => {
    const firestore = ctx.firestore();

    // Doc do aluno some.
    assert.equal((await firestore.doc("academias/academy-a/usuarios/aluno-1").get()).exists, false);

    // Cascata: tudo do aluno-1 some.
    for (const [colecao, docId] of [
      ["matriculas", "matricula-1"],
      ["pagamentos", "pagamento-1"],
      ["presencas", "presenca-1"],
      ["graduacoes", "graduacao-1"],
      ["notificacoes", "notificacao-1"],
      ["conquistas_aluno", "conquista-1"],
      ["contratos", "contrato-1"],
      ["respostas_pesquisa", "resposta-1"],
      ["planos_modalidade", "matricula-jiujitsu"],
    ]) {
      const doc = await firestore.doc(`academias/academy-a/${colecao}/${docId}`).get();
      assert.equal(doc.exists, false, `${colecao}/${docId} deveria ter sido apagado`);
    }

    // Registros imutáveis (saúde/legal) continuam existindo, só ficam órfãos.
    assert.equal((await firestore.doc("academias/academy-a/atestados/atestado-1").get()).exists, true);
    assert.equal((await firestore.doc("academias/academy-a/par_qs/parq-1").get()).exists, true);

    // Vínculo do aluno-2 (irmão) na MESMA coleção não é afetado.
    const presencaIrmao = await firestore.doc("academias/academy-a/presencas/presenca-2").get();
    assert.equal(presencaIrmao.exists, true);
    assert.equal(presencaIrmao.data().aluno_id, "aluno-2");

    // Grupo familiar: aluno-1 sai dos membros e deixa de ser responsável;
    // aluno-2 continua no grupo.
    const grupo = await firestore.doc("academias/academy-a/grupos_familiares/grupo-1").get();
    assert.equal(grupo.data().responsavel_id, null);
    assert.deepEqual(grupo.data().membros, [{ id: "aluno-2", nome: "Irmão Dois" }]);

    // Conta compartilhada: só o profile_ref do aluno-1 some; aluno-2 continua
    // com acesso normal.
    const conta = await firestore.doc(`usuariosFirebase/${SHARED_UID}`).get();
    assert.equal(conta.exists, true, "conta compartilhada não pode ser apagada enquanto o irmão ainda a usa");
    assert.equal(conta.data().profile_refs.length, 1);
    assert.equal(conta.data().profile_refs[0].usuarioId, "aluno-2");
    assert.equal(conta.data().primary_profile_key, "academy-a|usuarios|aluno-2");

    // Aluno-2 (irmão) permanece intocado.
    const aluno2 = await firestore.doc("academias/academy-a/usuarios/aluno-2").get();
    assert.equal(aluno2.exists, true);

    const auditoria = await firestore.collection("academias/academy-a/auditoria").get();
    assert.equal(auditoria.size, 1);
    assert.equal(auditoria.docs[0].data().tipo, "exclusao_aluno");
  });
});

test("excluir aluno inexistente falha com not-found", async () => {
  const functions = getFunctions(app);
  const excluir = httpsCallable(functions, "excluirAluno");
  await assert.rejects(
    () => excluir({ academiaId: "academy-a", alunoId: "nunca-existiu" }),
    (error) => {
      assert.equal(error.code, "functions/not-found");
      return true;
    },
  );
});
