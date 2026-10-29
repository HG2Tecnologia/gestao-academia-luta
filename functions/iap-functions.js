"use strict";

const fs = require("fs");
const path = require("path");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onMessagePublished } = require("firebase-functions/v2/pubsub");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const {
  SignedDataVerifier,
  Environment,
  VerificationException,
  VerificationStatus,
} = require("@apple/app-store-server-library");
const { google } = require("googleapis");

const db = admin.firestore();

const BUNDLE_ID = "br.com.hg2tecnologia.senseimanager";
const ANDROID_PACKAGE_NAME = "br.com.hg2tecnologia.senseimanager";
const GOOGLE_PLAY_RTDN_TOPIC = "play-rtdn";

const PRODUTOS_VALIDOS = new Set([
  "br.com.senseimanager.pro.mensal",
  "br.com.senseimanager.pro.trimestral",
  "br.com.senseimanager.pro.anual",
]);

const APPLE_APP_ID = defineSecret("APPLE_APP_ID");
const GOOGLE_PLAY_SERVICE_ACCOUNT_JSON = defineSecret(
  "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"
);

const appleRootCAs = [
  fs.readFileSync(path.join(__dirname, "certs", "AppleRootCA-G3.cer")),
];

// ── Apple: verificação criptográfica (JWS assinado pela Apple) ──────────────
// Única peça que não dá pra cobrir com teste automatizado sem um payload de
// verdade assinado pela Apple — por isso fica isolada e fina, delegando toda
// a verificação (cadeia de certificado, assinatura, ambiente) pra lib oficial
// da Apple. A lógica de negócio fica nas funções mais abaixo, essas sim
// 100% cobertas por teste.
function criarVerificador(environment, appAppleId) {
  return new SignedDataVerifier(
    appleRootCAs,
    true,
    environment,
    BUNDLE_ID,
    appAppleId
  );
}

// A Apple assina cada payload (transação, notificação, renewal info) preso a
// um ambiente (Production/Sandbox) — não dá pra saber qual antes de tentar.
// Tenta produção primeiro; só cai pra sandbox se a lib rejeitar
// especificamente por mismatch de ambiente (nunca por outro motivo).
async function verificarComFallbackDeAmbiente(appAppleId, chamarVerificador) {
  try {
    const decoded = await chamarVerificador(
      criarVerificador(Environment.PRODUCTION, appAppleId)
    );
    return { decoded, ambiente: "production" };
  } catch (e) {
    if (
      e instanceof VerificationException &&
      e.status === VerificationStatus.INVALID_ENVIRONMENT
    ) {
      const decoded = await chamarVerificador(
        criarVerificador(Environment.SANDBOX)
      );
      return { decoded, ambiente: "sandbox" };
    }
    throw e;
  }
}

async function verificarTransacaoApple(jwsTransaction, appAppleId) {
  return verificarComFallbackDeAmbiente(appAppleId, (v) =>
    v.verifyAndDecodeTransaction(jwsTransaction)
  );
}

async function verificarNotificacaoApple(signedPayload, appAppleId) {
  return verificarComFallbackDeAmbiente(appAppleId, (v) =>
    v.verifyAndDecodeNotification(signedPayload)
  );
}

async function verificarRenewalInfoApple(signedRenewalInfo, appAppleId) {
  return verificarComFallbackDeAmbiente(appAppleId, (v) =>
    v.verifyAndDecodeRenewalInfo(signedRenewalInfo)
  );
}

