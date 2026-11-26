"use strict";

const crypto = require("crypto");
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
const { FieldValue } = require("firebase-admin/firestore");
const { GMAIL_APP_PASSWORD, enviarAvisoInterno, esc } = require("./mailer");
const {
  PRODUTOS_VALIDOS,
  liberaWeb,
  motivoParaIgnorar,
  itemVigenteGoogle,
  podeAtivarAssinatura,
  usaAssinaturaDeLoja,
  ORIGENS_SEM_LOJA,
} = require("./domain/subscription-access");

const db = admin.firestore();

const BUNDLE_ID = "br.com.hg2tecnologia.senseimanager";
const ANDROID_PACKAGE_NAME = "br.com.hg2tecnologia.senseimanager";
const GOOGLE_PLAY_RTDN_TOPIC = "play-rtdn";

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

// Confirma ("acknowledge") a compra junto à Google — obrigatório em até 3 dias
// pra toda assinatura Android nova, senão o Google reembolsa automaticamente
// (foi exatamente o que quase aconteceu com o Maykon/Dojô Coelho: a compra
// nunca tinha sido reconhecida pelo app). Nunca precisa em renovação — só na
// primeira ativação de cada assinatura. `subscriptionId` aqui é o próprio
// `productId` (nome do produto), que é o que a API v1 de assinaturas espera.
async function confirmarCompraAndroid(purchaseToken, productId, serviceAccountJsonRaw) {
  const credentials = JSON.parse(serviceAccountJsonRaw);
  const auth = new google.auth.GoogleAuth({
    credentials,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const androidpublisher = google.androidpublisher({ version: "v3", auth });
  await androidpublisher.purchases.subscriptions.acknowledge({
    packageName: ANDROID_PACKAGE_NAME,
    subscriptionId: productId,
    token: purchaseToken,
    requestBody: {},
  });
}

// ── Histórico de assinatura (append-only) ───────────────────────────────────
// Nunca lança: é só auditoria/aviso, uma falha aqui não pode derrubar a
// atualização de verdade do plano que já aconteceu.
async function registrarEventoAssinatura({
  academiaId,
  evento,
  produto,
  plataforma,
  statusAnterior,
  statusNovo,
  origem,
}) {
  try {
    await db.collection("eventos_assinatura").add({
      academiaId,
      evento,
      produto: produto || null,
      plataforma: plataforma || null,
      status_anterior: statusAnterior ?? null,
      status_novo: statusNovo ?? null,
      origem,
      criado_em: FieldValue.serverTimestamp(),
    });
  } catch (e) {
    logger.error("registrarEventoAssinatura: falha ao gravar evento", {
      academiaId, evento, motivo: e.message,
    });
  }
}

// E-mail pra equipe HG2 quando um assinante precisa de atenção (cancelou,
// falhou cobrança, foi reembolsado ou expirou) — nunca em renovação normal,
// só o que vale a pena olhar. Mesmo padrão "melhor esforço" dos outros
// e-mails internos: falha de envio só loga, nunca interrompe nada.
async function avisarEventoAssinatura({ academiaId, evento, status }) {
  try {
    const academiaSnap = await db.doc(`academias/${academiaId}`).get();
    const academia = academiaSnap.data() || {};
    const nome = academia.nome || "—";
    const telefone = academia.telefone || "não informado";
    await enviarAvisoInterno({
      subject: `Assinatura: ${nome} — ${status}`,
      text:
        `Evento de assinatura que pode precisar da sua atenção.\n\n` +
        `Academia: ${nome}\nTelefone: ${telefone}\nID: ${academiaId}\n` +
        `Evento: ${evento}\nStatus: ${status}\n`,
      html:
        `<p>Evento de assinatura que pode precisar da sua atenção.</p>` +
        `<ul><li><b>Academia:</b> ${esc(nome)}</li>` +
        `<li><b>Telefone:</b> ${esc(telefone)}</li>` +
        `<li><b>ID:</b> ${esc(academiaId)}</li>` +
        `<li><b>Evento:</b> ${esc(evento)}</li>` +
        `<li><b>Status:</b> ${esc(status)}</li></ul>`,
    });
  } catch (e) {
    logger.error("avisarEventoAssinatura: falha ao enviar e-mail", {
      academiaId, evento, motivo: e.message,
    });
  }
}

// ── Quem pode ativar, e uma compra por academia ─────────────────────────────

// Sem isto, qualquer conta autenticada ativaria o plano em qualquer academia.
async function exigirEquipeDaAcademia(uid, academiaId) {
  if (typeof academiaId !== "string" || academiaId.includes("/")) {
    throw new HttpsError("invalid-argument", "Academia inválida.");
  }
  const conta = (await db.collection("usuariosFirebase").doc(uid).get()).data();
  if (!podeAtivarAssinatura(conta, academiaId)) {
    logger.warn("exigirEquipeDaAcademia: ativação recusada", { uid, academiaId });
    throw new HttpsError(
      "permission-denied",
      "Você não tem permissão para ativar a assinatura desta academia."
    );
  }
}

// Documento único por compra: ler e gravar nele dentro da transação impede que
// duas academias ativem a mesma compra ao mesmo tempo. Só o servidor acessa.
function refVinculoAssinatura(plataforma, originalTransactionId) {
  const id = crypto
    .createHash("sha256")
    .update(`${plataforma}:${originalTransactionId}`)
    .digest("hex");
  return db.collection("vinculos_assinatura").doc(id);
}

// Só faz leituras (numa transação, todas precisam vir antes das gravações).
// Recusa a compra em uso por outra academia; devolve as que ainda guardam o
// identificador sem usá-lo, para serem liberadas.
async function conferirCompraLivre(transaction, { academiaId, identificadores, vinculoRef }) {
  await transaction.get(vinculoRef);
  const snap = await transaction.get(
    db.collection("academias").where("plano_original_transaction_id", "in", identificadores)
  );
  const outras = snap.docs.filter((d) => d.id !== academiaId);
  if (outras.some((d) => usaAssinaturaDeLoja(d.data()))) {
    throw new HttpsError(
      "already-exists",
      "Esta assinatura já está em uso por outra academia. Fale com o suporte."
    );
  }
  return outras;
}

// ── Núcleo comum: valida os dados já verificados e grava no Firestore ───────
// Só é chamado depois que a assinatura/transação já foi confirmada como
// genuína (Apple ou Google) — aqui só restam as regras de negócio. Cobre
// tanto a primeira ativação (chamada pelo app) quanto uma renovação
// detectada via webhook — é a mesma operação de negócio nos dois casos.
// `origemEvento` é só pra auditoria em `eventos_assinatura` (quem disparou
// essa ativação) — nunca confundir com `plano_origem` (gravado sempre como
// "loja" aqui, porque só chega até aqui quem já validou de verdade com a
// Apple/Google).
async function processarAtivacaoAssinatura({
  academiaId,
  productId,
  plataforma,
  ambiente,
  expiresAtMs,
  transactionId,
  originalTransactionId,
  renovacaoAutomatica,
  // Data da transação (Apple), para não aplicar uma mais antiga por cima.
  transacaoEmMs,
  // Compra que esta substitui (`linkedPurchaseToken` do Google).
  compraAnteriorId,
  origemEvento = "app",
}) {
  if (!PRODUTOS_VALIDOS.has(productId)) {
    throw new HttpsError("invalid-argument", "Produto desconhecido.");
  }
  if (!expiresAtMs || expiresAtMs < Date.now()) {
    throw new HttpsError("permission-denied", "Assinatura expirada.");
  }

  const academiaRef = db.doc(`academias/${academiaId}`);
  const { statusAnterior, jaTemAssinaturaDesde, liberadas, ignorada } = await db.runTransaction(
    async (transaction) => {
      const academiaSnap = await transaction.get(academiaRef);
      if (!academiaSnap.exists) {
        throw new HttpsError("not-found", "Academia não encontrada.");
      }
      const atual = academiaSnap.data();

      const motivo = motivoParaIgnorar(atual, {
        originalTransactionId,
        compraAnteriorId,
        productId,
        expiresAtMs,
        transacaoEmMs,
      });
      if (motivo) return { ignorada: motivo, liberadas: [] };

      // Só a ativação pedida pelo app cria um vínculo novo. Webhook e
      // reconciliação já partem da academia que tem a compra. Quem já tinha o
      // identificador gravado segue renovando normalmente.
      let vinculoRef = null;
      let outras = [];
      if (
        origemEvento === "app" &&
        originalTransactionId &&
        atual.plano_original_transaction_id !== originalTransactionId
      ) {
        vinculoRef = refVinculoAssinatura(plataforma, originalTransactionId);
        // Uma troca feita sobre a compra de outra academia também é recusada.
        const substituida =
          compraAnteriorId && atual.plano_original_transaction_id !== compraAnteriorId;
        outras = await conferirCompraLivre(transaction, {
          academiaId,
          identificadores: substituida
            ? [originalTransactionId, compraAnteriorId]
            : [originalTransactionId],
          vinculoRef,
        });
      }

      for (const outra of outras) {
        const d = outra.data();
        const perdeAcesso = d.plano_tipo >= 1 && !ORIGENS_SEM_LOJA.has(d.plano_origem);
        transaction.update(outra.ref, {
          plano_original_transaction_id: FieldValue.delete(),
          ...(perdeAcesso
            ? { plano_tipo: 0, plano_status: "transferido", acesso_web: false }
            : {}),
        });
      }
      if (vinculoRef) {
        transaction.set(vinculoRef, {
          academiaId,
          plataforma,
          atualizado_em: FieldValue.serverTimestamp(),
        });
      }

      const jaAssinou = atual.plano_assinado_em != null;
      transaction.update(academiaRef, {
        plano_tipo: 1,
        plano_status: "ativo",
        plano_origem: "loja",
        plano_renovacao_automatica: renovacaoAutomatica ?? true,
        plano_expiracao: new Date(expiresAtMs).toISOString(),
        plano_produto_id: productId,
        plano_plataforma: plataforma,
        plano_ambiente: ambiente,
        plano_transaction_id: transactionId || null,
        plano_original_transaction_id: originalTransactionId || null,
        plano_transacao_em: transacaoEmMs ? new Date(transacaoEmMs).toISOString() : null,
        acesso_web: liberaWeb(productId),
        ...(jaAssinou ? {} : { plano_assinado_em: new Date().toISOString() }),
      });

      return {
        statusAnterior: atual.plano_status ?? null,
        jaTemAssinaturaDesde: jaAssinou,
        liberadas: outras.map((d) => ({ id: d.id, status: d.data().plano_status ?? null })),
      };
    }
  );

  if (ignorada) {
    logger.info(
      `processarAtivacaoAssinatura: academia ${academiaId}, produto ${productId} ignorado (${ignorada})`
    );
    return { ok: true, ambiente, ignorada };
  }

  for (const outra of liberadas) {
    await registrarEventoAssinatura({
      academiaId: outra.id,
      evento: "assinatura_transferida",
      plataforma,
      statusAnterior: outra.status,
      statusNovo: "transferido",
      origem: origemEvento,
    });
  }

  await registrarEventoAssinatura({
    academiaId,
    evento: jaTemAssinaturaDesde ? "renovacao" : "ativacao",
    produto: productId,
    plataforma,
    statusAnterior,
    statusNovo: "ativo",
    origem: origemEvento,
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
  origemEvento = "webhook",
}) {
  const academiaRef = db.doc(`academias/${academiaId}`);
  const academiaSnap = await academiaRef.get();
  const statusAnterior = academiaSnap.data()?.plano_status ?? null;

  const update = { plano_status: status };
  if (renovacaoAutomatica !== undefined) {
    update.plano_renovacao_automatica = renovacaoAutomatica;
  }
  await academiaRef.update(update);
  logger.info(`atualizarStatusAssinatura: academia ${academiaId} -> ${status}`);

  await registrarEventoAssinatura({
    academiaId,
    evento: "status_atualizado",
    statusAnterior,
    statusNovo: status,
    origem: origemEvento,
  });
  if (status === "periodo_carencia") {
    await avisarEventoAssinatura({ academiaId, evento: "falha_cobranca", status });
  }
}

// Revoga o Pro imediatamente — usado em reembolso/revogação (não espera a
// data de expiração, porque o pagamento já não é mais válido) e em
// expiração definitiva (fim do período de carência sem sucesso de cobrança).
async function revogarAssinatura({ academiaId, status, origemEvento = "webhook" }) {
  const academiaRef = db.doc(`academias/${academiaId}`);
  const academiaSnap = await academiaRef.get();
  const statusAnterior = academiaSnap.data()?.plano_status ?? null;

  await academiaRef.update({
    plano_tipo: 0,
    plano_status: status,
    acesso_web: false,
  });
  logger.info(`revogarAssinatura: academia ${academiaId} -> ${status}`);

  await registrarEventoAssinatura({
    academiaId,
    evento: "revogado",
    statusAnterior,
    statusNovo: status,
    origem: origemEvento,
  });
  await avisarEventoAssinatura({ academiaId, evento: "revogado", status });
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
  transacaoEmMs,
  origemEvento = "webhook",
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

  // Reembolso ou expiração de uma transação já substituída (ex.: o período
  // anterior a um upgrade) não mexe no plano atual.
  if (transacaoEmMs) {
    const atual = (await db.doc(`academias/${academiaId}`).get()).data() || {};
    if (transacaoEmMs < Date.parse(atual.plano_transacao_em)) {
      logger.info(
        `rotearNotificacaoAssinatura: ${notificationType} de transação antiga ignorado (academia ${academiaId})`
      );
      return;
    }
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
        transacaoEmMs,
        origemEvento,
      });
      break;
    case "DID_CHANGE_RENEWAL_STATUS":
      await atualizarStatusAssinatura({
        academiaId,
        status: renovacaoAutomatica === false ? "cancelado_ate_expirar" : "ativo",
        renovacaoAutomatica,
        origemEvento,
      });
      break;
    case "DID_FAIL_TO_RENEW":
      await atualizarStatusAssinatura({ academiaId, status: "periodo_carencia", origemEvento });
      break;
    case "GRACE_PERIOD_EXPIRED":
    case "EXPIRED":
      await revogarAssinatura({ academiaId, status: "expirado", origemEvento });
      break;
    case "ON_HOLD":
      await revogarAssinatura({ academiaId, status: "suspenso", origemEvento });
      break;
    case "REFUND":
    case "REVOKE":
      await revogarAssinatura({ academiaId, status: "reembolsado", origemEvento });
      break;
    default:
      logger.info(
        `rotearNotificacaoAssinatura: notificationType ${notificationType} sem tratamento específico, ignorado`
      );
  }
}

// ── Processamento de notificações da Apple (App Store Server Notifications V2) ──
async function processarNotificacaoApple(decoded, appAppleId, origemEvento = "webhook") {
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
    transacaoEmMs: transacao.purchaseDate,
    origemEvento,
  });
}

