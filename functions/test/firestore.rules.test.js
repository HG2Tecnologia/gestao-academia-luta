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

test("nem o Admin da academia lê ou escreve a subcoleção _atribuicao pelo cliente", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("usuariosFirebase/admin-fixture").set({
      schemaVersion: 2,
      academiaId: "academy-fixture",
      perfil: "Admin",
      academy_ids: ["academy-fixture"],
      roles_by_academy: { "academy-fixture": ["Admin"] },
    });
    await context.firestore().doc("academias/academy-fixture/_atribuicao/dados").set({
      classificacao: "identificada",
      utm_source: "google",
    });
  });
  const firestore = environment.authenticatedContext("admin-fixture").firestore();

  await assertFails(
    firestore.doc("academias/academy-fixture/_atribuicao/dados").get(),
  );
  await assertFails(
    firestore.doc("academias/academy-fixture/_atribuicao/dados").set({ utm_source: "forjado" }),
  );
});

test("Admin não consegue se auto-conceder o plano Pro escrevendo plano_tipo direto na academia", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("usuariosFirebase/admin-plano-fixture").set({
      schemaVersion: 2,
      academiaId: "academy-fixture",
      perfil: "Admin",
      academy_ids: ["academy-fixture"],
      roles_by_academy: { "academy-fixture": ["Admin"] },
    });
  });
  const firestore = environment.authenticatedContext("admin-plano-fixture").firestore();

  await assertFails(
    firestore.doc("academias/academy-fixture").update({ plano_tipo: 1 }),
  );
  await assertFails(
    firestore.doc("academias/academy-fixture").update({
      plano_tipo: 1,
      plano_expiracao: "2099-01-01T00:00:00.000Z",
      plano_plataforma: "ios",
    }),
  );
  // Mistura um campo legítimo com um protegido — ainda tem que barrar, não
  // basta escrever todos os campos legítimos que quiser desde que nenhum
  // protegido esteja junto.
  await assertFails(
    firestore.doc("academias/academy-fixture").update({
      nome: "Nome Novo",
      plano_ambiente: "production",
    }),
  );
});

test("Admin continua editando normalmente os outros campos da academia (não regride)", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("usuariosFirebase/admin-plano-fixture-2").set({
      schemaVersion: 2,
      academiaId: "academy-fixture",
      perfil: "Admin",
      academy_ids: ["academy-fixture"],
      roles_by_academy: { "academy-fixture": ["Admin"] },
    });
  });
  const firestore = environment.authenticatedContext("admin-plano-fixture-2").firestore();

  await assertSucceeds(
    firestore.doc("academias/academy-fixture").update({
      nome: "Nome Atualizado",
      telefone: "21999998888",
    }),
  );
});

test("plano gratuito: Admin cria a 1ª turma mas a 2ª é barrada pelo limite", async () => {
  // O emulador deste teste só roda Firestore/Auth, não as Cloud Functions —
  // então o contador não incrementa sozinho como incrementaria em produção
  // (manterContagemTurmasAtivas). Simula o resultado dessa function direto
  // via withSecurityRulesDisabled, igual já fazemos pro teste de alunos.
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("usuariosFirebase/admin-limite-turmas").set({
      schemaVersion: 2,
      academiaId: "academy-fixture",
      perfil: "Admin",
      academy_ids: ["academy-fixture"],
      roles_by_academy: { "academy-fixture": ["Admin"] },
    });
  });
  const firestore = environment.authenticatedContext("admin-limite-turmas").firestore();

  await assertSucceeds(
    firestore.doc("academias/academy-fixture/turmas/turma-1").set({ nome: "Turma 1", ativo: true }),
  );
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("academias/academy-fixture").update({ turmas_ativas_contagem: 1 });
  });
  await assertFails(
    firestore.doc("academias/academy-fixture/turmas/turma-2").set({ nome: "Turma 2", ativo: true }),
  );
});

