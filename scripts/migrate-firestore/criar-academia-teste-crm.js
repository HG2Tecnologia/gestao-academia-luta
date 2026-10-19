#!/usr/bin/env node
"use strict";

/**
 * Cria uma academia de teste ISOLADA (`academia-teste-crm`) com 1 admin e
 * alguns alunos de exemplo (turma, faixa, pagamento em dia/atrasado) — só
 * pra validar visualmente as telas novas do CRM sem tocar em dado de
 * cliente real. Idempotente: pode rodar de novo, só sobrescreve os mesmos
 * docs de teste.
 *
 * Uso: node criar-academia-teste-crm.js
 */

const fs = require("node:fs");
const path = require("node:path");
const admin = require("firebase-admin");

const projectId = process.env.GCLOUD_PROJECT || "sensei-manager-d64c0";
const serviceAccountPath = path.join(__dirname, "serviceAccount.json");
const credential = fs.existsSync(serviceAccountPath)
  ? admin.credential.cert(require(serviceAccountPath))
  : admin.credential.applicationDefault();

admin.initializeApp({ credential, projectId });
const db = admin.firestore();
const auth = admin.auth();

const ACADEMIA_ID = "academia-teste-crm";
const ADMIN_EMAIL = "admin-teste-crm@sensei.app";
const ADMIN_SENHA = "TesteCrm123";

async function main() {
  const academiaRef = db.collection("academias").doc(ACADEMIA_ID);
  await academiaRef.set({ nome: "Academia Teste CRM", criado_em: admin.firestore.FieldValue.serverTimestamp() });

  // Admin (Firebase Auth + funcionarios + usuariosFirebase).
  let adminUser;
  try {
    adminUser = await auth.getUserByEmail(ADMIN_EMAIL);
    await auth.updateUser(adminUser.uid, { password: ADMIN_SENHA });
  } catch {
    adminUser = await auth.createUser({ email: ADMIN_EMAIL, password: ADMIN_SENHA });
  }
  const adminUid = adminUser.uid;

  await academiaRef.collection("funcionarios").doc("admin-teste").set({
    nome: "Admin Teste",
    email: ADMIN_EMAIL,
    perfil: "Admin",
    ativo: true,
    firebaseUid: adminUid,
  });
  await db.collection("usuariosFirebase").doc(adminUid).set({
    schemaVersion: 2,
    academiaId: ACADEMIA_ID,
    colecao: "funcionarios",
    usuarioId: "admin-teste",
    perfil: "Admin",
    nome: "Admin Teste",
    email: ADMIN_EMAIL,
    must_change_password: false,
    profile_refs: [
      {
        key: `${ACADEMIA_ID}|funcionarios|admin-teste`,
        academiaId: ACADEMIA_ID,
        colecao: "funcionarios",
        usuarioId: "admin-teste",
        perfil_nome: "Admin",
        nome: "Admin Teste",
      },
    ],
  });

  // Modalidade + turma + faixa.
  await academiaRef.collection("modalidades").doc("jiujitsu").set({ nome: "Jiu-Jitsu", ativo: true });
  await academiaRef.collection("turmas").doc("turma-adulto").set({
    nome: "Jiu-Jitsu Adulto",
    modalidadeId: "jiujitsu",
    ativo: true,
  });
  await academiaRef.collection("planos").doc("plano-mensal").set({
    nome: "Mensalidade Jiu-Jitsu",
    valor_mensal: 150,
    ativo: true,
  });

  // Aluno 1: em dia, matriculado, com faixa.
  await academiaRef.collection("usuarios").doc("aluno-1").set({
    nome: "Aluno Exemplo Um",
    telefone: "(11) 91234-5678",
    telefone_digits: "11912345678",
    email: "aluno1@teste.com",
    ativo: true,
    perfil: 3,
    perfil_nome: "Aluno",
    plano_id: "plano-mensal",
    plano_nome: "Mensalidade Jiu-Jitsu",
    data_nascimento: "2000-05-15",
    xp_total: 120,
    nivel: 2,
    faixaPrincipalModalidadeId: "jiujitsu",
    faixasAtuais: { jiujitsu: { faixaNome: "Azul", faixaCor: "#2563eb", grau: 1 } },
    criado_em: admin.firestore.FieldValue.serverTimestamp(),
  });
  await academiaRef.collection("matriculas").doc("matricula-1").set({
    aluno_id: "aluno-1",
    turma_id: "turma-adulto",
    ativo: true,
  });
  await academiaRef.collection("pagamentos").doc("pagamento-1").set({
    aluno_id: "aluno-1",
    tipo: "Mensalidade",
    plano_id: "plano-mensal",
    plano_nome: "Mensalidade Jiu-Jitsu",
    valor: 150,
    status: 1,
    data_vencimento: "2026-10-05",
    data_pagamento: "2026-10-03",
    mes_referencia: "2026-10",
  });

  // Aluno 2: inadimplente (cobrança vencida, nunca paga).
  await academiaRef.collection("usuarios").doc("aluno-2").set({
    nome: "Aluno Exemplo Dois",
    telefone: "(11) 98888-7777",
    telefone_digits: "11988887777",
    ativo: true,
    perfil: 3,
    perfil_nome: "Aluno",
    plano_id: "plano-mensal",
    plano_nome: "Mensalidade Jiu-Jitsu",
    xp_total: 0,
    nivel: 0,
    criado_em: admin.firestore.FieldValue.serverTimestamp(),
  });
  await academiaRef.collection("matriculas").doc("matricula-2").set({
    aluno_id: "aluno-2",
    turma_id: "turma-adulto",
    ativo: true,
  });
  await academiaRef.collection("pagamentos").doc("pagamento-2").set({
    aluno_id: "aluno-2",
    tipo: "Mensalidade",
    plano_id: "plano-mensal",
    plano_nome: "Mensalidade Jiu-Jitsu",
    valor: 150,
    status: 0,
    data_vencimento: "2026-09-05",
    mes_referencia: "2026-09",
  });

  // Aluno 3: inativo, sem turma.
  await academiaRef.collection("usuarios").doc("aluno-3").set({
    nome: "Aluno Exemplo Três (inativo)",
    telefone: "(11) 97777-6666",
    ativo: false,
    perfil: 3,
    perfil_nome: "Aluno",
    xp_total: 0,
    nivel: 0,
    criado_em: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log("Academia de teste pronta.");
  console.log(`Login do CRM: ${ADMIN_EMAIL} / ${ADMIN_SENHA}`);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
