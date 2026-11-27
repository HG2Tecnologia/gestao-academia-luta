"use strict";

const { defineSecret } = require("firebase-functions/params");
const nodemailer = require("nodemailer");

// Conta Gmail/Workspace que envia os avisos internos (e também os recebe).
const REMETENTE = "admin@hg2tecnologia.com.br";
const DESTINO = "admin@hg2tecnologia.com.br";

// Senha de app do Google (não é a senha da conta). Gravada com:
//   firebase functions:secrets:set GMAIL_APP_PASSWORD
// Toda function que enviar e-mail precisa listar este secret em `secrets`.
const GMAIL_APP_PASSWORD = defineSecret("GMAIL_APP_PASSWORD");

function esc(valor) {
  return String(valor ?? "—")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

/** Envia um aviso interno da HG2 para a própria HG2. Lança em caso de falha. */
async function enviarAvisoInterno({ subject, text, html }) {
  const transporter = nodemailer.createTransport({
    host: "smtp.gmail.com",
    port: 465,
    secure: true,
    auth: { user: REMETENTE, pass: GMAIL_APP_PASSWORD.value() },
  });
  await transporter.sendMail({
    from: `Sensei <${REMETENTE}>`,
    to: DESTINO,
    subject,
    text,
    html,
  });
}

module.exports = { GMAIL_APP_PASSWORD, enviarAvisoInterno, esc };