// ── Google Play: verificação da compra via Android Publisher API ────────────
async function verificarCompraAndroid(purchaseToken, serviceAccountJsonRaw) {
  const credentials = JSON.parse(serviceAccountJsonRaw);
  const auth = new google.auth.GoogleAuth({
    credentials,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const androidpublisher = google.androidpublisher({ version: "v3", auth });
  const { data } = await androidpublisher.purchases.subscriptionsv2.get({
    packageName: ANDROID_PACKAGE_NAME,
    token: purchaseToken,
  });
  return data;
}

// ── Núcleo comum: valida os dados já verificados e grava no Firestore ───────
// Só é chamado depois que a assinatura/transação já foi confirmada como
// genuína (Apple ou Google) — aqui só restam as regras de negócio. Cobre
// tanto a primeira ativação (chamada pelo app) quanto uma renovação
// detectada via webhook — é a mesma operação de negócio nos dois casos.
async function processarAtivacaoAssinatura({
  academiaId,
  productId,
  plataforma,
  ambiente,
  expiresAtMs,
  transactionId,
  originalTransactionId,
  renovacaoAutomatica,
}) {
  if (!PRODUTOS_VALIDOS.has(productId)) {
    throw new HttpsError("invalid-argument", "Produto desconhecido.");
  }
  if (!expiresAtMs || expiresAtMs < Date.now()) {
    throw new HttpsError("permission-denied", "Assinatura expirada.");
  }

  const academiaRef = db.doc(`academias/${academiaId}`);
  const academiaSnap = await academiaRef.get();
  if (!academiaSnap.exists) {
    throw new HttpsError("not-found", "Academia não encontrada.");
  }
  const jaTemAssinaturaDesde =
    academiaSnap.data()?.plano_assinado_em != null;

  const agora = new Date();
  await academiaRef.update({
    plano_tipo: 1,
    plano_status: "ativo",
    plano_renovacao_automatica: renovacaoAutomatica ?? true,
    plano_expiracao: new Date(expiresAtMs).toISOString(),
    plano_produto_id: productId,
    plano_plataforma: plataforma,
    plano_ambiente: ambiente,
    plano_transaction_id: transactionId || null,
    plano_original_transaction_id: originalTransactionId || null,
    ...(jaTemAssinaturaDesde
      ? {}
      : { plano_assinado_em: agora.toISOString() }),
  });

  logger.info(
    `processarAtivacaoAssinatura: academia ${academiaId} ativada (${plataforma}/${ambiente}, produto ${productId})`
  );
  return { ok: true, ambiente };
}

// Atualiza só o "estado de superfície" da assinatura (ex.: usuário desligou
// o auto-renew, ou entrou em período de carência de cobrança) — sem mexer em
// plano_tipo/plano_expiracao, porque o acesso continua válido até a data que
// já está gravada.
async function atualizarStatusAssinatura({
  academiaId,
  status,
  renovacaoAutomatica,
}) {
  const update = { plano_status: status };
  if (renovacaoAutomatica !== undefined) {
    update.plano_renovacao_automatica = renovacaoAutomatica;
  }
  await db.doc(`academias/${academiaId}`).update(update);
  logger.info(`atualizarStatusAssinatura: academia ${academiaId} -> ${status}`);
}

// Revoga o Pro imediatamente — usado em reembolso/revogação (não espera a
// data de expiração, porque o pagamento já não é mais válido) e em
// expiração definitiva (fim do período de carência sem sucesso de cobrança).
async function revogarAssinatura({ academiaId, status }) {
  await db.doc(`academias/${academiaId}`).update({
    plano_tipo: 0,
    plano_status: status,
  });
  logger.info(`revogarAssinatura: academia ${academiaId} -> ${status}`);
}

async function buscarAcademiaPorOriginalTransactionId(originalTransactionId) {
  if (!originalTransactionId) return null;
  const snap = await db
    .collection("academias")
    .where("plano_original_transaction_id", "==", originalTransactionId)
    .limit(1)
    .get();
  if (snap.empty) return null;
  return snap.docs[0].id;
}

// ── Roteamento por tipo de notificação (puro — sem chamar Apple/Google) ─────
// Separado da verificação criptográfica de propósito: essa parte é 100%
// nossa regra de negócio, então é a que cobrimos com teste automatizado
// (passando dados já "verificados" direto). A verificação em si
// (processarNotificacaoApple/processarNotificacaoGooglePlay, abaixo) é só
// quem decodifica o JWS/consulta a API e repassa pra cá.
//
// Limitação conhecida: assinaturas ativadas ANTES desta correção (sem
// plano_original_transaction_id salvo) não são encontradas aqui — só voltam
// a sincronizar quando passarem de novo pelo fluxo validado (nova compra ou
// restauração). Documentado também em listar-assinaturas-pro.js.
async function rotearNotificacaoAssinatura({
  notificationType,
  originalTransactionId,
  productId,
  plataforma,
  ambiente,
  expiresAtMs,
  transactionId,
  renovacaoAutomatica,
}) {
  const academiaId = await buscarAcademiaPorOriginalTransactionId(
    originalTransactionId
  );
  if (!academiaId) {
    logger.info(
      `rotearNotificacaoAssinatura: nenhuma academia para originalTransactionId ${originalTransactionId}`
    );
    return;
  }

  switch (notificationType) {
    case "DID_RENEW":
    case "SUBSCRIBED":
    // Troca de plano (ex.: mensal -> anual). No upgrade imediato a Apple já
    // manda a transação nova (produto/expiração atualizados) nessa mesma
    // notificação; no downgrade/crossgrade (só vale na próxima renovação)
    // ela ainda reflete o plano atual — nos dois casos é seguro tratar
    // igual a uma renovação normal.
    case "DID_CHANGE_RENEWAL_PREF":
    // Reembolso que a Apple decidiu reverter (devolveu o dinheiro de volta
    // pro comerciante) — o assinante recupera o acesso. Sem isso, uma conta
    // revogada por REFUND ficava revogada pra sempre mesmo a Apple
    // desfazendo o reembolso depois.
    case "REFUND_REVERSED":
    // Extensão de cortesia dada pela Apple (ex.: compensação por instabilidade
    // da loja) — muda a data de expiração sem o assinante ter feito nada.
    case "RENEWAL_EXTENDED":
    case "RENEWAL_EXTENSION":
      await processarAtivacaoAssinatura({
        academiaId,
        productId,
        plataforma,
        ambiente,
        expiresAtMs,
        transactionId,
        originalTransactionId,
        renovacaoAutomatica,
      });
      break;
    case "DID_CHANGE_RENEWAL_STATUS":
      await atualizarStatusAssinatura({
        academiaId,
        status: renovacaoAutomatica === false ? "cancelado_ate_expirar" : "ativo",
        renovacaoAutomatica,
      });
      break;
    case "DID_FAIL_TO_RENEW":
      await atualizarStatusAssinatura({ academiaId, status: "periodo_carencia" });
      break;
    case "GRACE_PERIOD_EXPIRED":
    case "EXPIRED":
      await revogarAssinatura({ academiaId, status: "expirado" });
      break;
    case "REFUND":
    case "REVOKE":
      await revogarAssinatura({ academiaId, status: "reembolsado" });
      break;
    default:
      logger.info(
        `rotearNotificacaoAssinatura: notificationType ${notificationType} sem tratamento específico, ignorado`
      );
  }
}

// ── Processamento de notificações da Apple (App Store Server Notifications V2) ──
async function processarNotificacaoApple(decoded, appAppleId) {
  const { notificationType, data } = decoded;
  if (!data?.signedTransactionInfo) {
    logger.info(
      `processarNotificacaoApple: ${notificationType} sem signedTransactionInfo, ignorado`
    );
    return;
  }

  const { decoded: transacao } = await verificarTransacaoApple(
    data.signedTransactionInfo,
    appAppleId
  );

  let renovacaoAutomatica;
  if (data.signedRenewalInfo) {
    try {
      const { decoded: renewalInfo } = await verificarRenewalInfoApple(
        data.signedRenewalInfo,
        appAppleId
      );
      renovacaoAutomatica = renewalInfo.autoRenewStatus === 1;
    } catch (e) {
      logger.warn("processarNotificacaoApple: falha ao verificar renewalInfo", e);
    }
  }

  await rotearNotificacaoAssinatura({
    notificationType,
    originalTransactionId: transacao.originalTransactionId,
    productId: transacao.productId,
    plataforma: "ios",
    ambiente: transacao.environment === "Production" ? "production" : "sandbox",
    expiresAtMs: transacao.expiresDate,
    transactionId: transacao.transactionId,
    renovacaoAutomatica,
  });
}

// ── Processamento de notificações do Google Play (RTDN) ─────────────────────
// Mapeia subscriptionState pro mesmo vocabulário de notificationType da
// Apple, pra reaproveitar o roteamento acima sem duplicar a lógica.
const SUBSCRIPTION_STATE_PARA_NOTIFICATION_TYPE = {
  SUBSCRIPTION_STATE_ACTIVE: "DID_RENEW",
  SUBSCRIPTION_STATE_CANCELED: "DID_CHANGE_RENEWAL_STATUS",
  SUBSCRIPTION_STATE_IN_GRACE_PERIOD: "DID_FAIL_TO_RENEW",
  SUBSCRIPTION_STATE_ON_HOLD: "DID_FAIL_TO_RENEW",
  SUBSCRIPTION_STATE_EXPIRED: "EXPIRED",
  SUBSCRIPTION_STATE_REVOKED: "REVOKE",
  // Google permite o assinante pausar a assinatura (fica sem cobrar e sem
  // acesso até ele mesmo retomar) — sem acesso válido nesse meio tempo,
  // então trata igual a uma expiração; quando retomar, o próximo
  // SUBSCRIPTION_STATE_ACTIVE reativa normalmente.
  SUBSCRIPTION_STATE_PAUSED: "EXPIRED",
};

async function processarNotificacaoGooglePlay(purchaseToken, serviceAccountJson) {
  const compra = await verificarCompraAndroid(purchaseToken, serviceAccountJson);
  const item = (compra.lineItems || [])[0];
  const renovacaoAutomatica = !!item?.autoRenewingPlan?.autoRenewEnabled;
  const notificationType =
    SUBSCRIPTION_STATE_PARA_NOTIFICATION_TYPE[compra.subscriptionState];
  if (!notificationType) {
    logger.info(
      `processarNotificacaoGooglePlay: subscriptionState ${compra.subscriptionState} sem tratamento específico`
    );
    return;
  }
  if (notificationType === "DID_CHANGE_RENEWAL_STATUS") {
    // Cancelado continua ativo até expirar — o roteamento só muda o status
    // de superfície, então não precisa dos dados de reativação.
    await rotearNotificacaoAssinatura({
      notificationType,
      originalTransactionId: purchaseToken,
      renovacaoAutomatica: false,
    });
    return;
  }
  if (!item && notificationType === "DID_RENEW") return;

  await rotearNotificacaoAssinatura({
    notificationType,
    originalTransactionId: purchaseToken,
    productId: item?.productId,
    plataforma: "android",
    ambiente: compra.testPurchase ? "sandbox" : "production",
    expiresAtMs: item?.expiryTime ? new Date(item.expiryTime).getTime() : 0,
    transactionId: item?.latestSuccessfulOrderId || null,
    renovacaoAutomatica,
  });
}

// ── Cloud Functions expostas ─────────────────────────────────────────────────

exports.ativarAssinaturaIOS = onCall(
  { secrets: [APPLE_APP_ID], region: "us-central1" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Não autenticado.");
    }
    const { academiaId, jwsTransaction } = request.data || {};
    if (!academiaId || !jwsTransaction) {
      throw new HttpsError("invalid-argument", "Dados da compra incompletos.");
    }

    let decoded, ambiente;
    try {
      const appAppleId = Number(APPLE_APP_ID.value()) || undefined;
      const resultado = await verificarTransacaoApple(
        jwsTransaction,
        appAppleId
      );
      decoded = resultado.decoded;
      ambiente = resultado.ambiente;
    } catch (e) {
      logger.error("ativarAssinaturaIOS: falha ao verificar transação", e);
      throw new HttpsError(
        "permission-denied",
        "Não foi possível validar a compra junto à Apple."
      );
    }

    if (decoded.bundleId !== BUNDLE_ID) {
      throw new HttpsError("permission-denied", "Aplicativo não corresponde.");
    }
    if (decoded.revocationDate) {
      throw new HttpsError(
        "permission-denied",
        "Essa transação foi revogada/reembolsada."
      );
    }

    return processarAtivacaoAssinatura({
      academiaId,
      productId: decoded.productId,
      plataforma: "ios",
      ambiente,
      expiresAtMs: decoded.expiresDate,
      transactionId: decoded.transactionId,
      originalTransactionId: decoded.originalTransactionId,
    });
  }
);

const ESTADOS_ANDROID_INVALIDOS = new Set([
  "SUBSCRIPTION_STATE_EXPIRED",
  "SUBSCRIPTION_STATE_REVOKED",
  "SUBSCRIPTION_STATE_PENDING",
]);

exports.ativarAssinaturaAndroid = onCall(
  { secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT_JSON], region: "us-central1" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Não autenticado.");
    }
    const { academiaId, purchaseToken } = request.data || {};
    if (!academiaId || !purchaseToken) {
      throw new HttpsError("invalid-argument", "Dados da compra incompletos.");
    }

    let compra;
    try {
      compra = await verificarCompraAndroid(
        purchaseToken,
        GOOGLE_PLAY_SERVICE_ACCOUNT_JSON.value()
      );
    } catch (e) {
      logger.error("ativarAssinaturaAndroid: falha ao verificar compra", e);
      throw new HttpsError(
        "permission-denied",
        "Não foi possível validar a compra junto à Google Play."
      );
    }

    if (ESTADOS_ANDROID_INVALIDOS.has(compra.subscriptionState)) {
      throw new HttpsError("permission-denied", "Assinatura inválida.");
    }
    const item = (compra.lineItems || [])[0];
    if (!item) {
      throw new HttpsError("permission-denied", "Assinatura sem item válido.");
    }

    return processarAtivacaoAssinatura({
      academiaId,
      productId: item.productId,
      plataforma: "android",
      ambiente: compra.testPurchase ? "sandbox" : "production",
      expiresAtMs: item.expiryTime ? new Date(item.expiryTime).getTime() : 0,
      transactionId: item.latestSuccessfulOrderId || null,
      originalTransactionId: purchaseToken,
      renovacaoAutomatica: !!item.autoRenewingPlan?.autoRenewEnabled,
    });
  }
);

