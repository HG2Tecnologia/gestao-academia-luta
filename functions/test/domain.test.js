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
  monthlyChargeDocumentId,
  resolveChargeStatus,
} = require("../domain/billing");

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