// ── Processamento de notificações do Google Play (RTDN) ─────────────────────
// Mapeia subscriptionState pro mesmo vocabulário de notificationType da
// Apple, pra reaproveitar o roteamento acima sem duplicar a lógica.
const SUBSCRIPTION_STATE_PARA_NOTIFICATION_TYPE = {
  SUBSCRIPTION_STATE_ACTIVE: "DID_RENEW",
  SUBSCRIPTION_STATE_CANCELED: "DID_CHANGE_RENEWAL_STATUS",
  SUBSCRIPTION_STATE_IN_GRACE_PERIOD: "DID_FAIL_TO_RENEW",
  // Suspensão de conta: a cobrança falhou e a carência acabou. A Google
  // manda retirar o acesso; volta com o próximo SUBSCRIPTION_STATE_ACTIVE.
  // "ON_HOLD" não existe nas notificações da Apple.
  SUBSCRIPTION_STATE_ON_HOLD: "ON_HOLD",
  SUBSCRIPTION_STATE_EXPIRED: "EXPIRED",
  SUBSCRIPTION_STATE_REVOKED: "REVOKE",
  // Google permite o assinante pausar a assinatura (fica sem cobrar e sem
  // acesso até ele mesmo retomar) — sem acesso válido nesse meio tempo,
  // então trata igual a uma expiração; quando retomar, o próximo
  // SUBSCRIPTION_STATE_ACTIVE reativa normalmente.
  SUBSCRIPTION_STATE_PAUSED: "EXPIRED",
};

