"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const { defineSecret } = require("firebase-functions/params");

/**
 * Mesma propriedade GA4 já ativa na HG2 (`G-1TW34PNK8R`) — NÃO criar uma
 * segunda propriedade. Ver nota de arquitetura abaixo sobre por que o
 * envio é feito pelo servidor (Measurement Protocol), não por `gtag.js`
 * no navegador.
 */
const GA4_MEASUREMENT_ID = "G-1TW34PNK8R";

/**
 * Secret do Measurement Protocol — gerado em GA4 Admin > Data Streams >
 * [stream] > Measurement Protocol API secrets. PENDENTE: precisa ser
 * criado e configurado (`firebase functions:secrets:set GA4_API_SECRET`)
 * antes do deploy desta function funcionar de fato — sem isso, o envio
 * falha silenciosamente (ver checagem abaixo) e só é logado, nunca quebra
 * nada pro usuário.
 */
const GA4_API_SECRET = defineSecret("GA4_API_SECRET");

/**
 * Por que Measurement Protocol (servidor) em vez de `gtag.js` (cliente):
 * investigação de causa raiz (comparando com o `gtag.js` já em produção
 * na HG2, mesmo Measurement ID) provou, com evidência de rede reproduzida
 * em 3 cenários independentes — página isolada sem nenhum código nosso,
 * app do CRM, e o próprio `gtag.js` "puro" da HG2 sem passar pelo
 * contêiner GTM dela — que esse Measurement ID, quando carregado de forma
 * autônoma (sem o contêiner GTM específico da HG2), NUNCA envia dados ao
 * GA4: só dispara os pixels da conta de Google Ads vinculada. Ou seja, o
 * destino GA4 desse "Google tag" só é alcançado através daquele contêiner
 * GTM específico — não é um bug no nosso código Angular, é uma
 * particularidade da configuração desse tag no lado do Google. Reusar o
 * contêiner GTM da HG2 misturaria tráfego do produto com o site
 * institucional; por isso o envio passou a ser feito direto pela API do
 * GA4 (Measurement Protocol), do nosso próprio servidor — determinístico,
 * testável, e sem depender de nenhum comportamento opaco de tag de
 * terceiros.
 *
 * Consentimento: mesma política do `registrarAtribuicaoCadastro` — a
 * function recusa gravar sem a declaração explícita `consentimentoAnalytics:
 * true`. Mesma ressalva: isso é uma declaração do cliente, não uma prova
 * independente (ver cabeçalho de `attribution-functions.js`).
 *
 * Minimização: só os parâmetros do evento abaixo (nenhum nome/e-mail/
 * telefone passa por aqui). `clientId` é um identificador opaco gerado no
 * navegador (não é PII, equivalente ao `_ga` do `gtag.js` padrão).
 */
const EVENTOS_VALIDOS = new Set(["page_view", "cadastro_iniciado", "sign_up"]);
const CLIENT_ID_REGEX = /^[0-9]{1,20}\.[0-9]{1,20}$/;
const SESSION_ID_REGEX = /^[0-9]{1,20}$/;

function sanitizarTexto(valor, tamanhoMax) {
  if (typeof valor !== "string") return null;
  const limpo = valor.trim().slice(0, tamanhoMax);
  return limpo || null;
}

function validarClientId(valor) {
  const limpo = typeof valor === "string" ? valor.trim() : "";
  return CLIENT_ID_REGEX.test(limpo) ? limpo : null;
}

function validarSessionId(valor) {
  const limpo = typeof valor === "string" ? valor.trim() : "";
  return SESSION_ID_REGEX.test(limpo) ? limpo : null;
}

function construirPayload({ clientId, nomeEvento, paramsEntrada }) {
  const params = {
    session_id: validarSessionId(paramsEntrada?.session_id) ?? undefined,
    engagement_time_msec: 1,
    page_location: sanitizarTexto(paramsEntrada?.page_location, 500) ?? undefined,
    page_title: sanitizarTexto(paramsEntrada?.page_title, 200) ?? undefined,
    method: nomeEvento === "sign_up" ? "email" : undefined,
  };
  Object.keys(params).forEach((chave) => {
    if (params[chave] === undefined) delete params[chave];
  });

  return {
    client_id: clientId,
    events: [{ name: nomeEvento, params }],
  };
}
exports.construirPayload = construirPayload;

/**
 * Callable pública (sem `request.auth` exigido — `page_view` e
 * `cadastro_iniciado` acontecem antes de qualquer login, na home/landing
 * pública). O mesmo risco de abuso já existe hoje com qualquer `gtag.js`
 * client-side comum (nada impede alguém de montar o POST do Measurement
 * Protocol direto pro Google, sem passar por nós) — esta function não
 * piora esse cenário de base, só move o envio real pro nosso servidor.
 */
exports.registrarEventoAnalytics = onCall({ secrets: [GA4_API_SECRET] }, async (request) => {
  if (request.data?.consentimentoAnalytics !== true) {
    throw new HttpsError("invalid-argument", "Consentimento de análise não confirmado.");
  }

  const clientId = validarClientId(request.data?.clientId);
  if (!clientId) {
    throw new HttpsError("invalid-argument", "Identificador de cliente inválido.");
  }

  const nomeEvento = request.data?.evento?.name;
  if (!EVENTOS_VALIDOS.has(nomeEvento)) {
    throw new HttpsError("invalid-argument", "Evento não suportado.");
  }

  const apiSecret = GA4_API_SECRET.value();
  if (!apiSecret) {
    // Pendência de configuração (secret ainda não criado) — nunca quebra
    // a navegação do usuário, só fica documentado no log.
    logger.error("GA4_API_SECRET não configurado — evento de analytics descartado", { nomeEvento });
    return { ok: false };
  }

  const payload = construirPayload({ clientId, nomeEvento, paramsEntrada: request.data?.evento?.params });

  try {
    const resposta = await fetch(
      `https://www.google-analytics.com/mp/collect?measurement_id=${GA4_MEASUREMENT_ID}&api_secret=${apiSecret}`,
      { method: "POST", body: JSON.stringify(payload) }
    );
    if (!resposta.ok) {
      logger.warn("GA4 Measurement Protocol retornou status não-OK", { status: resposta.status, nomeEvento });
      return { ok: false };
    }
  } catch (erro) {
    // Analytics é complementar — nunca pode propagar erro pro chamador.
    logger.warn("Falha ao enviar evento ao GA4", { nomeEvento, erro: String(erro) });
    return { ok: false };
  }

  logger.info("Evento de analytics enviado ao GA4", { nomeEvento });
  return { ok: true };
});
