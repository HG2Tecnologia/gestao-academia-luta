#!/usr/bin/env node
"use strict";

/**
 * Calcula e grava turmas_ativas_contagem, alunos_ativos_contagem e
 * funcionarios_contagem em TODAS as academias, a partir da contagem real
 * das subcoleções — necessário rodar isso UMA VEZ antes de confiar nesses
 * campos nas Firestore rules (sem backfill, toda academia nasceria com os
 * contadores em 0, mesmo já tendo turmas/alunos/funcionários de verdade).
 *
 * Read + write. Uso:
 *   node backfill-contadores-plano.js            # todas as academias
 *   node backfill-contadores-plano.js <academiaId>  # só uma, pra conferir
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

const academiaIdFiltro = process.argv[2] || null;

async function contarTurmasAtivas(academiaRef) {
  const snap = await academiaRef.collection("turmas").where("ativo", "==", true).count().get();
  return snap.data().count;
}

async function contarAlunosAtivos(academiaRef) {
  const snap = await academiaRef
    .collection("usuarios")
    .where("perfil", "==", 3)
    .where("ativo", "==", true)
    .count()
    .get();
  return snap.data().count;
}

async function contarFuncionarios(academiaRef) {
  const snap = await academiaRef.collection("funcionarios").count().get();
  return snap.data().count;
}

async function processarAcademia(ref) {
  const [turmas, alunos, funcionarios] = await Promise.all([
    contarTurmasAtivas(ref),
    contarAlunosAtivos(ref),
    contarFuncionarios(ref),
  ]);
  await ref.update({
    turmas_ativas_contagem: turmas,
    alunos_ativos_contagem: alunos,
    funcionarios_contagem: funcionarios,
  });
  return { id: ref.id, turmas, alunos, funcionarios };
}

async function main() {
  const refs = academiaIdFiltro
    ? [db.collection("academias").doc(academiaIdFiltro)]
    : await db.collection("academias").listDocuments();

  console.log(`Processando ${refs.length} academia(s)...`);
  let ok = 0;
  for (const ref of refs) {
    try {
      const r = await processarAcademia(ref);
      console.log(
        `✓ ${r.id}  turmas=${r.turmas}  alunos=${r.alunos}  funcionarios=${r.funcionarios}`,
      );
      ok++;
    } catch (e) {
      console.error(`✗ ${ref.id}  erro: ${e.message}`);
    }
  }
  console.log(`\nConcluído: ${ok}/${refs.length} academias atualizadas.`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
