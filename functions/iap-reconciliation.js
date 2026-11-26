"use strict";

/**
 * Rede de segurança diária pra assinaturas: cobre o caso de uma notificação
 * da Apple/Google se perder (o webhook já existe em iap-functions.js, mas
 * não há garantia de entrega 100%) e também segura cortesias/liberações
 * manuais vencidas. Nunca mexe em quem ainda está dentro do prazo — só olha
 * pra quem já venceu há 3+ dias de tolerância.
 *
 * `plano_origem === "loja"`: consulta a loja de verdade (App Store Server
 * API / Play Developer API) antes de decidir — pode ser só uma notificação
 * perdida, não necessariamente uma assinatura morta.
 * `plano_origem` em "cortesia"/"manual": nunca consulta loja nenhuma — só
 * revoga quando o prazo (`plano_expiracao`) já passou. Sem prazo definido,
 * nunca mexe (cortesia sem validade = vale até alguém mudar na mão).
 *
 * Pré-requisito pra funcionar no lado iOS: gerar uma chave da App Store
 * Server API (App Store Connect → Users and Access → Integrations →
 * In-App Purchase) e configurar:
 *   firebase functions:secrets:set APPLE_IAP_KEY_ID
 *   firebase functions:secrets:set APPLE_IAP_ISSUER_ID
 *   firebase functions:secrets:set APPLE_IAP_PRIVATE_KEY   (conteúdo do .p8)
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { AppStoreServerAPIClient, Environment, Status } = require("@apple/app-store-server-library");

const {
  BUNDLE_ID,
  verificarTransacaoApple,
  processarAtivacaoAssinatura,
  atualizarStatusAssinatura,
  revogarAssinatura,
  processarNotificacaoGooglePlay,
} = require("./iap-functions")._internal;

const db = admin.firestore();

const APPLE_IAP_KEY_ID = defineSecret("APPLE_IAP_KEY_ID");
const APPLE_IAP_ISSUER_ID = defineSecret("APPLE_IAP_ISSUER_ID");
const APPLE_IAP_PRIVATE_KEY = defineSecret("APPLE_IAP_PRIVATE_KEY");
const GOOGLE_PLAY_SERVICE_ACCOUNT_JSON = defineSecret("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");

const TOLERANCIA_DIAS = 3;

function criarClienteApple(environment) {
  return new AppStoreServerAPIClient(
    APPLE_IAP_PRIVATE_KEY.value(),
    APPLE_IAP_KEY_ID.value(),
    APPLE_IAP_ISSUER_ID.value(),
    BUNDLE_ID,
    environment
  );
}

// BILLING_RETRY e BILLING_GRACE_PERIOD: a Apple ainda está tentando cobrar
// e o assinante ainda tem acesso por definição desses dois estados — trata
// igual a "periodo_carencia" (mesmo vocabulário que o webhook já usa).
async function reconciliarIOS({ academiaId, originalTransactionId, ambiente, appAppleId }) {
  const apiClient = criarClienteApple(
    ambiente === "sandbox" ? Environment.SANDBOX : Environment.PRODUCTION
  );
  const resposta = await apiClient.getAllSubscriptionStatuses(originalTransactionId);
  const item = (resposta.data || [])
    .flatMap((grupo) => grupo.lastTransactions || [])
    .find((t) => t.originalTransactionId === originalTransactionId);

  if (!item) {
    logger.warn(
      `reconciliarIOS: nenhuma transação encontrada pra ${originalTransactionId} (academia ${academiaId})`
    );
    return;
  }

  if (item.status === Status.ACTIVE) {
    const { decoded: transacao } = await verificarTransacaoApple(
      item.signedTransactionInfo,
      appAppleId
    );
    await processarAtivacaoAssinatura({
      academiaId,
      productId: transacao.productId,
      plataforma: "ios",
      ambiente,
      expiresAtMs: transacao.expiresDate,
      transactionId: transacao.transactionId,
      originalTransactionId,
      transacaoEmMs: transacao.purchaseDate,
      origemEvento: "reconciliacao",
    });
    return;
  }
  if (item.status === Status.BILLING_RETRY || item.status === Status.BILLING_GRACE_PERIOD) {
    await atualizarStatusAssinatura({
      academiaId,
      status: "periodo_carencia",
      origemEvento: "reconciliacao",
    });
    return;
  }
  // EXPIRED ou REVOKED: a loja confirma que não está mais ativa.
  await revogarAssinatura({
    academiaId,
    status: "expirado_reconciliacao",
    origemEvento: "reconciliacao",
  });
}

async function processarReconciliacaoAssinaturas() {
  const limite = new Date(
    Date.now() - TOLERANCIA_DIAS * 24 * 60 * 60 * 1000
  ).toISOString();
  const snap = await db
    .collection("academias")
    .where("plano_tipo", "==", 1)
    .where("plano_expiracao", "<", limite)
    .get();

  let processadas = 0;
  let erros = 0;
  for (const doc of snap.docs) {
    const academiaId = doc.id;
    const d = doc.data();
    try {
      if (d.plano_origem === "cortesia" || d.plano_origem === "manual") {
        // Sem prazo definido, cortesia nunca é mexida por aqui.
        if (d.plano_expiracao) {
          await revogarAssinatura({
            academiaId,
            status: "expirado_cortesia",
            origemEvento: "reconciliacao",
          });
        }
        processadas++;
        continue;
      }

      if (!d.plano_original_transaction_id) {
        logger.warn(
          `processarReconciliacaoAssinaturas: academia ${academiaId} sem plano_original_transaction_id, pulando`
        );
        continue;
      }

      if (d.plano_plataforma === "ios") {
        await reconciliarIOS({
          academiaId,
          originalTransactionId: d.plano_original_transaction_id,
          ambiente: d.plano_ambiente || "production",
        });
      } else if (d.plano_plataforma === "android") {
        await processarNotificacaoGooglePlay(
          d.plano_original_transaction_id,
          GOOGLE_PLAY_SERVICE_ACCOUNT_JSON.value(),
          "reconciliacao"
        );
      } else {
        logger.warn(
          `processarReconciliacaoAssinaturas: academia ${academiaId} sem plataforma conhecida, pulando`
        );
        continue;
      }
      processadas++;
    } catch (e) {
      erros++;
      logger.error(`processarReconciliacaoAssinaturas: falha na academia ${academiaId}`, {
        motivo: e.message,
      });
    }
  }

  logger.info(
    `processarReconciliacaoAssinaturas: ${processadas} processada(s), ${erros} erro(s), ${snap.size} candidata(s) no total`
  );
  return { processadas, erros, total: snap.size };
}

exports.reconciliarAssinaturas = onSchedule(
  {
    schedule: "0 7 * * *",
    timeZone: "America/Sao_Paulo",
    secrets: [
      APPLE_IAP_KEY_ID,
      APPLE_IAP_ISSUER_ID,
      APPLE_IAP_PRIVATE_KEY,
      GOOGLE_PLAY_SERVICE_ACCOUNT_JSON,
    ],
  },
  async () => {
    await processarReconciliacaoAssinaturas();
  }
);

// Gatilho manual pra testar sem esperar o cron — chama a mesma lógica e
// devolve o resumo como JSON. Mesmo padrão de testarVencimentosContasAcademia
// (functions/index.js) e testarAlertasEngajamento (engagement-notifications.js).
exports.testarReconciliacaoAssinaturas = onRequest(
  {
    // Sem acesso público: exige token de uma conta com permissão no projeto
    // (`curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" <url>`).
    invoker: "private",
    secrets: [
      APPLE_IAP_KEY_ID,
      APPLE_IAP_ISSUER_ID,
      APPLE_IAP_PRIVATE_KEY,
      GOOGLE_PLAY_SERVICE_ACCOUNT_JSON,
    ],
  },
  async (req, res) => {
    const resultado = await processarReconciliacaoAssinaturas();
    res.status(200).json(resultado);
  }
);

exports._internal = { processarReconciliacaoAssinaturas, reconciliarIOS };
