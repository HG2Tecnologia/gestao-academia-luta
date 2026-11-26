"use strict";

// Cenários de assinatura para simulação local. Só monta os dados — quem grava
// (sempre no emulador) é `cenario-assinatura.js`.
//
// Os campos seguem o que `processarAtivacaoAssinatura` grava hoje em
// iap-functions.js, mais `acesso_web` (plano Black Belt).

const DIA_MS = 24 * 60 * 60 * 1000;

const PRODUTO_PRO = "br.com.senseimanager.pro.mensal";
const PRODUTO_BLACK = "br.com.senseimanager.black.mensal";

// Tudo que um cenário não define é apagado do documento, para não sobrar
// estado do cenário anterior.
const CAMPOS_DE_ASSINATURA = [
  "plano_status",
  "plano_origem",
  "plano_renovacao_automatica",
  "plano_expiracao",
  "plano_produto_id",
  "plano_plataforma",
  "plano_ambiente",
  "plano_transaction_id",
  "plano_original_transaction_id",
  "plano_assinado_em",
  "plano_transacao_em",
  "web_cortesia_ate",
];

function emDias(agora, dias) {
  return new Date(agora.getTime() + dias * DIA_MS);
}

function semAssinatura(agora, idadeDias) {
  return { criado_em: emDias(agora, -idadeDias), plano_tipo: 0, acesso_web: false };
}

function assinaturaDeLoja(agora, plataforma, { black, status, expiraEmDias, renova, pago }) {
  return {
    criado_em: emDias(agora, -90),
    plano_tipo: pago ? 1 : 0,
    acesso_web: pago && black,
    plano_status: status,
    plano_origem: "loja",
    plano_renovacao_automatica: renova,
    plano_expiracao: emDias(agora, expiraEmDias).toISOString(),
    plano_produto_id: black ? PRODUTO_BLACK : PRODUTO_PRO,
    plano_plataforma: plataforma,
    plano_ambiente: "sandbox",
    plano_transaction_id: "simulacao-transacao",
    plano_original_transaction_id: "simulacao-assinatura",
    plano_assinado_em: emDias(agora, -60).toISOString(),
  };
}

const ativa = { status: "ativo", expiraEmDias: 30, renova: true, pago: true };
const cancelada = { status: "cancelado_ate_expirar", expiraEmDias: 10, renova: false, pago: true };
// Em carência a data já passou, mas a loja ainda considera o assinante ativo.
const emCarencia = { status: "periodo_carencia", expiraEmDias: -1, renova: true, pago: true };
const encerrada = (status) => ({ status, expiraEmDias: -5, renova: false, pago: false });

const CENARIOS = {
  gratis: {
    descricao: "Grátis, teste de 30 dias já encerrado",
    montar: (agora) => semAssinatura(agora, 60),
  },
  teste: {
    descricao: "Primeiro dia do teste de 30 dias",
    montar: (agora) => semAssinatura(agora, 0),
  },
  "teste-acabando": {
    descricao: "Teste de 30 dias faltando 3 dias",
    montar: (agora) => semAssinatura(agora, 27),
  },
  pro: {
    descricao: "Sensei PRO ativo (sem web)",
    montar: (agora, p) => assinaturaDeLoja(agora, p, { ...ativa, black: false }),
  },
  black: {
    descricao: "Black Belt ativo (app + web)",
    montar: (agora, p) => assinaturaDeLoja(agora, p, { ...ativa, black: true }),
  },
  "pro-cancelado": {
    descricao: "PRO cancelado, ainda dentro do período pago",
    montar: (agora, p) => assinaturaDeLoja(agora, p, { ...cancelada, black: false }),
  },
  "black-cancelado": {
    descricao: "Black Belt cancelado, ainda dentro do período pago",
    montar: (agora, p) => assinaturaDeLoja(agora, p, { ...cancelada, black: true }),
  },
  "pro-carencia": {
    descricao: "PRO com falha de cobrança, em carência",
    montar: (agora, p) => assinaturaDeLoja(agora, p, { ...emCarencia, black: false }),
  },
  "black-carencia": {
    descricao: "Black Belt com falha de cobrança, em carência",
    montar: (agora, p) => assinaturaDeLoja(agora, p, { ...emCarencia, black: true }),
  },
  expirado: {
    descricao: "Black Belt expirado",
    montar: (agora, p) =>
      assinaturaDeLoja(agora, p, { ...encerrada("expirado"), black: true }),
  },
  suspenso: {
    descricao: "Black Belt suspenso por falta de pagamento (Google)",
    montar: (agora) =>
      assinaturaDeLoja(agora, "android", { ...encerrada("suspenso"), black: true }),
  },
  reembolsado: {
    descricao: "Black Belt reembolsado",
    montar: (agora, p) =>
      assinaturaDeLoja(agora, p, { ...encerrada("reembolsado"), black: true }),
  },
  "cortesia-web": {
    descricao: "Grátis com o web liberado manualmente por 6 meses",
    montar: (agora) => ({
      ...semAssinatura(agora, 90),
      web_cortesia_ate: emDias(agora, 180),
    }),
  },
  cortesia: {
    descricao: "PRO de cortesia por 30 dias, sem loja",
    montar: (agora) => ({
      criado_em: emDias(agora, -90),
      plano_tipo: 1,
      acesso_web: false,
      plano_status: "ativo",
      plano_origem: "cortesia",
      plano_expiracao: emDias(agora, 30).toISOString(),
    }),
  },
};

/**
 * Devolve `{ descricao, campos, remover }` do cenário: `campos` é o que gravar
 * em `academias/{id}` e `remover` o que apagar.
 */
function montarCenario(nome, { plataforma = "ios", agora = new Date() } = {}) {
  if (!Object.hasOwn(CENARIOS, nome)) {
    throw new Error(`Cenário desconhecido: ${nome}`);
  }
  if (plataforma !== "ios" && plataforma !== "android") {
    throw new Error(`Plataforma inválida: ${plataforma} (use ios ou android)`);
  }
  const { descricao, montar } = CENARIOS[nome];
  const campos = montar(agora, plataforma);
  const remover = CAMPOS_DE_ASSINATURA.filter((c) => !(c in campos));
  return { descricao, campos, remover };
}

module.exports = { CENARIOS, CAMPOS_DE_ASSINATURA, montarCenario };
