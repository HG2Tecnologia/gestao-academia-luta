#!/usr/bin/env node
"use strict";

/**
 * Diagnostica (e, com --apply, corrige quando é seguro) alunos ativos sem
 * nenhum "plano por modalidade" em academias que já ativaram
 * `cobranca_por_modalidade_ativa`.
 *
 * Causa raiz: nesse modo, `ensureChargesPorModalidade`
 * (functions/finance-functions.js) só gera cobrança pra quem tem doc em
 * `planos_modalidade` — um aluno sem isso simplesmente PARA de ser cobrado
 * todo mês seguinte, mesmo ainda tendo `plano_id` legado preenchido (esse
 * campo é ignorado nesse modo). É por isso que alguns alunos aparecem no
 * Financeiro sem o badge de modalidade: a cobrança dele é antiga, de antes
 * da academia ativar o modo novo, e não existe mais nenhuma sendo gerada.
 *
 * O que este script faz por academia com o modo ativado:
 *  - Acha alunos ativos sem nenhum `planos_modalidade` ativo.
 *  - Resolve em quantas modalidades DISTINTAS cada um está matriculado hoje
 *    (via matrículas ativas -> turma -> `modalidadeId` da turma).
 *  - Aluno em **exatamente 1** modalidade e com `plano_id` legado válido:
 *    migração automática seguro — cria 1 `planos_modalidade` usando o MESMO
 *    plano/valor/dia de vencimento que ele já paga hoje. Não muda quanto o
 *    aluno paga, só move a cobrança pro novo modelo.
 *  - Aluno em 0 ou 2+ modalidades, ou sem `plano_id` legado válido: fica de
 *    fora da aplicação automática (criar errado aqui pode DUPLICAR a
 *    cobrança — 1 por modalidade em vez de 1 só) e entra no relatório para
 *    decisão manual (qual plano/valor usar em cada modalidade).
 *
 * Por padrão só analisa e gera relatório:
 *   node migrar-alunos-sem-plano-modalidade.js
 *
 * Para aplicar as migrações automáticas seguras (categoria "auto" do
 * relatório) depois de revisar:
 *   node migrar-alunos-sem-plano-modalidade.js --apply
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

const DEFAULT_DUE_DAY = 10;

async function main() {
  console.log(apply ? "APLICAÇÃO habilitada (só categoria \"auto\")" : "DRY-RUN: nenhum documento será alterado");

  const report = {
    totals: { academias: 0, alunosSemPlano: 0, auto: 0, manual: 0 },
    detalhes: [],
  };

  const academiasSnap = await db.collection("academias").get();

  for (const academiaDoc of academiasSnap.docs) {
    const academiaData = academiaDoc.data();
    if (academiaData.cobranca_por_modalidade_ativa !== true) continue;

    const academiaId = academiaDoc.id;
    const academiaRef = academiaDoc.ref;

    const [alunosSnap, matriculasSnap, turmasSnap, planosSnap, modalidadesSnap, planosModalidadeSnap] =
      await Promise.all([
        academiaRef.collection("usuarios").where("ativo", "==", true).get(),
        academiaRef.collection("matriculas").where("ativo", "==", true).get(),
        academiaRef.collection("turmas").get(),
        academiaRef.collection("planos").get(),
        academiaRef.collection("modalidades").get(),
        academiaRef.collection("planos_modalidade").where("ativo", "==", true).get(),
      ]);

    const turmaPorId = new Map(turmasSnap.docs.map((d) => [d.id, d.data()]));
    const planoPorId = new Map(planosSnap.docs.map((d) => [d.id, d.data()]));
    const modalidadePorId = new Map(modalidadesSnap.docs.map((d) => [d.id, d.data()]));

    const alunosComPlanoModalidade = new Set(
      planosModalidadeSnap.docs.map((d) => String(d.data().aluno_id || "")),
    );

    const matriculasPorAluno = new Map();
    for (const doc of matriculasSnap.docs) {
      const m = doc.data();
      const alunoId = String(m.aluno_id || "");
      if (!alunoId) continue;
      if (!matriculasPorAluno.has(alunoId)) matriculasPorAluno.set(alunoId, []);
      matriculasPorAluno.get(alunoId).push(m);
    }

    const academiaDetalhe = { academiaId, nome: academiaData.nome || "", alunos: [] };

    for (const alunoDoc of alunosSnap.docs) {
      const alunoId = alunoDoc.id;
      if (alunosComPlanoModalidade.has(alunoId)) continue; // já migrado

      const aluno = alunoDoc.data();
      const matriculas = matriculasPorAluno.get(alunoId) || [];
      const modalidadeIds = new Set();
      for (const m of matriculas) {
        const turma = turmaPorId.get(String(m.turma_id || ""));
        const modId = turma?.modalidadeId;
        if (modId) modalidadeIds.add(modId);
      }

      const planoLegadoId = String(aluno.plano_id || "").trim();
      const planoLegado = planoLegadoId ? planoPorId.get(planoLegadoId) : null;

      report.totals.alunosSemPlano++;

      const entry = {
        alunoId,
        nome: aluno.nome || "",
        modalidades: [...modalidadeIds].map((id) => ({
          id,
          nome: modalidadePorId.get(id)?.nome || null,
        })),
        planoLegado: planoLegado
          ? { id: planoLegadoId, nome: planoLegado.nome, valorMensal: planoLegado.valor_mensal }
          : null,
      };

      if (modalidadeIds.size === 1 && planoLegado) {
        entry.categoria = "auto";
        report.totals.auto++;
        if (apply) {
          const modalidadeId = [...modalidadeIds][0];
          const diaVencimento = Number.isInteger(aluno.dia_vencimento)
            ? aluno.dia_vencimento
            : DEFAULT_DUE_DAY;
          const ref = academiaRef.collection("planos_modalidade").doc();
          await ref.set({
            id: ref.id,
            aluno_id: alunoId,
            modalidade_id: modalidadeId,
            plano_id: planoLegadoId,
            dia_vencimento: diaVencimento,
            ativo: true,
            origem: "migracao_automatica_script",
            criado_em: admin.firestore.FieldValue.serverTimestamp(),
          });
          entry.aplicado = true;
        }
      } else {
        entry.categoria = "manual";
        entry.motivo =
          modalidadeIds.size === 0
            ? "sem_matricula_com_modalidade"
            : modalidadeIds.size > 1
              ? "multiplas_modalidades"
              : "sem_plano_legado_valido";
        report.totals.manual++;
      }

      academiaDetalhe.alunos.push(entry);
    }

    if (academiaDetalhe.alunos.length > 0) {
      report.totals.academias++;
      report.detalhes.push(academiaDetalhe);
    }
  }

  const reportPath = path.join(__dirname, "alunos-sem-plano-modalidade-report.json");
  fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
  console.log(JSON.stringify(report.totals, null, 2));
  console.log(`Relatório: ${reportPath}`);
  if (report.totals.manual > 0) {
    console.log(
      `\n${report.totals.manual} aluno(s) precisam de revisão manual (0 ou 2+ modalidades, ou sem plano legado) — veja o relatório.`,
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
