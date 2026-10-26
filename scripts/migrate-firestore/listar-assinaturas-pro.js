#!/usr/bin/env node
"use strict";

/**
 * Lista todas as academias marcadas como Pro (plano_tipo: 1) com os campos
 * relevantes pra conferência manual contra a App Store Connect / Play
 * Console — só leitura, nunca altera nada.
 *
 * IMPORTANTE: não existe forma automática de verificar retroativamente, via
 * API da Apple/Google, as assinaturas ativadas ANTES da validação
 * server-side (ativarAssinaturaIOS/ativarAssinaturaAndroid) entrar no ar —
 * essas não têm `plano_transaction_id` gravado, e a API da Apple só permite
 * consultar uma transação a partir de um ID já conhecido, não "todas as
 * transações do app". A única forma confiável de conferir essas é manual,
 * cruzando com o relatório de assinantes da App Store Connect.
 *
 * A partir de agora (depois dessa correção), toda ativação nova já grava
 * `plano_ambiente` ('production'/'sandbox') e `plano_transaction_id` — então
 * qualquer uma dessas 5 contas que tiver uma renovação real vai se
 * autoconfirmar (ou se autorrejeitar, se não for uma assinatura de verdade)
 * na próxima vez que o app processar a renovação.
 *
 * Uso:
 *   node listar-assinaturas-pro.js
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

async function main() {
  const snap = await db.collection("academias").where("plano_tipo", "==", 1).get();

  if (snap.empty) {
    console.log("Nenhuma academia marcada como Pro.");
    return;
  }

  const linhas = snap.docs.map((doc) => {
    const d = doc.data();
    return {
      id: doc.id,
      nome: d.nome || "",
      email: d.email || "",
      produto: d.plano_produto_id || "(não registrado)",
      plataforma: d.plano_plataforma || "(não registrado)",
      ambiente: d.plano_ambiente || "— pré-validação, verificar manualmente —",
      transaction_id: d.plano_transaction_id || "—",
      assinado_em: d.plano_assinado_em || "(desconhecido)",
      expira_em: d.plano_expiracao || "(desconhecido)",
      academia_criada_em: d.criado_em || "",
    };
  });

  console.table(linhas);
  console.log(`\nTotal: ${linhas.length} academia(s) marcada(s) como Pro.`);
  console.log(
    "\nContas com ambiente \"— pré-validação...\" foram ativadas antes da correção " +
    "server-side e não têm como ser confirmadas automaticamente — cruze manualmente " +
    "com o relatório de assinantes da App Store Connect / Play Console, ou aguarde a " +
    "próxima renovação delas (vai se autoconfirmar ou se autorrejeitar nesse momento)."
  );
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