test("plano gratuito: turma extra é permitida quando academia é Pro", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("academias/academy-fixture").update({ plano_tipo: 1 });
    await context.firestore().doc("usuariosFirebase/admin-pro-turmas").set({
      schemaVersion: 2,
      academiaId: "academy-fixture",
      perfil: "Admin",
      academy_ids: ["academy-fixture"],
      roles_by_academy: { "academy-fixture": ["Admin"] },
    });
  });
  const firestore = environment.authenticatedContext("admin-pro-turmas").firestore();

  await assertSucceeds(
    firestore.doc("academias/academy-fixture/turmas/turma-1").set({ nome: "Turma 1", ativo: true }),
  );
  await assertSucceeds(
    firestore.doc("academias/academy-fixture/turmas/turma-2").set({ nome: "Turma 2", ativo: true }),
  );
});

test("plano gratuito: 6º aluno é barrado pelo limite de 5", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("academias/academy-fixture").update({ alunos_ativos_contagem: 5 });
    await context.firestore().doc("usuariosFirebase/admin-limite-alunos").set({
      schemaVersion: 2,
      academiaId: "academy-fixture",
      perfil: "Admin",
      academy_ids: ["academy-fixture"],
      roles_by_academy: { "academy-fixture": ["Admin"] },
    });
  });
  const firestore = environment.authenticatedContext("admin-limite-alunos").firestore();

  await assertFails(
    firestore.doc("academias/academy-fixture/usuarios/aluno-6").set({
      nome: "Aluno 6",
      perfil: 3,
      ativo: true,
    }),
  );
});

test("plano gratuito: funcionário extra é barrado pelo limite de 1", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("usuariosFirebase/admin-limite-equipe").set({
      schemaVersion: 2,
      academiaId: "academy-fixture",
      perfil: "Admin",
      academy_ids: ["academy-fixture"],
      roles_by_academy: { "academy-fixture": ["Admin"] },
    });
  });
  const firestore = environment.authenticatedContext("admin-limite-equipe").firestore();

  await assertSucceeds(
    firestore.doc("academias/academy-fixture/funcionarios/func-1").set({ nome: "Func 1" }),
  );
  // Mesmo motivo do teste de turmas: simula aqui o que
  // manterContagemFuncionarios faria em produção.
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("academias/academy-fixture").update({ funcionarios_contagem: 1 });
  });
  await assertFails(
    firestore.doc("academias/academy-fixture/funcionarios/func-2").set({ nome: "Func 2" }),
  );
});

test("Admin não consegue zerar os contadores de limite de plano direto na academia", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc("academias/academy-fixture").update({ turmas_ativas_contagem: 1 });
    await context.firestore().doc("usuariosFirebase/admin-contador-fixture").set({
      schemaVersion: 2,
      academiaId: "academy-fixture",
      perfil: "Admin",
      academy_ids: ["academy-fixture"],
      roles_by_academy: { "academy-fixture": ["Admin"] },
    });
  });
  const firestore = environment.authenticatedContext("admin-contador-fixture").firestore();

  await assertFails(
    firestore.doc("academias/academy-fixture").update({ turmas_ativas_contagem: 0 }),
  );
});

