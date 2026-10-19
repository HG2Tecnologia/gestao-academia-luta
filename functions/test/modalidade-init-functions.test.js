"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const { initializeApp, deleteApp } = require("firebase/app");
const { connectAuthEmulator, createUserWithEmailAndPassword, getAuth, signInWithEmailAndPassword } = require("firebase/auth");
const { connectFunctionsEmulator, getFunctions, httpsCallable } = require("firebase/functions");
const { initializeTestEnvironment } = require("@firebase/rules-unit-testing");

const projectId = "sensei-manager-test";

// `modalidade-init-functions.js` chama `admin.firestore()` no escopo do
// módulo — no processo real da function isso já roda depois do
// `admin.initializeApp()` de `index.js`, mas aqui é um processo de teste
// separado que só quer o array `MODALIDADES_PADRAO`, então inicializa um
// app mínimo antes do require pra não quebrar o import.
require("firebase-admin").initializeApp({ projectId });
const { MODALIDADES_PADRAO, normalizarTexto } = require("../modalidade-init-functions");

let environment;
let app;
let contadorUid = 0;

async function criarAdmin(academiaId) {
  contadorUid += 1;
  const email = `admin-modalidades-${contadorUid}@example.invalid`;
  const cred = await createUserWithEmailAndPassword(getAuth(app), email, "SenhaFixture123");
  const uid = cred.user.uid;

  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`usuariosFirebase/${uid}`).set({
      schemaVersion: 2,
      uid,
      academiaId,
      perfil: "Admin",
      academy_ids: [academiaId],
      roles_by_academy: { [academiaId]: ["Admin"] },
    });
  });

  return { uid, email };
}

async function chamarInicializar(uid, email, dados) {
  await signInWithEmailAndPassword(getAuth(app), email, "SenhaFixture123");
  const fn = httpsCallable(getFunctions(app), "inicializarModalidadesPadrao");
  return fn(dados);
}

async function criarAcademia(academiaId, uidDono, extra) {
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`academias/${academiaId}`).set({
      nome: "Academia Fixture",
      created_by_uid: uidDono,
      ...extra,
    });
  });
}

async function lerModalidades(academiaId) {
  // `withSecurityRulesDisabled` sempre resolve pra `undefined` — o valor
  // de retorno do callback é descartado pela própria lib (ver
  // node_modules/@firebase/rules-unit-testing: `await callback(context)`
  // sem `return`). Por isso toda leitura aqui precisa escrever o
  // resultado numa variável de fora via closure, nunca via `return`.
  let resultado;
  await environment.withSecurityRulesDisabled(async (context) => {
    const snap = await context.firestore().collection(`academias/${academiaId}/modalidades`).get();
    resultado = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  });
  return resultado;
}

async function lerFaixas(academiaId) {
  let resultado;
  await environment.withSecurityRulesDisabled(async (context) => {
    const snap = await context.firestore().collection(`academias/${academiaId}/faixas`).get();
    resultado = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  });
  return resultado;
}

async function lerAcademia(academiaId) {
  let resultado;
  await environment.withSecurityRulesDisabled(async (context) => {
    const snap = await context.firestore().doc(`academias/${academiaId}`).get();
    resultado = snap.data();
  });
  return resultado;
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
  app = initializeApp({ projectId, apiKey: "fixture-api-key" }, "modalidade-init-test");
  connectAuthEmulator(getAuth(app), "http://127.0.0.1:9099", { disableWarnings: true });
  connectFunctionsEmulator(getFunctions(app), "127.0.0.1", 5001);
});

test.after(async () => {
  await deleteApp(app);
  await environment.cleanup();
});

test.afterEach(async () => {
  await environment.clearFirestore();
});

const TOTAL_MODALIDADES = MODALIDADES_PADRAO.length;
const TOTAL_FAIXAS = MODALIDADES_PADRAO.reduce((acc, m) => acc + m.faixas.length, 0);

