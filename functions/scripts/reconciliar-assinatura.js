#!/usr/bin/env node
"use strict";

/**
 * Reconcilia UMA academia específica contra a loja de verdade (App Store
 * Server API / Play Developer API) — uso pontual, nunca em lote. Sempre
 * mostra o que encontraria primeiro; só grava no Firestore com --aplicar.
 *
 * Fica dentro de functions/ (não em scripts/migrate-firestore/, que é um
 * projeto node irmão com seu PRÓPRIO node_modules) justamente pra reaproveitar
 * de verdade a lógica de iap-functions.js/iap-reconciliation.js sem duplicar
 * nada — exigir de scripts/migrate-firestore/ carregaria uma segunda cópia
 * isolada do firebase-admin e quebraria (`admin.initializeApp()` chamado
 * aqui não valeria pra cópia que iap-functions.js enxerga).
 *
 * Credenciais (nenhuma vai pro repositório — todas no .gitignore):
 *   functions/scripts/serviceAccount.json              (Firebase Admin)
 *   functions/scripts/apple-iap-private-key.p8          (App Store Server API)
 *   functions/scripts/google-play-service-account.json  (Android Publisher API)
 * Key ID / Issuer ID da Apple vêm de APPLE_IAP_KEY_ID / APPLE_IAP_ISSUER_ID
 * (variáveis de ambiente) — não são segredo, só identificadores.
 *
 * Uso (rodar de dentro de functions/):
 *   node scripts/reconciliar-assinatura.js <academiaId>            # dry-run
 *   node scripts/reconciliar-assinatura.js <academiaId> --aplicar   # grava de verdade
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

const { AppStoreServerAPIClient, Environment, Status } = require("@apple/app-store-server-library");
const iapFunctions = require("../iap-functions");
const {
  BUNDLE_ID,
  verificarTransacaoApple,
  verificarCompraAndroid,
  processarAtivacaoAssinatura,
  atualizarStatusAssinatura,
  revogarAssinatura,
  processarNotificacaoGooglePlay,
} = iapFunctions._internal;

const academiaId = process.argv[2];
const aplicar = process.argv.includes("--aplicar");

if (!academiaId) {
  console.error("Uso: node scripts/reconciliar-assinatura.js <academiaId> [--aplicar]");
  process.exit(1);
}

function lerArquivoLocal(nomeArquivo) {
  const caminho = path.join(__dirname, nomeArquivo);
  if (!fs.existsSync(caminho)) return null;
  return fs.readFileSync(caminho, "utf8");
}

function criarClienteApple(environment) {
  const chave = lerArquivoLocal("apple-iap-private-key.p8");
  if (!chave) {
    throw new Error(
      "apple-iap-private-key.p8 não encontrado em functions/scripts/ — copie o .p8 gerado em App Store Connect pra lá."
    );
  }
  const keyId = process.env.APPLE_IAP_KEY_ID;
  const issuerId = process.env.APPLE_IAP_ISSUER_ID;
  if (!keyId || !issuerId) {
    throw new Error(
      "Defina APPLE_IAP_KEY_ID e APPLE_IAP_ISSUER_ID no ambiente antes de rodar (ex.: export APPLE_IAP_KEY_ID=... && export APPLE_IAP_ISSUER_ID=...)."
    );
  }
  return new AppStoreServerAPIClient(chave, keyId, issuerId, BUNDLE_ID, environment);
}

async function main() {
  const doc = await db.doc(`academias/${academiaId}`).get();
  if (!doc.exists) {
    console.error(`Academia ${academiaId} não encontrada.`);
    process.exit(1);
  }
  const d = doc.data();
  console.log(`Academia: ${d.nome || "(sem nome)"}  (${academiaId})`);
  console.log(
    `Estado atual no Firestore: plano_tipo=${d.plano_tipo}  plano_status=${d.plano_status}  ` +
    `plano_origem=${d.plano_origem || "(não definido)"}  plano_expiracao=${d.plano_expiracao}`
  );

  if (d.plano_origem === "cortesia" || d.plano_origem === "manual") {
    console.log(
      "\nATENÇÃO: plano_origem é cortesia/manual — este script é só para academias 'loja'. " +
      "Pra mudar uma cortesia/liberação manual, edite plano_origem/plano_expiracao direto, sem consultar loja nenhuma."
    );
    process.exit(1);
  }
  if (!d.plano_original_transaction_id) {
    console.error("Academia sem plano_original_transaction_id — nada pra consultar na loja.");
    process.exit(1);
  }

  if (d.plano_plataforma === "ios") {
    const ambiente = d.plano_ambiente || "production";
    const apiClient = criarClienteApple(
      ambiente === "sandbox" ? Environment.SANDBOX : Environment.PRODUCTION
    );
    const resposta = await apiClient.getAllSubscriptionStatuses(d.plano_original_transaction_id);
    const item = (resposta.data || [])
      .flatMap((grupo) => grupo.lastTransactions || [])
      .find((t) => t.originalTransactionId === d.plano_original_transaction_id);

    if (!item) {
      console.log("\nA Apple não encontrou nenhuma transação pra esse originalTransactionId.");
      process.exit(0);
    }
    const nomeStatus = Object.keys(Status).find((k) => Status[k] === item.status) || item.status;
    console.log(`\nNa Apple agora: status=${nomeStatus}`);

    if (item.status === Status.ACTIVE) {
      const { decoded: transacao } = await verificarTransacaoApple(item.signedTransactionInfo);
      console.log(
        `  produto=${transacao.productId}  expira=${new Date(transacao.expiresDate).toISOString()}`
      );
      if (aplicar) {
        await processarAtivacaoAssinatura({
          academiaId,
          productId: transacao.productId,
          plataforma: "ios",
          ambiente,
          expiresAtMs: transacao.expiresDate,
          transactionId: transacao.transactionId,
          originalTransactionId: d.plano_original_transaction_id,
          origemEvento: "manual",
        });
        console.log("✓ Aplicado: assinatura resincronizada como ativa.");
      }
    } else if (item.status === Status.BILLING_RETRY || item.status === Status.BILLING_GRACE_PERIOD) {
      console.log("  (período de carência — acesso continua válido até a loja decidir)");
      if (aplicar) {
        await atualizarStatusAssinatura({ academiaId, status: "periodo_carencia", origemEvento: "manual" });
        console.log("✓ Aplicado: marcado como periodo_carencia.");
      }
    } else {
      console.log("  (EXPIRED ou REVOKED — a loja confirma que não está mais ativa)");
      if (aplicar) {
        await revogarAssinatura({ academiaId, status: "expirado_reconciliacao", origemEvento: "manual" });
        console.log("✓ Aplicado: revogado.");
      }
    }
  } else if (d.plano_plataforma === "android") {
    const serviceAccountJson = lerArquivoLocal("google-play-service-account.json");
    if (!serviceAccountJson) {
      throw new Error(
        "google-play-service-account.json não encontrado em functions/scripts/."
      );
    }
    const compra = await verificarCompraAndroid(d.plano_original_transaction_id, serviceAccountJson);
    console.log(`\nNo Google Play agora: subscriptionState=${compra.subscriptionState}`);
    console.log(`  acknowledgementState=${compra.acknowledgementState || "(desconhecido)"}`);
    if (aplicar) {
      await processarNotificacaoGooglePlay(
        d.plano_original_transaction_id,
        serviceAccountJson,
        "manual"
      );
      console.log("✓ Aplicado: resincronizado conforme o estado atual na Google Play.");
    }
  } else {
    console.error(`plano_plataforma desconhecida: ${d.plano_plataforma}`);
    process.exit(1);
  }

  if (!aplicar) {
    console.log("\n(dry-run — nada foi gravado. Rode de novo com --aplicar pra gravar de verdade.)");
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
