"use strict";

const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

const db = admin.firestore();

/**
 * Endpoints públicos (sem Firebase Auth) pra assinatura de contrato via
 * link enviado por WhatsApp/e-mail — o CRM não tem login de aluno, então
 * o responsável assina só com o token da URL, sem conta nenhuma. Usa
 * `onCall` (não `onRequest`) só pra reaproveitar o mesmo transporte/CORS
 * que o resto das Cloud Functions já usa; `request.auth` fica
 * null aqui de propósito, não é checado.
 *
 * Collection `contratos` existe no Firestore do mobile (código morto,
 * nunca teve UI lá) — reaproveitamos o esqueleto de campos
 * (`aluno_id`, `status` numérico, `data_assinatura`), mas a convenção
 * de `status` (1=Pendente/2=Assinado/3=Cancelado) segue o que já
 * estava codificado nas telas Angular existentes (badges, filtros),
 * não o comentário isolado do mobile (que só confirmava "1=Assinado"
 * numa função nunca chamada).
 */

async function buscarContratoPorToken(token) {
  const snap = await db.collectionGroup("contratos").where("token_publico", "==", token).limit(1).get();
  if (snap.empty) return null;
  return snap.docs[0];
}

exports.contratoPublicoObter = onCall(async (request) => {
  const token = request.data?.token;
  if (!token) return { sucesso: false, mensagem: "Token inválido." };

  const doc = await buscarContratoPorToken(token);
  if (!doc) return { sucesso: false, mensagem: "Contrato não encontrado ou link inválido." };

  const c = doc.data();
  const academiaId = doc.ref.parent.parent.id;
  const academiaSnap = await db.collection("academias").doc(academiaId).get();
  const academia = academiaSnap.data() ?? {};

  return {
    sucesso: true,
    dados: {
      id: doc.id,
      nomeAluno: c.nome_aluno ?? "",
      nomeAcademia: academia.nome ?? "",
      logoUrl: academia.logoUrl ?? undefined,
      conteudoHtml: c.conteudo_html ?? "",
      status: c.status ?? 1,
      dataAssinatura: c.data_assinatura?.toDate?.()?.toISOString?.() ?? undefined,
      nomeAssinou: c.nome_assinou ?? undefined,
    },
  };
});

exports.contratoPublicoAssinar = onCall(async (request) => {
  const token = request.data?.token;
  const nomeCompleto = request.data?.nomeCompleto;
  if (!token || !nomeCompleto?.trim()) {
    return { sucesso: false, mensagem: "Informe seu nome completo." };
  }

  const doc = await buscarContratoPorToken(token);
  if (!doc) return { sucesso: false, mensagem: "Contrato não encontrado ou link inválido." };

  const c = doc.data();
  if (c.status === 2) return { sucesso: false, mensagem: "Este contrato já foi assinado." };
  if (c.status === 3) return { sucesso: false, mensagem: "Este contrato foi cancelado." };

  await doc.ref.update({
    status: 2,
    nome_assinou: nomeCompleto.trim(),
    data_assinatura: FieldValue.serverTimestamp(),
    ip_assinatura: request.rawRequest?.ip ?? null,
  });

  return { sucesso: true, dados: { id: doc.id } };
});
