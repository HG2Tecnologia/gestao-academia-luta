"use strict";

const fs = require("fs");
const path = require("path");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
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

// ── Apple: verificação criptográfica da transação (JWS assinado pela Apple) ──
// Única peça que não dá pra cobrir com teste automatizado sem uma transação
// de verdade assinada pela Apple — por isso fica isolada e fina, delegando
// toda a verificação (cadeia de certificado, assinatura, expiração) pra lib
// oficial da Apple. A lógica de negócio (produto válido, não revogado, não
// expirado, escrita no Firestore) fica em processarAtivacaoAssinatura, que
// essa sim é 100% coberta por teste.
async function verificarTransacaoApple(jwsTransaction, appAppleId) {
  const verificadorProducao = new SignedDataVerifier(
    appleRootCAs,
    true,
    Environment.PRODUCTION,
    BUNDLE_ID,
    appAppleId
  );
  try {
    const decoded = await verificadorProducao.verifyAndDecodeTransaction(
      jwsTransaction
    );
    return { decoded, ambiente: "production" };
  } catch (e) {
    if (
      e instanceof VerificationException &&
      e.status === VerificationStatus.INVALID_ENVIRONMENT
    ) {
      const verificadorSandbox = new SignedDataVerifier(
        appleRootCAs,
        true,
        Environment.SANDBOX,
        BUNDLE_ID
      );
      const decoded = await verificadorSandbox.verifyAndDecodeTransaction(
        jwsTransaction
      );
      return { decoded, ambiente: "sandbox" };
    }
    throw e;
  }
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
// genuína (Apple ou Google) — aqui só restam as regras de negócio.
async function processarAtivacaoAssinatura({
  academiaId,
  productId,
  plataforma,
  ambiente,
  expiresAtMs,
  transactionId,
  originalTransactionId,
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
    });
  }
);

exports._internal = {
  processarAtivacaoAssinatura,
  verificarTransacaoApple,
  verificarCompraAndroid,
  PRODUTOS_VALIDOS,
  BUNDLE_ID,
};
