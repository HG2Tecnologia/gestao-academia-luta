"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const { canonicalizePhone, canonicalPhoneDigits } = require("../domain/phone-normalizer");
const {
  authEmailMatchesIdentifier,
  buildAccountDocument,
  profileRole,
  syntheticAuthEmails,
} = require("../domain/account");
const {
  addBillingMonths,
  dueDateForPeriod,
  monthLabelPtBr,
  monthlyChargeDocumentId,
  resolveChargeStatus,
  resolveDuplicateGroup,
} = require("../domain/billing");
const { decidirAcaoContasCompartilhadas } = require("../domain/access-provisioning");

function fixture(name) {
  const file = path.join(__dirname, "..", "..", "test-fixtures", "domain", name);
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

for (const item of fixture("phone_normalization_cases.json")) {
  test(`telefone: ${item.name}`, () => {
    assert.equal(canonicalizePhone(item.input), item.expected);
  });
}

test("telefone: representação somente com dígitos deriva do canônico", () => {
  assert.equal(canonicalPhoneDigits("(21) 99999-9999"), "5521999999999");
});

for (const item of fixture("billing_cases.json")) {
  test(`financeiro: ${item.name}`, () => {
    assert.equal(resolveChargeStatus(item), item.expected);
  });
}

test("financeiro: competência navega entre anos", () => {
  assert.equal(addBillingMonths("2026-01", -1), "2025-12");
  assert.equal(addBillingMonths("2026-12", 1), "2027-01");
});

test("financeiro: vencimento respeita último dia do mês", () => {
  assert.equal(dueDateForPeriod("2027-02", 31), "2027-02-28");
});

test("financeiro: id mensal é determinístico", () => {
  assert.equal(
    monthlyChargeDocumentId("student-a", "2026-09"),
    "mensalidade__student-a__2026-09",
  );
});

test("financeiro: grupo sem duplicata (0 ou 1 doc) não decide nada", () => {
  assert.deepEqual(resolveDuplicateGroup([]), { manterId: null, desconsiderarIds: [], ignorar: false });
  assert.deepEqual(resolveDuplicateGroup([{ id: "a", status: 0, criadoEmMillis: 1 }]), {
    manterId: "a",
    desconsiderarIds: [],
    ignorar: false,
  });
});

test("financeiro: duplicata com uma paga mantém a paga, desconsidera o resto", () => {
  const decisao = resolveDuplicateGroup([
    { id: "aleatorio-1", status: 0, criadoEmMillis: 100 },
    { id: "aleatorio-2", status: 1, criadoEmMillis: 200 },
  ]);
  assert.equal(decisao.manterId, "aleatorio-2");
  assert.deepEqual(decisao.desconsiderarIds, ["aleatorio-1"]);
  assert.equal(decisao.ignorar, false);
});

test("financeiro: duplicata sem nenhuma paga prefere o ID determinístico", () => {
  const decisao = resolveDuplicateGroup([
    { id: "aleatorio-1", status: 0, criadoEmMillis: 100 },
    { id: "mensalidade__aluno-1__2026-09", status: 0, criadoEmMillis: 200 },
  ]);
  assert.equal(decisao.manterId, "mensalidade__aluno-1__2026-09");
  assert.deepEqual(decisao.desconsiderarIds, ["aleatorio-1"]);
});

test("financeiro: duplicata sem paga nem ID determinístico mantém o mais antigo", () => {
  const decisao = resolveDuplicateGroup([
    { id: "criado-depois", status: 0, criadoEmMillis: 200 },
    { id: "criado-primeiro", status: 3, criadoEmMillis: 100 },
  ]);
  assert.equal(decisao.manterId, "criado-primeiro");
  assert.deepEqual(decisao.desconsiderarIds, ["criado-depois"]);
});

test("financeiro: duas pagas é ambíguo — não decide nada, fica pra revisão manual", () => {
  const decisao = resolveDuplicateGroup([
    { id: "pago-1", status: 1, criadoEmMillis: 100 },
    { id: "pago-2", status: 1, criadoEmMillis: 200 },
  ]);
  assert.equal(decisao.ignorar, true);
  assert.equal(decisao.manterId, null);
  assert.deepEqual(decisao.desconsiderarIds, []);
});

test("financeiro: três duplicadas, uma paga — as outras duas somem", () => {
  const decisao = resolveDuplicateGroup([
    { id: "a", status: 0, criadoEmMillis: 100 },
    { id: "b", status: 1, criadoEmMillis: 200 },
    { id: "c", status: 3, criadoEmMillis: 300 },
  ]);
  assert.equal(decisao.manterId, "b");
  assert.deepEqual(decisao.desconsiderarIds.sort(), ["a", "c"]);
});

test("identidade: telefone aceita email sintético canônico e legado", () => {
  assert.deepEqual(
    syntheticAuthEmails("(21) 99999-9999"),
    ["5521999999999@sensei.app", "21999999999@sensei.app"],
  );
  assert.equal(
    authEmailMatchesIdentifier("21999999999@sensei.app", "+55 21 99999-9999"),
    true,
  );
});

test("identidade: conta v2 mantém papéis isolados por academia", () => {
  const account = buildAccountDocument({
    uid: "account-a",
    primaryProfileKey: "academy-a|funcionarios|admin-a",
    emailCanonical: "RESPONSAVEL@EXAMPLE.COM",
    profiles: [
      {
        academiaId: "academy-a",
        usuarioId: "admin-a",
        colecao: "funcionarios",
        perfil_nome: "Admin",
        nome: "Responsável",
      },
      {
        academiaId: "academy-b",
        usuarioId: "student-b",
        colecao: "usuarios",
        perfil_nome: "Aluno",
        nome: "Filha",
      },
    ],
  });

  assert.equal(account.schemaVersion, 2);
  assert.deepEqual(account.academy_ids, ["academy-a", "academy-b"]);
  assert.deepEqual(account.roles_by_academy, {
    "academy-a": ["Admin"],
    "academy-b": ["Aluno"],
  });
  assert.equal(account.perfil, "Admin");
  assert.equal(account.email_canonical, "responsavel@example.com");
});

test("identidade: reconhece papéis legados sem transformar aluno em admin", () => {
  assert.equal(profileRole("usuarios", { perfil: 0 }), "Admin");
  assert.equal(profileRole("usuarios", { perfil: 3 }), "Aluno");
  assert.equal(profileRole("usuarios", { perfil: 0, perfil_nome: "Aluno" }), "Aluno");
  assert.equal(profileRole("usuarios", { perfil: 99 }), null);
  assert.equal(profileRole("funcionarios", {}), "Professor");
});

// Bug reportado: cadastrar um aluno novo com o mesmo telefone/e-mail de outro
// aluno que já tinha definido a própria senha derrubava o acesso de ambos
// (a senha temporária nova sobrescrevia a conta Auth compartilhada). A
// correção só entra em ação no provisionamento automático (criação/edição),
// nunca num clique explícito em "Redefinir senha".
test("provisionamento: sobrescreve normalmente quando ninguém do grupo já tem senha própria", () => {
  assert.equal(
    decidirAcaoContasCompartilhadas({ motivo: "provisao_criacao", algumJaDefiniuSenha: false }),
    "sobrescrever",
  );
});

test("provisionamento: bloqueia e devolve pro cliente quando já existe senha própria definida", () => {
  assert.equal(
    decidirAcaoContasCompartilhadas({ motivo: "provisao_criacao", algumJaDefiniuSenha: true }),
    "bloquear",
  );
  assert.equal(
    decidirAcaoContasCompartilhadas({ motivo: "provisao_edicao", algumJaDefiniuSenha: true }),
    "bloquear",
  );
});

test("provisionamento: redefinição explícita nunca bloqueia, mesmo com senha própria definida", () => {
  assert.equal(
    decidirAcaoContasCompartilhadas({ motivo: "redefinicao", algumJaDefiniuSenha: true }),
    "sobrescrever",
  );
});

test("provisionamento: 2ª chamada com confirmarSobrescrita ignora o bloqueio", () => {
  assert.equal(
    decidirAcaoContasCompartilhadas({
      motivo: "provisao_criacao",
      algumJaDefiniuSenha: true,
      confirmarSobrescrita: true,
    }),
    "sobrescrever",
  );
});

test("financeiro: rótulo de mês em português usado nas notificações", () => {
  assert.equal(monthLabelPtBr("2026-10"), "outubro/2026");
  assert.equal(monthLabelPtBr("2026-01"), "janeiro/2026");
  assert.equal(monthLabelPtBr("2026-12"), "dezembro/2026");
});

test("provisionamento: 2ª chamada com apenasVincular nunca sobrescreve, mesmo sem conflito", () => {
  assert.equal(
    decidirAcaoContasCompartilhadas({
      motivo: "provisao_criacao",
      algumJaDefiniuSenha: false,
      apenasVincular: true,
    }),
    "vincular_sem_senha",
  );
  assert.equal(
    decidirAcaoContasCompartilhadas({
      motivo: "provisao_criacao",
      algumJaDefiniuSenha: true,
      apenasVincular: true,
    }),
    "vincular_sem_senha",
  );
});
