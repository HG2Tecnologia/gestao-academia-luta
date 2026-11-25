"use strict";

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const { GMAIL_APP_PASSWORD, enviarAvisoInterno, esc } = require("./mailer");

function montarEmail(academiaId, academia) {
  const nome = academia.nome || "—";
  const email = academia.email || "—";
  const telefone = academia.telefone || "não informado";
  return {
    subject: `Nova academia no Sensei: ${nome}`,
    text:
      `Uma nova academia se cadastrou no Sensei.\n\n` +
      `Nome: ${nome}\nE-mail: ${email}\nTelefone: ${telefone}\n` +
      `ID: ${academiaId}\n`,
    html:
      `<p>Uma nova academia se cadastrou no Sensei.</p>` +
      `<ul><li><b>Nome:</b> ${esc(nome)}</li>` +
      `<li><b>E-mail:</b> ${esc(email)}</li>` +
      `<li><b>Telefone:</b> ${esc(telefone)}</li>` +
      `<li><b>ID:</b> ${esc(academiaId)}</li></ul>`,
  };
}

/**
 * Avisa a HG2 por e-mail quando uma academia se cadastra. Trigger no
 * documento `academias/{id}`, então vale para qualquer origem de cadastro
 * (app ou web). Falha de e-mail nunca derruba nem repete o cadastro.
 */
exports.avisarNovaAcademia = onDocumentCreated(
  { document: "academias/{academiaId}", secrets: [GMAIL_APP_PASSWORD] },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const academiaId = event.params.academiaId;
    try {
      await enviarAvisoInterno(montarEmail(academiaId, snap.data()));
      logger.info("Aviso de nova academia enviado", { academiaId });
    } catch (error) {
      logger.error("Falha ao enviar aviso de nova academia", {
        academiaId, motivo: error.message,
      });
    }
  },
);

exports._montarEmail = montarEmail;