test("regressão: se a proteção dos campos de plano sumir da regra, a escrita REABRE (prova que ela é necessária)", async () => {
  // Mesmo espírito do teste de regressão de `_atribuicao` acima: aplica uma
  // cópia DELIBERADAMENTE REGREDIDA das regras (remove só a condição extra
  // de `camposPlanoProtegidos()`, voltando ao `allow update` original) pra
  // provar que, sem ela, qualquer Admin volta a conseguir se auto-conceder
  // o plano Pro.
  const rulesPath = path.join(__dirname, "..", "..", "scripts", "migrate-firestore", "firestore.rules");
  const rulesOriginais = fs.readFileSync(rulesPath, "utf8");
  const rulesRegredidas = rulesOriginais.replace(
    "allow update: if isAdminOuSecretaria(academiaId) &&\n        !request.resource.data.diff(resource.data).affectedKeys()\n          .hasAny(camposPlanoProtegidos());",
    "allow update: if isAdminOuSecretaria(academiaId);",
  );

  if (rulesRegredidas === rulesOriginais) {
    throw new Error("A regressão simulada não alterou o arquivo de regras — teste inválido.");
  }

  const projectIdRegressao = "sensei-manager-test-regressao-plano";
  const ambienteRegredido = await initializeTestEnvironment({
    projectId: projectIdRegressao,
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: rulesRegredidas,
    },
  });

  try {
    await ambienteRegredido.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc("academias/academy-fixture").set({ nome: "Academia Fixture" });
      await context.firestore().doc("usuariosFirebase/admin-regressao-plano").set({
        schemaVersion: 2,
        academiaId: "academy-fixture",
        perfil: "Admin",
        academy_ids: ["academy-fixture"],
        roles_by_academy: { "academy-fixture": ["Admin"] },
      });
    });
    const firestore = ambienteRegredido.authenticatedContext("admin-regressao-plano").firestore();

    await assertSucceeds(
      firestore.doc("academias/academy-fixture").update({ plano_tipo: 1 }),
    );
  } finally {
    await ambienteRegredido.cleanup();
  }
});

test("regressão: se a exclusão de _atribuicao sumir do match genérico, o acesso REABRE (prova que a proteção depende dos dois blocos)", async () => {
  // Isto não testa o `firestore.rules` real do projeto — testa uma cópia
  // DELIBERADAMENTE REGREDIDA (remove só a exclusão de '_atribuicao' do
  // match genérico "resto", mantendo o match específico com
  // `allow read, write: if false` intacto) pra provar que, SOZINHO, o
  // bloco específico não basta. Isso é a demonstração concreta do aviso
  // escrito no topo do bloco `_atribuicao` do arquivo real: um rollback
  // que restaure só metade da proteção reabre o acesso.
  const rulesPath = path.join(__dirname, "..", "..", "scripts", "migrate-firestore", "firestore.rules");
  const rulesOriginais = fs.readFileSync(rulesPath, "utf8");
  const rulesRegredidas = rulesOriginais
    .replace("colecao != '_atribuicao' && pertenceAcademia(academiaId)", "pertenceAcademia(academiaId)")
    .replace("colecao in ['usuarios', 'funcionarios', '_atribuicao']", "colecao in ['usuarios', 'funcionarios']");

  // Confirma que a substituição realmente mudou o texto (senão o teste
  // passaria por engano, sem provar nada).
  if (rulesRegredidas === rulesOriginais) {
    throw new Error("A regressão simulada não alterou o arquivo de regras — teste inválido.");
  }

  const projectIdRegressao = "sensei-manager-test-regressao";
  const ambienteRegredido = await initializeTestEnvironment({
    projectId: projectIdRegressao,
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: rulesRegredidas,
    },
  });

  try {
    await ambienteRegredido.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc("usuariosFirebase/admin-regressao").set({
        schemaVersion: 2,
        academiaId: "academy-fixture",
        perfil: "Admin",
        academy_ids: ["academy-fixture"],
        roles_by_academy: { "academy-fixture": ["Admin"] },
      });
      await context.firestore().doc("academias/academy-fixture/_atribuicao/dados").set({
        classificacao: "identificada",
      });
    });
    const firestore = ambienteRegredido.authenticatedContext("admin-regressao").firestore();

    // Com a regressão, a leitura TEM que suceder — é isso que prova que a
    // exclusão no match genérico é indispensável, não redundante.
    await assertSucceeds(firestore.doc("academias/academy-fixture/_atribuicao/dados").get());
  } finally {
    await ambienteRegredido.cleanup();
  }
});
