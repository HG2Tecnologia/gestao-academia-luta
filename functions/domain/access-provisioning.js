"use strict";

// Helpers puros para o provisionamento / redefinição de acesso ao app.
//
// Regra de ouro: um contato (aluno/responsável) pode entrar no app digitando
// o **telefone** OU o **e-mail** cadastrado. Cada conta do Firebase Auth só
// tem um e-mail, então:
//   - se há telefone, a conta usa o e-mail sintético `<E.164>@sensei.app` e o
//     login por e-mail real é resolvido depois (discoverAccessProfiles);
//   - se não há telefone, a conta usa o e-mail real.
// A redefinição de senha precisa cobrir **todas** as contas Auth alcançáveis
// por qualquer um desses identificadores, senão a pessoa troca a senha de uma
// "porta" e continua batendo na outra.

const { canonicalizePhone, canonicalPhoneDigits } = require("./phone-normalizer");
const { canonicalizeEmail, syntheticAuthEmails } = require("./account");

/**
 * Normaliza os identificadores de um documento de perfil (`usuarios` /
 * `funcionarios`) para o que interessa ao login.
 *
 * Retorna `{ realEmail, phoneCanonical, authEmails }` onde `authEmails` é a
 * lista (sem duplicatas, ordem estável) de e-mails de login do Firebase Auth
 * que aquele contato pode ter: e-mail real + `<E.164>@sensei.app` +
 * `<nacional>@sensei.app`.
 */
function loginIdentifiers(data = {}) {
  const realEmail = canonicalizeEmail(data.email);
  const phoneCanonical = canonicalizePhone(
    data.telefone_canonical || data.telefone || data.telefone_digits,
  );

  const authEmails = [];
  const push = (value) => {
    if (value && !authEmails.includes(value)) authEmails.push(value);
  };
  if (realEmail) push(realEmail);
  for (const synthetic of syntheticAuthEmails(phoneCanonical || "")) push(synthetic);

  return { realEmail, phoneCanonical, authEmails };
}

/**
 * E-mail de login "primário" para criar a conta Auth: prioriza o sintético de
 * telefone (rota mais comum e sem depender de caixa de e-mail real), cai para
 * o e-mail real quando não há telefone.
 */
function primaryLoginEmail({ realEmail, phoneCanonical }) {
  const digits = canonicalPhoneDigits(phoneCanonical || "");
  if (digits) return `${digits}@sensei.app`;
  return realEmail || null;
}

/**
 * A partir do e-mail de uma conta Auth já existente, devolve o identificador
 * (telefone canônico ou e-mail) que casa com ela — usado para alimentar o
 * `upsertAccount`, que valida `authEmailMatchesIdentifier`.
 */
function identityForAuthEmail(authEmail) {
  const email = canonicalizeEmail(authEmail);
  if (!email) return null;
  if (email.endsWith("@sensei.app")) {
    return canonicalizePhone(email.slice(0, -"@sensei.app".length));
  }
  return email;
}

/**
 * Texto curto dizendo COMO a pessoa deve entrar — mostrado para a academia
 * repassar ao aluno junto com a senha temporária.
 */
function loginHint({ realEmail, phoneCanonical }, rawTelefone) {
  if (phoneCanonical) return `telefone ${rawTelefone || phoneCanonical}`;
  if (realEmail) return `e-mail ${realEmail}`;
  return "telefone ou e-mail cadastrado";
}

/**
 * Decide o que fazer quando o provisionamento automático de acesso (criação
 * ou edição de aluno) encontra OUTRAS contas Auth já existentes para o mesmo
 * telefone/e-mail. Nunca entra em jogo para `motivo === 'redefinicao'` — um
 * clique explícito da academia em "Redefinir senha" sobre um perfil
 * específico já é uma decisão intencional, não um efeito colateral de cadastro.
 *
 * - `apenasVincular` / `confirmarSobrescrita`: a academia já escolheu o que
 *   fazer numa segunda chamada (depois do diálogo de conflito) — respeita.
 * - `algumJaDefiniuSenha`: alguma das contas encontradas já teve o primeiro
 *   acesso completo (a pessoa definiu a própria senha) — bloqueia e devolve
 *   pro cliente perguntar, em vez de sobrescrever essa senha sem avisar.
 * - Fora isso (ninguém ainda definiu senha própria), sobrescreve como sempre.
 */
function decidirAcaoContasCompartilhadas({
  motivo,
  confirmarSobrescrita = false,
  apenasVincular = false,
  algumJaDefiniuSenha = false,
}) {
  if (apenasVincular) return "vincular_sem_senha";
  if (motivo === "redefinicao" || confirmarSobrescrita) return "sobrescrever";
  if (algumJaDefiniuSenha) return "bloquear";
  return "sobrescrever";
}

module.exports = {
  loginIdentifiers,
  primaryLoginEmail,
  identityForAuthEmail,
  loginHint,
  decidirAcaoContasCompartilhadas,
};