test("academia nova e vazia: cria todas as modalidades e faixas padrão, status completo", async () => {
  const academiaId = "academia-nova-vazia";
  const { uid, email } = await criarAdmin(academiaId);
  await criarAcademia(academiaId, uid);

  const res = await chamarInicializar(uid, email, { academiaId });
  assert.equal(res.data.status, "completo");
  assert.equal(res.data.resumo.criadas, TOTAL_MODALIDADES + TOTAL_FAIXAS);
  assert.equal(res.data.resumo.pendentes, 0);

  const modalidades = await lerModalidades(academiaId);
  const faixas = await lerFaixas(academiaId);
  assert.equal(modalidades.length, TOTAL_MODALIDADES);
  assert.equal(faixas.length, TOTAL_FAIXAS);

  const academia = await lerAcademia(academiaId);
  assert.equal(academia.modalidades_status, "completo");
});

test("reexecução do seed já concluído: não duplica nada e retorna rápido", async () => {
  const academiaId = "academia-ja-completa";
  const { uid, email } = await criarAdmin(academiaId);
  await criarAcademia(academiaId, uid);

  await chamarInicializar(uid, email, { academiaId });
  const res2 = await chamarInicializar(uid, email, { academiaId });

  assert.equal(res2.data.jaEstavaCompleto, true);
  const modalidades = await lerModalidades(academiaId);
  assert.equal(modalidades.length, TOTAL_MODALIDADES);
});

test("reexecução forçada do seed já concluído continua sem duplicar (idempotência real)", async () => {
  const academiaId = "academia-forcar-reexecucao";
  const { uid, email } = await criarAdmin(academiaId);
  await criarAcademia(academiaId, uid);

  await chamarInicializar(uid, email, { academiaId });
  const res2 = await chamarInicializar(uid, email, { academiaId, forcarReexecucao: true });

  assert.equal(res2.data.status, "completo");
  assert.equal(res2.data.resumo.criadas, 0);
  assert.equal(res2.data.resumo.ja_existiam, TOTAL_MODALIDADES + TOTAL_FAIXAS);
  const modalidades = await lerModalidades(academiaId);
  assert.equal(modalidades.length, TOTAL_MODALIDADES);
});

test("falha parcial seguida de retry: seed interrompido no meio completa sem duplicar", async () => {
  const academiaId = "academia-falha-parcial";
  const { uid, email } = await criarAdmin(academiaId);
  await criarAcademia(academiaId, uid);

  // Simula "parou depois de criar algumas modalidades": cria manualmente
  // as 2 primeiras modalidades padrão com os MESMOS IDs determinísticos
  // que a function geraria, como se uma execução anterior tivesse
  // parado ali no meio (ex.: função caiu no meio do loop).
  await environment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    for (const def of MODALIDADES_PADRAO.slice(0, 2)) {
      await firestore.doc(`academias/${academiaId}/modalidades/${def.chave}`).set({
        id: def.chave,
        chave_padrao: def.chave,
        nome: def.nome,
        cor: def.cor,
        ativo: true,
      });
    }
  });

  const res = await chamarInicializar(uid, email, { academiaId });
  assert.equal(res.data.status, "completo");
  // As 2 primeiras já existiam (não recriadas); as outras 6 + todas as faixas foram criadas agora.
  assert.equal(res.data.resumo.ja_existiam, 2);
  assert.equal(res.data.resumo.criadas, TOTAL_MODALIDADES - 2 + TOTAL_FAIXAS);

  const modalidades = await lerModalidades(academiaId);
  assert.equal(modalidades.length, TOTAL_MODALIDADES);
});