// Configurar em: App Store Connect → app → App Information →
// App Store Server Notifications → URL de produção/sandbox (V2).
// Sempre responde 200 (mesmo em erro interno, só loga) — mesmo padrão do
// webhookAsaas, pra não fazer a Apple reenviar em loop.
exports.webhookAppStoreNotifications = onRequest(
  { secrets: [APPLE_APP_ID], region: "us-central1" },
  async (req, res) => {
    try {
      const signedPayload = req.body?.signedPayload;
      if (!signedPayload) {
        res.status(200).send("OK");
        return;
      }
      const appAppleId = Number(APPLE_APP_ID.value()) || undefined;
      const { decoded } = await verificarNotificacaoApple(
        signedPayload,
        appAppleId
      );
      await processarNotificacaoApple(decoded, appAppleId);
    } catch (e) {
      logger.error("webhookAppStoreNotifications: erro ao processar", e);
    }
    res.status(200).send("OK");
  }
);

// Configurar em: Google Cloud Console → Pub/Sub → criar tópico "play-rtdn" →
// Play Console → app → Monetização → Notificações em tempo real → apontar
// pra esse tópico. A function se inscreve nele automaticamente no deploy.
exports.webhookGooglePlayNotifications = onMessagePublished(
  {
    topic: GOOGLE_PLAY_RTDN_TOPIC,
    secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT_JSON],
    region: "us-central1",
  },
  async (event) => {
    try {
      const payload = event.data.message.json;
      const purchaseToken = payload?.subscriptionNotification?.purchaseToken;
      if (!purchaseToken) {
        logger.info(
          "webhookGooglePlayNotifications: evento ignorado (sem subscriptionNotification)",
          payload
        );
        return;
      }
      await processarNotificacaoGooglePlay(
        purchaseToken,
        GOOGLE_PLAY_SERVICE_ACCOUNT_JSON.value()
      );
    } catch (e) {
      logger.error("webhookGooglePlayNotifications: erro ao processar", e);
    }
  }
);

exports._internal = {
  processarAtivacaoAssinatura,
  atualizarStatusAssinatura,
  revogarAssinatura,
  buscarAcademiaPorOriginalTransactionId,
  rotearNotificacaoAssinatura,
  processarNotificacaoApple,
  processarNotificacaoGooglePlay,
  verificarTransacaoApple,
  verificarCompraAndroid,
  PRODUTOS_VALIDOS,
  BUNDLE_ID,
  SUBSCRIPTION_STATE_PARA_NOTIFICATION_TYPE,
};
