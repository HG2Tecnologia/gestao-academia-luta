"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");

const db = admin.firestore();

// Só aceitamos registrar atribuição logo após o cadastro, nunca depois —
// evita que alguém chame esta function muito depois pra "plantar" origem
// numa academia que não acabou de criar.
const JANELA_REGISTRO_MS = 30 * 60 * 1000;

// Retenção: 90 dias, aprovado para o campo `expira_em` usado pela
// política de TTL nativa do Firestore (ver nota de retenção abaixo e
// `scripts/migrate-firestore/firestore-ttl-atribuicao.md` pra a
// configuração da política em si — NÃO aplicada ainda).
const RETENCAO_ATRIBUICAO_MS = 90 * 24 * 60 * 60 * 1000;

const CLASSIFICACOES_VALIDAS = new Set(["identificada", "direta_presumida", "nao_identificada"]);
const CLICK_ID_TYPES_VALIDOS = new Set(["gclid", "gbraid", "wbraid"]);

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
 *
 * Consentimento — IMPORTANTE, leia antes de confiar neste controle: o
 * campo `consentimentoAnalytics: true` exigido abaixo é uma DECLARAÇÃO do
 * cliente, não uma PROVA independente de consentimento. A function não
 * tem como verificar, do lado do servidor, se o usuário realmente clicou
 * "aceitar" — ela só recusa gravar quando essa declaração está ausente
 * ou falsa, o que impede o caso mais comum (código que esqueceu de
 * checar consentimento, ou tentativa de replay de uma chamada antiga sem
 * o campo). Um cliente deliberadamente adulterado ainda poderia mandar
 * `true` mesmo sem consentimento real — nenhuma arquitetura client+server
 * simples elimina isso sem um sistema de consentimento assinado/
 * verificável (ex.: um token de consentimento emitido e validado por uma
 * function própria no momento do clique, não implementado aqui). Esse é
 * o limite real deste controle; não tratar como garantia absoluta.
 *
 * Minimização/acesso/retenção dos dados de atribuição (revisão, sem
 * ampliar o que já era coletado):
 * — Minimização: só os campos abaixo (UTM, click id, host do referrer,
 *   classificação, timestamp) — nenhum campo novo foi adicionado nesta
 *   revisão, nenhum dado de identificação direta (nome/e-mail/telefone)
 *   passa por este arquivo.
 * — Acesso: `academias/{id}/_atribuicao/{doc}` tem leitura E escrita
 *   bloqueadas pra qualquer perfil client-side nas regras do Firestore
 *   (testado no Emulator) — só esta function, com o Admin SDK, lê/escreve.
 * — `academiaId` não é PII por si só, mas é tratado aqui como
 *   potencialmente associável a uma pessoa (o Admin que criou a
 *   academia), por isso nunca é cruzado com nome/e-mail/telefone nos logs.
 * — Retenção: **90 dias, aprovado.** Cada doc grava `expira_em` (Timestamp
 *   = agora + 90 dias, calculado no relógio do servidor, nunca recebido
 *   do cliente). Sem job/function agendada nova — a exclusão em si é
 *   feita pela política de TTL NATIVA do Firestore, configurada fora
 *   deste código (ver `scripts/migrate-firestore/firestore-ttl-atribuicao.md`
 *   — a política ainda NÃO foi aplicada em produção, só documentada/
 *   preparada). Documentos gravados antes da política existir, ou se ela
 *   nunca for aplicada, simplesmente mantêm o campo `expira_em` sem efeito
 *   nenhum — não são expurgados por nenhum outro mecanismo.
 */
exports.registrarAtribuicaoCadastro = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "É necessário autenticar antes de registrar a origem do cadastro.");
  }

  const academiaId = String(request.data?.academiaId ?? "").trim();
  if (!academiaId) {
    throw new HttpsError("invalid-argument", "Informe a academia.");
  }

  if (request.data?.consentimentoAnalytics !== true) {
    logger.warn("Atribuição rejeitada: sem declaração explícita de consentimento", { academiaId });
    throw new HttpsError("invalid-argument", "Consentimento de análise não confirmado.");
  }

  const academiaSnap = await db.doc(`academias/${academiaId}`).get();
  if (!academiaSnap.exists) {
    logger.warn("Atribuição rejeitada: academia inexistente", { academiaId });
    throw new HttpsError("not-found", "Academia não encontrada.");
  }
  const academia = academiaSnap.data();

  if (academia.created_by_uid !== request.auth.uid) {
    logger.warn("Atribuição rejeitada: uid não é o criador da academia", { academiaId });
    throw new HttpsError("permission-denied", "Só quem criou a academia pode registrar a origem do cadastro.");
  }

  const criadoEm = academia.criado_em?.toMillis?.() ?? 0;
  if (!criadoEm || Date.now() - criadoEm > JANELA_REGISTRO_MS) {
    logger.warn("Atribuição rejeitada: fora da janela de registro", { academiaId });
    throw new HttpsError(
      "failed-precondition",
      "Janela de registro de origem expirada para esta academia."
    );
  }

  const atribuicaoRef = db.doc(`academias/${academiaId}/_atribuicao/dados`);

  let dadosGravados;
  try {
    dadosGravados = await db.runTransaction(async (tx) => {
      const existente = await tx.get(atribuicaoRef);
      if (existente.exists) {
        // Idempotente: não sobrescreve um registro já feito (ex.: retry de
        // rede no cliente não duplica nem "rouba" a atribuição original).
        // Transação garante que duas chamadas concorrentes (ex.: 2 abas)
        // não resultem numa gravação dupla/corrida.
        return null;
      }

      const entrada = request.data?.atribuicao;
      const classificacao = CLASSIFICACOES_VALIDAS.has(entrada?.classificacao)
        ? entrada.classificacao
        : "nao_identificada";
      const clickIdType = CLICK_ID_TYPES_VALIDOS.has(entrada?.click_id_type)
        ? entrada.click_id_type
        : null;

      const dados = {
        classificacao,
        utm_source: sanitizarTexto(entrada?.utm_source, 100),
        utm_medium: sanitizarTexto(entrada?.utm_medium, 100),
        utm_campaign: sanitizarTexto(entrada?.utm_campaign, 150),
        utm_term: sanitizarTexto(entrada?.utm_term, 150),
        utm_content: sanitizarTexto(entrada?.utm_content, 150),
        click_id: clickIdType ? sanitizarTexto(entrada?.click_id, 150) : null,
        click_id_type: clickIdType,
        referrer_host: sanitizarTexto(entrada?.referrer_host, 200),
        registrado_em: FieldValue.serverTimestamp(),
        // Calculado no relógio do servidor (Cloud Functions), nunca a
        // partir de um valor vindo do cliente — evita que um payload
        // adulterado estenda a própria retenção.
        expira_em: Timestamp.fromMillis(Date.now() + RETENCAO_ATRIBUICAO_MS),
      };
      tx.set(atribuicaoRef, dados);
      return dados;
    });
  } catch (erro) {
    logger.error("Falha ao gravar atribuição de cadastro", { academiaId, erro: String(erro) });
    throw new HttpsError("internal", "Não foi possível registrar a origem do cadastro agora.");
  }

  if (!dadosGravados) {
    return { ok: true, jaRegistrado: true };
  }

  logger.info("Atribuição de cadastro registrada", { academiaId, classificacao: dadosGravados.classificacao });
  return { ok: true, jaRegistrado: false };
});
