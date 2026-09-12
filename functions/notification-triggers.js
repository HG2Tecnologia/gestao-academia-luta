"use strict";

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

const db = admin.firestore();

/**
 * Dispara a notificação pessoal "você foi graduado" pro aluno assim que o
 * documento de graduação é criado — não importa se quem criou foi Admin,
 * Secretaria ou Professor (todos escrevem `graduacoes` direto do client hoje).
 * Trigger de Firestore, não `onCall`: não exige o passo de "permitir acesso
 * público" no Cloud Run que as functions HTTP (onCall) exigem.
 */
exports.onGraduacaoCriada = onDocumentCreated(
  "academias/{academiaId}/graduacoes/{graduacaoId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const graduacao = snap.data();
    const academiaId = event.params.academiaId;
    const alunoId = String(graduacao.aluno_id ?? "").trim();
    if (!alunoId) return;

    let faixaNome = "";
    const faixaId = String(graduacao.faixa_id ?? "").trim();
    if (faixaId) {
      try {
        const faixaSnap = await db
          .collection("academias").doc(academiaId)
          .collection("faixas").doc(faixaId)
          .get();
        faixaNome = faixaSnap.data()?.nome || "";
      } catch (error) {
        logger.warn("Não foi possível resolver o nome da faixa pra notificação", {
          academiaId, faixaId, motivo: error.message,
        });
      }
    }

    const mensagem = faixaNome
      ? `Você foi graduado para ${faixaNome}. Parabéns!`
      : "Você recebeu uma nova graduação. Parabéns!";

    await db
      .collection("academias").doc(academiaId)
      .collection("notificacoes").doc(`graduacao_${event.params.graduacaoId}`)
      .set({
        titulo: "Nova graduação",
        mensagem,
        tipo: "graduacao",
        aluno_id: alunoId,
        lida: false,
        criado_em: FieldValue.serverTimestamp(),
      });
  },
);
