#!/usr/bin/env node
"use strict";

/**
 * Backfill de `modalidade_nome` em cobranças (`pagamentos`) geradas pelo
 * modo por-modalidade antes desse campo existir.
 *
 * Causa raiz corrigida em `ensureChargesPorModalidade`
 * (functions/finance-functions.js): a função sempre escreveu
 * `modalidade_id`, mas nunca resolvia o nome legível da modalidade, então
 * no Financeiro duas mensalidades do mesmo aluno em turmas diferentes
 * (ex.: Jiu-Jitsu e Judô) apareciam idênticas. Esse script preenche
 * `modalidade_nome` nas cobranças já geradas, resolvendo via
 * `academias/{id}/modalidades`.
 *
 * Por padrão apenas analisa e gera relatório:
 *   node backfill-modalidade-nome-pagamentos.js
 *
 * Para aplicar depois de revisar o relatório:
 *   node backfill-modalidade-nome-pagamentos.js --apply
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
    totals: { academias: 0, cobrancasSemNome: 0, resolvidas: 0, semModalidadeValida: 0 },
    detalhes: [],
  };

  const academiasSnap = await db.collection("academias").get();

  for (const academiaDoc of academiasSnap.docs) {
    const academiaId = academiaDoc.id;
    const pagamentosSnap = await academiaDoc.ref
      .collection("pagamentos")
      .where("modalidade_id", "!=", "")
      .get();

    const modalidadesSnap = await academiaDoc.ref.collection("modalidades").get();
    const nomePorModalidade = new Map(
      modalidadesSnap.docs.map((doc) => [doc.id, doc.data().nome || null]),
    );

    let batch = db.batch();
    let opsNoBatch = 0;
    const academiaResolvidas = [];

    for (const pagamentoDoc of pagamentosSnap.docs) {
      const data = pagamentoDoc.data();
      const modalidadeId = String(data.modalidade_id || "").trim();
      const modalidadeNomeAtual = String(data.modalidade_nome || "").trim();
      if (!modalidadeId || modalidadeNomeAtual) continue;

      report.totals.cobrancasSemNome++;
      const nomeResolvido = nomePorModalidade.get(modalidadeId);
      if (!nomeResolvido) {
        report.totals.semModalidadeValida++;
        continue;
      }

      academiaResolvidas.push({
        pagamentoId: pagamentoDoc.id,
        alunoId: data.aluno_id || null,
        modalidadeId,
        modalidadeNomeResolvido: nomeResolvido,
      });
      report.totals.resolvidas++;

      if (apply) {
        batch.update(pagamentoDoc.ref, { modalidade_nome: nomeResolvido });
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
      report.detalhes.push({ academiaId, pagamentos: academiaResolvidas });
    }
  }

  const reportPath = path.join(__dirname, "modalidade-nome-pagamentos-backfill-report.json");
  fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
  console.log(JSON.stringify(report.totals, null, 2));
  console.log(`Relatório: ${reportPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
