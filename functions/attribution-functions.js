"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();

// Só aceitamos registrar atribuição logo após o cadastro, nunca depois —
// evita que alguém chame esta function muito depois pra "plantar" origem
// numa academia que não acabou de criar.
const JANELA_REGISTRO_MS = 30 * 60 * 1000;

const CLASSIFICACOES_VALIDAS = new Set(["identificada", "direta_presumida", "nao_identificada"]);

function sanitizarTexto(valor, tamanhoMax) {
  if (typeof valor !== "string") return null;
  const limpo = valor.trim().slice(0, tamanhoMax);
  return limpo || null;
}

/**
 * Callable que grava a atribuição de origem (UTM/click id/referrer) da
 * academia recém-criada em `academias/{id}/_atribuicao/dados`. O cliente
 * (CRM) nunca escreve essa subcoleção direto — as regras do Firestore
 * bloqueiam leitura E escrita client-side (ver `firestore.rules`), então
 * mesmo um navegador adulterado só consegue *propor* os dados pra esta
 * function, que valida e decide o que de fato é gravado.
 */
exports.registrarAtribuicaoCadastro = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "É necessário autenticar antes de registrar a origem do cadastro.");
  }

  const academiaId = String(request.data?.academiaId ?? "").trim();
  if (!academiaId) {
    throw new HttpsError("invalid-argument", "Informe a academia.");
  }

  const academiaSnap = await db.doc(`academias/${academiaId}`).get();
  if (!academiaSnap.exists) {
    throw new HttpsError("not-found", "Academia não encontrada.");
  }
  const academia = academiaSnap.data();

  if (academia.created_by_uid !== request.auth.uid) {
    throw new HttpsError("permission-denied", "Só quem criou a academia pode registrar a origem do cadastro.");
  }

  const criadoEm = academia.criado_em?.toMillis?.() ?? 0;
  if (!criadoEm || Date.now() - criadoEm > JANELA_REGISTRO_MS) {
    throw new HttpsError(
      "failed-precondition",
      "Janela de registro de origem expirada para esta academia."
    );
  }

  const atribuicaoRef = db.doc(`academias/${academiaId}/_atribuicao/dados`);
  const existente = await atribuicaoRef.get();
  if (existente.exists) {
    // Idempotente: não sobrescreve um registro já feito (ex.: retry de rede
    // no cliente não duplica nem "rouba" a atribuição original).
    return { ok: true, jaRegistrado: true };
  }

  const entrada = request.data?.atribuicao;
  const classificacao = CLASSIFICACOES_VALIDAS.has(entrada?.classificacao)
    ? entrada.classificacao
    : "nao_identificada";

  const dados = {
    classificacao,
    utm_source: sanitizarTexto(entrada?.utm_source, 100),
    utm_medium: sanitizarTexto(entrada?.utm_medium, 100),
    utm_campaign: sanitizarTexto(entrada?.utm_campaign, 150),
    utm_term: sanitizarTexto(entrada?.utm_term, 150),
    utm_content: sanitizarTexto(entrada?.utm_content, 150),
    click_id: sanitizarTexto(entrada?.click_id, 150),
    click_id_type: sanitizarTexto(entrada?.click_id_type, 20),
    referrer_host: sanitizarTexto(entrada?.referrer_host, 200),
    registrado_em: admin.firestore.FieldValue.serverTimestamp(),
  };

  await atribuicaoRef.set(dados);
  logger.info("Atribuição de cadastro registrada", { academiaId, classificacao });
  return { ok: true, jaRegistrado: false };
});
