#!/usr/bin/env node
"use strict";

/**
 * Diagnóstico SOMENTE LEITURA do bug de "graus coloridos vazando pra quem
 * não devia" — acha, em todas as academias (ou só numa, se passada), quais
 * alunos têm uma graduação aprovada com `grau` MAIOR do que o esperado
 * pra quem não é elegível a graus coloridos (padrão "normal" = 4, mesma
 * regra de core/grau_colorido.dart no app).
 *
 * Não escreve nada. Só lista pra decisão humana — ver conversa sobre o bug
 * de "alunos com 11 graus brancos".
 *
 * Uso:
 *   node diag-graus-coloridos.js [academiaId]
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

const MAX_GRAUS_PADRAO_SEM_COR = 4;
const academiaIdFiltro = process.argv[2] || null;

function montarElegibilidade(matriculas, turmasPorId, grausColoridosDisponivel) {
  const resultado = new Map(); // alunoId -> Set<modalidadeId>
  if (!grausColoridosDisponivel) return resultado;
  for (const m of matriculas) {
    if (m.ativo !== true) continue;
    const alunoId = m.aluno_id || "";
    const turmaId = m.turma_id || "";
    if (!alunoId || !turmaId) continue;
    const turma = turmasPorId.get(turmaId);
    if (!turma || turma.usa_graus_coloridos !== true) continue;
    const modalidadeId = turma.modalidadeId || turma.modalidade_id || "";
    if (!modalidadeId) continue;
    if (!resultado.has(alunoId)) resultado.set(alunoId, new Set());
    resultado.get(alunoId).add(modalidadeId);
  }
  return resultado;
}

async function diagnosticarAcademia(academiaRef) {
  const academiaId = academiaRef.id;
  const academiaSnap = await academiaRef.get();
  const academia = academiaSnap.data() || {};
  const grausColoridosDisponivel = academia.graus_coloridos_disponivel === true;

  const [faixasSnap, graduacoesSnap, turmasSnap, matriculasSnap, usuariosSnap] =
    await Promise.all([
      academiaRef.collection("faixas").get(),
      academiaRef.collection("graduacoes").get(),
      academiaRef.collection("turmas").get(),
      academiaRef.collection("matriculas").get(),
      academiaRef.collection("usuarios").get(),
    ]);

  const faixas = faixasSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  const faixaMap = new Map(faixas.map((f) => [f.id, f]));

  const turmasPorId = new Map(
    turmasSnap.docs.map((d) => [d.id, { id: d.id, ...d.data() }])
  );
  const matriculas = matriculasSnap.docs.map((d) => d.data());
  const elegibilidade = montarElegibilidade(
    matriculas,
    turmasPorId,
    grausColoridosDisponivel
  );
  const alunoNomes = new Map(
    usuariosSnap.docs.map((d) => [d.id, d.data().nome || d.id])
  );

  const achados = [];
  for (const doc of graduacoesSnap.docs) {
    const g = doc.data();
    if (g.aprovado !== true) continue;
    const grau = typeof g.grau === "number" ? g.grau : 0;
    if (grau <= 0) continue;
    const faixa = faixaMap.get(g.faixa_id) || {};
    if (grau <= MAX_GRAUS_PADRAO_SEM_COR) continue; // dentro do padrão normal
    const temGrauCores =
      Array.isArray(faixa.grau_cores) && faixa.grau_cores.length > 0;
    const modalidadeId = faixa.modalidadeId || faixa.modalidade_id || "";
    const alunoId = g.aluno_id || "";
    const elegivel = elegibilidade.get(alunoId)?.has(modalidadeId) ?? false;
    if (temGrauCores && elegivel) continue; // elegível de verdade hoje, grau alto é esperado
    // Nomes de faixa que legitimamente têm mais de 4 graus mesmo SEM o
    // sistema colorido (ex.: graus de faixa preta) — mesma lista usada em
    // `_maxGrausFaixa` no app. Qualquer outra faixa com grau > 4 aqui é
    // suspeita: ou é resíduo do bug (faixa foi colorida, resetada, mas o
    // histórico ficou com o grau alto), ou precisa de revisão manual.
    const nomeFaixa = (faixa.nome || "").toLowerCase();
    const bateComBeltLegitimaDeAltoGrau =
      nomeFaixa.includes("preta") ||
      nomeFaixa.includes("vermelha") ||
      nomeFaixa.includes("coral");
    achados.push({
      academiaId,
      academiaNome: academia.nome || academiaId,
      alunoId,
      alunoNome: alunoNomes.get(alunoId) || alunoId,
      faixaNome: faixa.nome || g.faixa_id,
      grau,
      maxFaixaConfigurado: faixa.max_graus ?? null,
      faixaTemGrauCoresHoje: temGrauCores,
      alunoElegivelHoje: elegivel,
      suspeito: !bateComBeltLegitimaDeAltoGrau,
      dataExame: g.data_exame || null,
      graduacaoId: doc.id,
    });
  }
  return achados;
}

async function main() {
  const academiasSnap = academiaIdFiltro
    ? { docs: [db.collection("academias").doc(academiaIdFiltro)] }
    : await db.collection("academias").listDocuments().then((refs) => ({ docs: refs }));

  let todosAchados = [];
  for (const ref of academiasSnap.docs) {
    const achados = await diagnosticarAcademia(ref);
    todosAchados = todosAchados.concat(achados);
  }

  if (todosAchados.length === 0) {
    console.log("Nenhum aluno com grau acima do padrão (4) encontrado.");
    return;
  }

  const suspeitos = todosAchados.filter((a) => a.suspeito);
  const legitimos = todosAchados.filter((a) => !a.suspeito);

  console.log(`=== ${suspeitos.length} graduação(ões) SUSPEITA(S) (provável resíduo do bug) ===\n`);
  for (const a of suspeitos) {
    console.log(
      `academia=${a.academiaNome} (${a.academiaId})  aluno=${a.alunoNome} (${a.alunoId})  ` +
        `faixa=${a.faixaNome}  grau=${a.grau}  maxFaixaConfigurado=${a.maxFaixaConfigurado}  ` +
        `temGrauCoresHoje=${a.faixaTemGrauCoresHoje}  elegivelHoje=${a.alunoElegivelHoje}  ` +
        `dataExame=${a.dataExame}  graduacaoId=${a.graduacaoId}`
    );
  }

  console.log(`\n=== ${legitimos.length} graduação(ões) com grau > 4 em faixa de alto-grau legítimo (preta/vermelha/coral) — informativo, não é bug ===\n`);
  for (const a of legitimos) {
    console.log(
      `academia=${a.academiaNome} (${a.academiaId})  aluno=${a.alunoNome} (${a.alunoId})  ` +
        `faixa=${a.faixaNome}  grau=${a.grau}  graduacaoId=${a.graduacaoId}`
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
