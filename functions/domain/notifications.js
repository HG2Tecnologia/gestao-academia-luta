"use strict";

/**
 * Monta a mensagem da notificação de "esqueci minha senha" pra academia.
 * Quando o telefone/e-mail informado é compartilhado por mais de um aluno
 * (ex.: irmãos usando o telefone dos pais), agrupa todos numa única
 * notificação em vez de uma por aluno.
 */
function buildSolicitacaoSenhaMensagem(nomes) {
  const lista = nomes.map((n) => n || "Um aluno");
  if (lista.length === 1) {
    return `${lista[0]} pediu para redefinir a senha de acesso ao app.`;
  }
  const ultimosDoisJuntos = `${lista.slice(0, -1).join(", ")} e ${lista[lista.length - 1]}`;
  return `Os alunos ${ultimosDoisJuntos} pediram para redefinir a senha de acesso ao app.`;
}

module.exports = { buildSolicitacaoSenhaMensagem };
