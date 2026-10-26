#!/usr/bin/env node
"use strict";

/**
 * Diagnóstico SOMENTE LEITURA do financeiro de uma academia específica —
 * investiga por que nem todo aluno ativo tem cobrança gerada em
 * determinados meses, e quantifica cobranças pendentes "duplicadas".
 *
 * Uso:
 *   node diag-financeiro-academia.js <academiaId>
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

const academiaId = process.argv[2];
if (!academiaId) {
  console.error("Uso: node diag-financeiro-academia.js <academiaId>");
  process.exit(1);
}

async function main() {
  const academiaRef = db.collection("academias").doc(academiaId);
  const academiaSnap = await academiaRef.get();
  if (!academiaSnap.exists) {
    console.error("Academia não encontrada:", academiaId);
    process.exit(1);
  }
  const academia = academiaSnap.data();
  console.log("=== Academia ===");
  console.log("nome:", academia.nome);
  console.log("cobranca_por_modalidade_ativa:", academia.cobranca_por_modalidade_ativa === true);

  const [alunosSnap, planosSnap, planosModalidadeSnap, pagamentosSnap] = await Promise.all([
    academiaRef.collection("usuarios").where("ativo", "==", true).get(),
    academiaRef.collection("planos").get(),
    academiaRef.collection("planos_modalidade").get(),
    academiaRef.collection("pagamentos").get(),
  ]);

  console.log("\n=== Contagens ===");
  console.log("alunos ativos:", alunosSnap.size);
  console.log("planos (total):", planosSnap.size, "| ativos:", planosSnap.docs.filter((d) => d.data().ativo === true).length);
  console.log("planos_modalidade (total):", planosModalidadeSnap.size, "| ativos:", planosModalidadeSnap.docs.filter((d) => d.data().ativo === true).length);
  console.log("pagamentos (total):", pagamentosSnap.size);

  const alunos = alunosSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  const alunosComPlanoIdLegado = alunos.filter((a) => String(a.plano_id ?? "").trim());
  const alunosSemPlanoIdLegado = alunos.filter((a) => !String(a.plano_id ?? "").trim());

  const matriculasPorAluno = new Map();
  for (const doc of planosModalidadeSnap.docs) {
    const d = doc.data();
    if (d.ativo !== true) continue;
    const alunoId = String(d.aluno_id ?? "");
    if (!matriculasPorAluno.has(alunoId)) matriculasPorAluno.set(alunoId, []);
    matriculasPorAluno.get(alunoId).push(d);
  }
  const alunosComMatriculaAtiva = alunos.filter((a) => matriculasPorAluno.has(a.id));
  const alunosSemMatriculaAtiva = alunos.filter((a) => !matriculasPorAluno.has(a.id));

  console.log("\n=== Elegibilidade pra cobrança automática ===");
  console.log("alunos ativos com plano_id (modelo legado):", alunosComPlanoIdLegado.length);
  console.log("alunos ativos SEM plano_id (modelo legado) — NUNCA são cobrados automaticamente nesse modo:", alunosSemPlanoIdLegado.length);
  console.log("alunos ativos com matrícula ativa em planos_modalidade:", alunosComMatriculaAtiva.length);
  console.log("alunos ativos SEM nenhuma matrícula ativa — NUNCA são cobrados automaticamente nesse modo:", alunosSemMatriculaAtiva.length);

  if (alunosSemPlanoIdLegado.length > 0) {
    console.log("\nAmostra de alunos SEM plano_id (até 10):");
    for (const a of alunosSemPlanoIdLegado.slice(0, 10)) {
      console.log(` - ${a.nome || a.id} (id=${a.id}, plano_id=${JSON.stringify(a.plano_id)})`);
    }
  }
  if (alunosSemMatriculaAtiva.length > 0) {
    console.log("\nAmostra de alunos SEM matrícula ativa em planos_modalidade (até 10):");
    for (const a of alunosSemMatriculaAtiva.slice(0, 10)) {
      console.log(` - ${a.nome || a.id} (id=${a.id})`);
    }
  }

  // ── Pagamentos por mês de referência ──────────────────────────────────────
  const pagamentos = pagamentosSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  const porMes = new Map();
  for (const p of pagamentos) {
    const mes = String(p.mes_referencia ?? "(sem mes_referencia)");
    if (!porMes.has(mes)) porMes.set(mes, { total: 0, pendente: 0, pago: 0, desconsiderado: 0, outro: 0, origemAuto: 0, origemOutra: 0 });
    const bucket = porMes.get(mes);
    bucket.total++;
    if (p.status === 0) bucket.pendente++;
    else if (p.status === 1) bucket.pago++;
    else if (p.status === 4) bucket.desconsiderado++;
    else bucket.outro++;
    if (p.origem === "auto") bucket.origemAuto++;
    else bucket.origemOutra++;
  }
  console.log("\n=== Pagamentos por mês de referência ===");
  const mesesOrdenados = [...porMes.keys()].sort();
  for (const mes of mesesOrdenados) {
    const b = porMes.get(mes);
    console.log(`${mes}: total=${b.total} pendente=${b.pendente} pago=${b.pago} desconsiderado=${b.desconsiderado} outro=${b.outro} | origem=auto:${b.origemAuto} outra:${b.origemOutra}`);
  }

  // ── Grupos potencialmente duplicados (mesmo aluno + mesmo mes, >1 ativo) ──
  const grupos = new Map();
  for (const p of pagamentos) {
    if (p.status === 4) continue;
    const tipo = p.tipo;
    const eMensalidade = tipo === undefined || tipo === null || tipo === "Mensalidade";
    if (!eMensalidade) continue;
    const alunoId = String(p.aluno_id ?? "").trim();
    const mes = String(p.mes_referencia ?? "").trim();
    if (!alunoId || !mes) continue;
    const modalidadeId = String(p.modalidade_id ?? "").trim();
    const chave = modalidadeId ? `${alunoId}|${mes}|${modalidadeId}` : `${alunoId}|${mes}`;
    if (!grupos.has(chave)) grupos.set(chave, []);
    grupos.get(chave).push(p);
  }
  const duplicados = [...grupos.entries()].filter(([, v]) => v.length > 1);
  console.log("\n=== Grupos duplicados (mesmo aluno+mês ativos) ===");
  console.log("total de grupos duplicados:", duplicados.length);
  for (const [chave, docs] of duplicados.slice(0, 15)) {
    console.log(` - ${chave}: ${docs.length} docs -> [${docs.map((d) => `${d.id}(status=${d.status},origem=${d.origem})`).join(", ")}]`);
  }
}

main().then(() => process.exit(0)).catch((e) => {
  console.error("Erro:", e);
  process.exit(1);
});