test("faixas parcialmente inicializadas: completa só as faixas que faltam, sem duplicar as existentes", async () => {
  const academiaId = "academia-faixas-parciais";
  const { uid, email } = await criarAdmin(academiaId);
  await criarAcademia(academiaId, uid);

  const def = MODALIDADES_PADRAO[0]; // Jiu-Jitsu Adulto, 5 faixas
  await environment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await firestore.doc(`academias/${academiaId}/modalidades/${def.chave}`).set({
      id: def.chave,
      chave_padrao: def.chave,
      nome: def.nome,
      cor: def.cor,
      ativo: true,
    });
    // Só a primeira faixa (Branca) já existe.
    const primeira = def.faixas[0];
    await firestore.doc(`academias/${academiaId}/faixas/${def.chave}_${primeira.ordem}`).set({
      id: `${def.chave}_${primeira.ordem}`,
      chave_padrao: `${def.chave}_${primeira.ordem}`,
      modalidadeId: def.chave,
      nome: primeira.nome,
      cor: primeira.cor,
      ordem: primeira.ordem,
    });
  });

  await chamarInicializar(uid, email, { academiaId });

  const faixas = await lerFaixas(academiaId);
  const faixasDaModalidade = faixas.filter((f) => f.modalidadeId === def.chave);
  assert.equal(faixasDaModalidade.length, def.faixas.length);
  // sem duplicata da faixa Branca
  const brancas = faixasDaModalidade.filter((f) => f.nome === "Branca");
  assert.equal(brancas.length, 1);
});

test("academia legada com IDs aleatórios: vincula por nome+cor em vez de duplicar", async () => {
  const academiaId = "academia-legada-ids-aleatorios";
  const { uid, email } = await criarAdmin(academiaId);
  await criarAcademia(academiaId, uid);

  const def = MODALIDADES_PADRAO[2]; // Muay Thai
  let idLegado;
  await environment.withSecurityRulesDisabled(async (context) => {
    const ref = await context.firestore().collection(`academias/${academiaId}/modalidades`).add({
      nome: def.nome,
      cor: def.cor,
      ativo: true,
      // SEM chave_padrao — simula doc criado pelo mobile antes desta function existir.
    });
    idLegado = ref.id;
  });

  const res = await chamarInicializar(uid, email, { academiaId });
  assert.equal(res.data.status, "completo");

  const modalidades = await lerModalidades(academiaId);
  const muayThai = modalidades.filter((m) => m.nome === "Muay Thai");
  assert.equal(muayThai.length, 1, "não deve duplicar a modalidade legada");
  assert.equal(muayThai[0].id, idLegado, "deve manter o ID aleatório original, não criar um novo");
  assert.equal(muayThai[0].chave_padrao, def.chave, "deve marcar o doc legado com a chave padrão");

  // Faixas da Muay Thai devem ter sido criadas apontando pro ID LEGADO, não pro `def.chave`.
  const faixas = await lerFaixas(academiaId);
  const faixasMuayThai = faixas.filter((f) => f.modalidadeId === idLegado);
  assert.equal(faixasMuayThai.length, def.faixas.length);
});

test("modalidade existente com nome personalizado: não duplica, não adivinha, registra pendência", async () => {
  const academiaId = "academia-nome-personalizado";
  const { uid, email } = await criarAdmin(academiaId);
  await criarAcademia(academiaId, uid);

  // Academia renomeou "Jiu-Jitsu Adulto" pra só "Jiu-Jitsu" — não bate com
  // o nome padrão normalizado, então a function não pode saber com certeza
  // que é a mesma coisa.
  let idPersonalizado;
  await environment.withSecurityRulesDisabled(async (context) => {
    const ref = await context.firestore().collection(`academias/${academiaId}/modalidades`).add({
      nome: "Jiu-Jitsu",
      cor: "#1565C0",
      ativo: true,
    });
    idPersonalizado = ref.id;
  });

  const res = await chamarInicializar(uid, email, { academiaId });
  assert.equal(res.data.status, "pendente_revisao");
  assert.ok(res.data.pendencias.some((p) => p.tipo === "modalidade" && p.chave === "jiu_jitsu_adulto"));

  const modalidades = await lerModalidades(academiaId);
  // doc personalizado continua intocado...
  const personalizado = modalidades.find((m) => m.id === idPersonalizado);
  assert.equal(personalizado.nome, "Jiu-Jitsu");
  assert.equal(personalizado.chave_padrao, undefined);
  // ...e NENHUM novo doc "Jiu-Jitsu Adulto" foi criado por cima.
  assert.ok(!modalidades.some((m) => m.nome === "Jiu-Jitsu Adulto"));

  const academia = await lerAcademia(academiaId);
  assert.equal(academia.modalidades_status, "pendente_revisao");
});

