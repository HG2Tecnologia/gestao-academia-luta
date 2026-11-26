"use strict";

// Regras puras (sem Firestore) sobre quem pode ativar uma assinatura e quando
// uma compra está "em uso" por uma academia.

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

module.exports = {
  PERFIS_QUE_ASSINAM,
  ORIGENS_SEM_LOJA,
  podeAtivarAssinatura,
  usaAssinaturaDeLoja,
};
