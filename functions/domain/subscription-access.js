"use strict";

// Regras puras (sem Firestore) sobre produtos, quem pode ativar uma assinatura,
// quando uma compra está "em uso" e qual assinatura vale para a academia.

const PRODUTOS_PRO = [
  "br.com.senseimanager.pro.mensal",
  "br.com.senseimanager.pro.trimestral",
  "br.com.senseimanager.pro.anual",
];
// Black Belt: tudo do PRO mais o sistema web.
const PRODUTOS_BLACK_BELT = [
  "br.com.senseimanager.black.mensal",
  "br.com.senseimanager.black.trimestral",
  "br.com.senseimanager.black.anual",
];
const PRODUTOS_VALIDOS = new Set([...PRODUTOS_PRO, ...PRODUTOS_BLACK_BELT]);

const liberaWeb = (productId) => PRODUTOS_BLACK_BELT.includes(productId);

// Toda a equipe: no app, além de Admin e Secretaria, o Professor também chega
// à tela de planos. Recusar quem já pagou seria pior que aceitar a equipe.
const PERFIS_QUE_ASSINAM = ["Admin", "Secretaria", "Professor"];

const ORIGENS_SEM_LOJA = new Set(["cortesia", "manual"]);

/** Mesmo critério de `possuiPerfilNaAcademia` nas regras do Firestore. */
function podeAtivarAssinatura(conta, academiaId) {
  if (!conta || !academiaId) return false;
  const perfilPrincipal = conta.academiaId === academiaId;
  const idsDeAcademia = Array.isArray(conta.academy_ids) ? conta.academy_ids : [];
  if (!perfilPrincipal && !idsDeAcademia.includes(academiaId)) return false;

  if (perfilPrincipal && PERFIS_QUE_ASSINAM.includes(conta.perfil)) return true;
  const papeis = conta.roles_by_academy?.[academiaId];
  return Array.isArray(papeis) && papeis.some((p) => PERFIS_QUE_ASSINAM.includes(p));
}

/**
 * A academia ainda usufrui da assinatura de loja gravada nela? Cortesia e
 * liberação manual não contam: o acesso delas não vem da compra.
 */
function usaAssinaturaDeLoja(academia, agora = Date.now()) {
  if (ORIGENS_SEM_LOJA.has(academia.plano_origem)) return false;
  if (!(academia.plano_tipo >= 1)) return false;
  if (academia.plano_status === "periodo_carencia") return true;
  const expiracao = academia.plano_expiracao;
  return !expiracao || Date.parse(expiracao) > agora;
}

/**
 * Uma ativação deve substituir o que está gravado na academia? Devolve o motivo
 * para ignorá-la, ou `null` para aplicar.
 *
 * - Mesma assinatura (Apple mantém o identificador nas trocas de plano): uma
 *   transação mais antiga que a gravada chega por restauração ou notificação
 *   atrasada e não pode desfazer a atual.
 * - Outra assinatura enquanto a atual segue ativa e renovando: não troca por um
 *   plano menor, nem por um de mesmo nível que vença antes. Se a atual foi
 *   cancelada, a nova vale, porque é ela que vai continuar sendo cobrada.
 * - Substituição declarada pela loja (`compraAnteriorId`) sempre vale, inclusive
 *   para um plano menor.
 */
function motivoParaIgnorar(atual, nova, agora = Date.now()) {
  const idAtual = atual.plano_original_transaction_id;
  if (!idAtual) return null;

  if (idAtual === nova.originalTransactionId) {
    const gravada = Date.parse(atual.plano_transacao_em);
    return nova.transacaoEmMs && gravada && nova.transacaoEmMs < gravada
      ? "transacao_antiga"
      : null;
  }

  if (idAtual === nova.compraAnteriorId) return null;
  if (!usaAssinaturaDeLoja(atual, agora)) return null;
  if (atual.plano_renovacao_automatica === false) return null;

  const webAtual = liberaWeb(atual.plano_produto_id);
  const webNova = liberaWeb(nova.productId);
  if (webAtual !== webNova) return webAtual ? "plano_menor" : null;
  return nova.expiresAtMs < Date.parse(atual.plano_expiracao) ? "vence_antes" : null;
}

/**
 * Item da assinatura do Google que vale agora. Numa troca agendada vêm dois: o
 * atual, ainda com validade, e o futuro, sem `expiryTime`. Depois da renovação o
 * antigo continua na lista, já vencido.
 */
function itemVigenteGoogle(lineItems = []) {
  return lineItems
    .filter((item) => item.expiryTime)
    .sort((a, b) => Date.parse(b.expiryTime) - Date.parse(a.expiryTime))[0];
}

module.exports = {
  PRODUTOS_VALIDOS,
  PRODUTOS_PRO,
  PRODUTOS_BLACK_BELT,
  liberaWeb,
  motivoParaIgnorar,
  itemVigenteGoogle,
  PERFIS_QUE_ASSINAM,
  ORIGENS_SEM_LOJA,
  podeAtivarAssinatura,
  usaAssinaturaDeLoja,
};
