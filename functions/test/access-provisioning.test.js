"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  loginIdentifiers,
  primaryLoginEmail,
  identityForAuthEmail,
  loginHint,
} = require("../domain/access-provisioning");

test("loginIdentifiers: telefone + e-mail geram todos os e-mails de login", () => {
  const r = loginIdentifiers({
    email: "Mae@Gmail.com",
    telefone: "(88) 99678-0298",
  });
  assert.equal(r.realEmail, "mae@gmail.com");
  assert.equal(r.phoneCanonical, "+5588996780298");
  // e-mail real + sintético E.164 + sintético nacional, sem duplicatas
  assert.deepEqual(r.authEmails, [
    "mae@gmail.com",
    "5588996780298@sensei.app",
    "88996780298@sensei.app",
  ]);
});

test("loginIdentifiers: só telefone (irmão sem e-mail)", () => {
  const r = loginIdentifiers({ telefone_digits: "88996780298" });
  assert.equal(r.realEmail, null);
  assert.deepEqual(r.authEmails, [
    "5588996780298@sensei.app",
    "88996780298@sensei.app",
  ]);
});

test("loginIdentifiers: sem contato nenhum", () => {
  const r = loginIdentifiers({ nome: "Aluno Sem Contato" });
  assert.equal(r.realEmail, null);
  assert.equal(r.phoneCanonical, null);
  assert.deepEqual(r.authEmails, []);
});

test("primaryLoginEmail: telefone tem prioridade sobre e-mail", () => {
  assert.equal(
    primaryLoginEmail({ realEmail: "x@y.com", phoneCanonical: "+5521999998888" }),
    "5521999998888@sensei.app",
  );
  assert.equal(
    primaryLoginEmail({ realEmail: "x@y.com", phoneCanonical: null }),
    "x@y.com",
  );
  assert.equal(primaryLoginEmail({ realEmail: null, phoneCanonical: null }), null);
});

test("identityForAuthEmail: sintético -> telefone canônico; real -> e-mail", () => {
  assert.equal(identityForAuthEmail("5521999998888@sensei.app"), "+5521999998888");
  assert.equal(identityForAuthEmail("Pai@Gmail.com"), "pai@gmail.com");
  assert.equal(identityForAuthEmail(""), null);
});

test("loginHint: prioriza telefone e usa o formato cru quando disponível", () => {
  assert.equal(
    loginHint({ realEmail: "x@y.com", phoneCanonical: "+5521999998888" }, "(21) 99999-8888"),
    "telefone (21) 99999-8888",
  );
  assert.equal(
    loginHint({ realEmail: "x@y.com", phoneCanonical: null }, null),
    "e-mail x@y.com",
  );
});