test("pendente_revisao nunca é reprocessado automaticamente, só com forcarReexecucao", async () => {
  const academiaId = "academia-pendente-revisao-nao-reprocessa";
  const { uid, email } = await criarAdmin(academiaId);
  await criarAcademia(academiaId, uid);

  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().collection(`academias/${academiaId}/modalidades`).add({
      nome: "Jiu-Jitsu",
      cor: "#1565C0",
      ativo: true,
    });
  });

  const res1 = await chamarInicializar(uid, email, { academiaId });
  assert.equal(res1.data.status, "pendente_revisao");

  const res2 = await chamarInicializar(uid, email, { academiaId });
  assert.equal(res2.data.jaEstavaCompleto, true);
  assert.equal(res2.data.status, "pendente_revisao");

  const modalidades = await lerModalidades(academiaId);
  // o doc personalizado "Jiu-Jitsu" continua sozinho, sem nenhum
  // "Jiu-Jitsu Adulto" criado por cima dele na reexecução automática.
  assert.equal(modalidades.filter((m) => normalizarTexto(m.nome) === "jiu-jitsu").length, 1);
  assert.ok(!modalidades.some((m) => normalizarTexto(m.nome) === normalizarTexto("Jiu-Jitsu Adulto")));
});

test("duas inicializações simultâneas não duplicam modalidades nem faixas", async () => {
  const academiaId = "academia-concorrencia";
  const { uid, email } = await criarAdmin(academiaId);
  await criarAcademia(academiaId, uid);

  await signInWithEmailAndPassword(getAuth(app), email, "SenhaFixture123");
  const fn = httpsCallable(getFunctions(app), "inicializarModalidadesPadrao");

  const [r1, r2] = await Promise.all([fn({ academiaId }), fn({ academiaId })]);
  assert.ok(["completo"].includes(r1.data.status) || r1.data.jaEstavaCompleto);
  assert.ok(["completo"].includes(r2.data.status) || r2.data.jaEstavaCompleto);

  const modalidades = await lerModalidades(academiaId);
  const faixas = await lerFaixas(academiaId);
  assert.equal(modalidades.length, TOTAL_MODALIDADES);
  assert.equal(faixas.length, TOTAL_FAIXAS);
});

test("sem permissão: usuário que não é Admin da academia é rejeitado, nada é criado", async () => {
  const academiaId = "academia-sem-permissao";
  const { uid: donoUid } = await criarAdmin(academiaId);
  await criarAcademia(academiaId, donoUid);

  contadorUid += 1;
  const emailIntruso = `intruso-${contadorUid}@example.invalid`;
  await createUserWithEmailAndPassword(getAuth(app), emailIntruso, "SenhaFixture123");
  await signInWithEmailAndPassword(getAuth(app), emailIntruso, "SenhaFixture123");

  const fn = httpsCallable(getFunctions(app), "inicializarModalidadesPadrao");
  await assert.rejects(fn({ academiaId }), (erro) => erro.code === "functions/permission-denied");

  const modalidades = await lerModalidades(academiaId);
  assert.equal(modalidades.length, 0);
});

test("cadastro sem duplicação: academia e admin seguem únicos mesmo após retry da inicialização", async () => {
  const academiaId = "academia-sem-duplicacao-admin";
  const { uid, email } = await criarAdmin(academiaId);
  await criarAcademia(academiaId, uid);

  await chamarInicializar(uid, email, { academiaId });
  await chamarInicializar(uid, email, { academiaId, forcarReexecucao: true });

  let academiasSnap;
  await environment.withSecurityRulesDisabled(async (context) => {
    academiasSnap = await context.firestore().collection("academias").where("created_by_uid", "==", uid).get();
  });
  assert.equal(academiasSnap.docs.length, 1, "retry não deve criar segunda academia");
});
