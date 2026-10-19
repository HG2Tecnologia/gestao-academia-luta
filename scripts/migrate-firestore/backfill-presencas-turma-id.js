#!/usr/bin/env node
"use strict";

/**
 * Backfill de `turma_id` em presenças antigas que só têm `horario_id`.
 *
 * Causa raiz corrigida em `addPresenca` (mobile/lib/core/firestore_service.dart):
 * o check-in feito pelo professor escaneando o QR do aluno gravava a presença
 * sem `turma_id`, o que confundia o cálculo de frequência/faltas em
 * `frequencia_treino.dart` (uma presença sem turma_id "cobre" qualquer turma
 * naquele dia, mascarando ou distorcendo o cálculo de falta). Esse script
 * corrige o histórico já em produção resolvendo turma_id a partir do
 * horario_id salvo em cada presença.
 *
 * Por padrão apenas analisa e gera relatório:
 *   node backfill-presencas-turma-id.js
 *
 * Para aplicar depois de revisar o relatório:
 *   node backfill-presencas-turma-id.js --apply
 */

const fs = require("node:fs");
const path = require("node:path");
const admin = require("firebase-admin");

const apply = process.argv.includes("--apply");
const projectId = process.env.GCLOUD_PROJECT || "sensei-manager-d64c0";
const serviceAccountPath = path.join(__dirname, "serviceAccount.json");
const credential = fs.existsSync(serviceAccountPath)
  ? admin.credential.cert(require(serviceAccountPath))
  : admin.credential.applicationDefault();

admin.initializeApp({ credential, projectId });
const db = admin.firestore();

async function main() {
  console.log(apply ? "APLICAÇÃO habilitada" : "DRY-RUN: nenhum documento será alterado");

  const report = {
    totals: { academias: 0, presencasSemTurma: 0, resolvidas: 0, semHorarioValido: 0 },
    detalhes: [],
  };

  const academiasSnap = await db.collection("academias").get();

  for (const academiaDoc of academiasSnap.docs) {
    const academiaId = academiaDoc.id;
    const presencasSnap = await academiaDoc.ref.collection("presencas").get();

    // Cache de horarios da academia pra não bater no Firestore por presença.
    const horariosSnap = await academiaDoc.ref.collection("horarios").get();
    const turmaIdPorHorario = new Map(
      horariosSnap.docs.map((doc) => [doc.id, doc.data().turma_id || null]),
    );

    let batch = db.batch();
    let opsNoBatch = 0;
    const academiaResolvidas = [];

    for (const presencaDoc of presencasSnap.docs) {
      const data = presencaDoc.data();
      const turmaId = String(data.turma_id || "").trim();
      const horarioId = String(data.horario_id || "").trim();
      if (turmaId || !horarioId) continue;

      report.totals.presencasSemTurma++;
      const turmaIdResolvido = turmaIdPorHorario.get(horarioId);
      if (!turmaIdResolvido) {
        report.totals.semHorarioValido++;
        continue;
      }

      academiaResolvidas.push({
        presencaId: presencaDoc.id,
        alunoId: data.aluno_id || null,
        horarioId,
        turmaIdResolvido,
      });
      report.totals.resolvidas++;

      if (apply) {
        batch.update(presencaDoc.ref, { turma_id: turmaIdResolvido });
        opsNoBatch++;
        if (opsNoBatch >= 400) {
          await batch.commit();
          batch = db.batch();
          opsNoBatch = 0;
        }
      }
    }

    if (apply && opsNoBatch > 0) await batch.commit();
    if (academiaResolvidas.length > 0) {
      report.totals.academias++;
      report.detalhes.push({ academiaId, presencas: academiaResolvidas });
    }
  }

  const reportPath = path.join(__dirname, "presencas-turma-id-backfill-report.json");
  fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
  console.log(JSON.stringify(report.totals, null, 2));
  console.log(`Relatório: ${reportPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