async function processarNotificacaoGooglePlay(purchaseToken, serviceAccountJson, origemEvento = "webhook") {
  const compra = await verificarCompraAndroid(purchaseToken, serviceAccountJson);
  await aplicarCompraGoogle(purchaseToken, compra, origemEvento);
}

// Estados em que uma compra nova pode assumir o lugar da anterior.
const ESTADOS_ANDROID_COM_ACESSO = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_CANCELED",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
]);

const renovaNoGoogle = (item) =>
  !!item?.autoRenewingPlan?.autoRenewEnabled || !!item?.deferredItemReplacement;

const dadosDaCompraAndroid = (item, compra) => ({
  productId: item?.productId,
  plataforma: "android",
  ambiente: compra.testPurchase ? "sandbox" : "production",
  expiresAtMs: item?.expiryTime ? new Date(item.expiryTime).getTime() : 0,
  transactionId: item?.latestSuccessfulOrderId || null,
});

async function aplicarCompraGoogle(purchaseToken, compra, origemEvento = "webhook") {
  const item = itemVigenteGoogle(compra.lineItems);
  const renovacaoAutomatica = renovaNoGoogle(item);
  const notificationType =
    SUBSCRIPTION_STATE_PARA_NOTIFICATION_TYPE[compra.subscriptionState];
  if (!notificationType) {
    logger.info(
      `processarNotificacaoGooglePlay: subscriptionState ${compra.subscriptionState} sem tratamento específico`
    );
    return;
  }

  // Troca de plano ou reassinatura gera um token novo. Se o app ainda não o
  // registrou, a academia é encontrada pelo token anterior.
  const anterior = compra.linkedPurchaseToken;
  if (anterior && !(await buscarAcademiaPorOriginalTransactionId(purchaseToken))) {
    const academiaId = await buscarAcademiaPorOriginalTransactionId(anterior);
    const dados = dadosDaCompraAndroid(item, compra);
    if (
      !academiaId ||
      !ESTADOS_ANDROID_COM_ACESSO.has(compra.subscriptionState) ||
      !(dados.expiresAtMs > Date.now())
    ) {
      return;
    }
    await processarAtivacaoAssinatura({
      academiaId,
      ...dados,
      originalTransactionId: purchaseToken,
      compraAnteriorId: anterior,
      renovacaoAutomatica,
      origemEvento,
    });
    // A ativação grava "ativo"; os outros estados são aplicados em seguida.
    if (notificationType === "DID_RENEW") return;
  }

  if (notificationType === "DID_CHANGE_RENEWAL_STATUS") {
    // Cancelado continua ativo até expirar — o roteamento só muda o status
    // de superfície, então não precisa dos dados de reativação.
    await rotearNotificacaoAssinatura({
      notificationType,
      originalTransactionId: purchaseToken,
      renovacaoAutomatica: false,
      origemEvento,
    });
    return;
  }
  if (!item && notificationType === "DID_RENEW") return;

  await rotearNotificacaoAssinatura({
    notificationType,
    originalTransactionId: purchaseToken,
    ...dadosDaCompraAndroid(item, compra),
    renovacaoAutomatica,
    origemEvento,
  });
}

