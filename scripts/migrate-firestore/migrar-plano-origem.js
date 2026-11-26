#!/usr/bin/env node
"use strict";

/**
 * Preenche `plano_origem` ("loja" | "cortesia" | "manual") em toda academia
 * já marcada como Pro (`plano_tipo: 1`) que ainda não tem esse campo — uma
 * vez só, antes da rotina diária de reconciliação (iap-reconciliation.js) ir
 * pro ar, já que é esse campo que protege cortesias/liberações manuais de
 * serem derrubadas automaticamente.
 *
 * Regra: tem `plano_produto_id` (comprou de verdade e já passou pelo fluxo
 * validado) → "loja". Sem produto → "cortesia" (academias liberadas na mão,
 * sem nenhuma compra por trás). Exceção única, hardcoded: o Dojô Coelho
 * (Maykon) está com liberação manual TEMPORÁRIA enquanto a compra Android
 * dele não é reprocessada — marca como "manual" em vez de "cortesia" pra não
 * confundir os dois casos.
 *
 * Idempotente: pula quem já tem `plano_origem` gravado, então rodar de novo
 * não faz nada além do que já estava pendente.
 *
 * Read + write. Uso:
 *   node migrar-plano-origem.js            # dry-run, só mostra o que faria
 *   node migrar-plano-origem.js --aplicar  # grava de verdade
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

const aplicar = process.argv.includes("--aplicar");

// Liberação manual temporária do caso do Maykon/Dojô Coelho: não é cortesia
// de verdade, é um placeholder até a compra Android real ser reprocessada
// (estágio 4 do plano — scripts/migrate-firestore/reconciliar-assinatura.js).
const ORIGEM_MANUAL_FORCADA = new Set(["JWwj3BZEM6Z7CkxK9w2k"]);

function origemParaAcademia(id, dados) {
  if (ORIGEM_MANUAL_FORCADA.has(id)) return "manual";
  return dados.plano_produto_id ? "loja" : "cortesia";
}

async function main() {
  const snap = await db.collection("academias").where("plano_tipo", "==", 1).get();
  if (snap.empty) {
    console.log("Nenhuma academia marcada como Pro.");
    return;
  }

  console.log(
    aplicar
      ? `Aplicando em ${snap.size} academia(s) marcada(s) como Pro...`
      : `Dry-run (${snap.size} academia(s) Pro) — rode com --aplicar pra gravar de verdade.`,
  );

  let pulou = 0;
  let marcou = 0;
  for (const doc of snap.docs) {
    const dados = doc.data();
    if (dados.plano_origem) {
      pulou++;
      continue;
    }
    const origem = origemParaAcademia(doc.id, dados);
    console.log(
      `${aplicar ? "✓" : "→"} ${doc.id}  "${dados.nome || ""}"  produto=${dados.plano_produto_id || "(nenhum)"}  → plano_origem="${origem}"`,
    );
    if (aplicar) {
      await doc.ref.update({ plano_origem: origem });
    }
    marcou++;
  }

  console.log(
    `\n${aplicar ? "Gravado" : "Marcaria"} em ${marcou} academia(s); ${pulou} já tinham plano_origem e foram puladas.`,
  );
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