// Ativação pedida pelo app, com a compra já consultada na Google.
async function ativarCompraAndroid({ academiaId, purchaseToken, compra }) {
  if (ESTADOS_ANDROID_INVALIDOS.has(compra.subscriptionState)) {
    throw new HttpsError("permission-denied", "Assinatura inválida.");
  }
  const item = itemVigenteGoogle(compra.lineItems);
  if (!item) {
    throw new HttpsError("permission-denied", "Assinatura sem item válido.");
  }
  return processarAtivacaoAssinatura({
    academiaId,
    ...dadosDaCompraAndroid(item, compra),
    originalTransactionId: purchaseToken,
    compraAnteriorId: compra.linkedPurchaseToken || null,
    renovacaoAutomatica: renovaNoGoogle(item),
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
    await exigirEquipeDaAcademia(request.auth.uid, academiaId);

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
      transacaoEmMs: decoded.purchaseDate,
    });
  }
);

const ESTADOS_ANDROID_INVALIDOS = new Set([
  "SUBSCRIPTION_STATE_EXPIRED",
  "SUBSCRIPTION_STATE_REVOKED",
  "SUBSCRIPTION_STATE_PENDING",
  "SUBSCRIPTION_STATE_ON_HOLD",
  "SUBSCRIPTION_STATE_PAUSED",
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
    await exigirEquipeDaAcademia(request.auth.uid, academiaId);

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

    const item = itemVigenteGoogle(compra.lineItems);
    if (
      item &&
      !ESTADOS_ANDROID_INVALIDOS.has(compra.subscriptionState) &&
      compra.acknowledgementState === "ACKNOWLEDGEMENT_STATE_PENDING"
    ) {
      try {
        await confirmarCompraAndroid(
          purchaseToken,
          item.productId,
          GOOGLE_PLAY_SERVICE_ACCOUNT_JSON.value()
        );
      } catch (e) {
        // Não impede a ativação (o assinante já pagou e já validamos a
        // compra) — só loga, pra não deixar a confirmação pendente passar
        // batido e virar reembolso automático em 3 dias.
        logger.error("ativarAssinaturaAndroid: falha ao confirmar (acknowledge) a compra", {
          academiaId, motivo: e.message,
        });
      }
    }

    return ativarCompraAndroid({ academiaId, purchaseToken, compra });
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
  registrarEventoAssinatura,
  avisarEventoAssinatura,
  buscarAcademiaPorOriginalTransactionId,
  rotearNotificacaoAssinatura,
  processarNotificacaoApple,
  processarNotificacaoGooglePlay,
  aplicarCompraGoogle,
  ativarCompraAndroid,
  verificarTransacaoApple,
  verificarCompraAndroid,
  confirmarCompraAndroid,
  PRODUTOS_VALIDOS,
  BUNDLE_ID,
  SUBSCRIPTION_STATE_PARA_NOTIFICATION_TYPE,
};
