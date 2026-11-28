"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { GMAIL_APP_PASSWORD, enviarAvisoInterno, esc } = require("./mailer");

const db = admin.firestore();

const PAPEIS = new Set(["academia", "professor", "aluno"]);

/**
 * Descobre, no servidor (nunca confiando no app), quem enviou o feedback e de
 * qual academia: perfil da pessoa + nome/telefone da academia. Falha aqui não
 * impede o feedback de ser gravado — só fica sem esses campos.
 */
async function buscarContato(uid) {
  const contato = {};
  try {
    const conta = (await db.collection("usuariosFirebase").doc(uid).get()).data() || {};
    const academiaId = conta.academiaId || null;
    const usuarioId = conta.usuarioId || null;
    const colecao = conta.colecao || "usuarios";
    contato.academiaId = academiaId;
    contato.usuarioId = usuarioId;
    contato.usuarioNome = conta.nome || "";
    contato.usuarioEmail = conta.email || "";

    if (academiaId) {
      const [academiaSnap, usuarioSnap] = await Promise.all([
        db.collection("academias").doc(academiaId).get(),
        usuarioId
          ? db.collection("academias").doc(academiaId).collection(colecao).doc(usuarioId).get()
          : Promise.resolve(null),
      ]);
      const academia = academiaSnap.data() || {};
      contato.academiaNome = academia.nome || "";
      contato.academiaTelefone = academia.telefone || "";
      contato.academiaEmail = academia.email || "";
      const usuario = usuarioSnap && usuarioSnap.exists ? usuarioSnap.data() || {} : {};
      contato.usuarioTelefone = usuario.telefone || "";
      if (usuario.nome) contato.usuarioNome = usuario.nome;
      if (usuario.email) contato.usuarioEmail = usuario.email;
    }
  } catch (error) {
    logger.warn("Não foi possível resolver o contato do feedback", {
      uid, motivo: error.message,
    });
  }
  return contato;
}

function montarEmailFeedback(f) {
  const v = (valor) => valor || "não informado";
  const linhas = [
    ["Papel", f.papel],
    ["Academia", f.academiaNome],
    ["Telefone da academia", f.academiaTelefone],
    ["E-mail da academia", f.academiaEmail],
    ["ID da academia", f.academiaId],
    ["Pessoa", f.usuarioNome],
    ["Telefone da pessoa", f.usuarioTelefone],
    ["E-mail da pessoa", f.usuarioEmail],
    ["Versão do app", f.versao],
    ["Plataforma", f.plataforma],
  ];
  return {
    subject: `Feedback no Sensei: ${v(f.academiaNome)} (${f.papel})`,
    text:
      `Novo feedback de quem não quis avaliar o app.\n\n` +
      linhas.map(([k, val]) => `${k}: ${v(val)}`).join("\n") +
      `\n\nMensagem:\n${f.mensagem}\n`,
    html:
      `<p>Novo feedback de quem não quis avaliar o app.</p><ul>` +
      linhas.map(([k, val]) => `<li><b>${k}:</b> ${esc(v(val))}</li>`).join("") +
      `</ul><p><b>Mensagem:</b></p>` +
      `<blockquote style="white-space:pre-wrap">${esc(f.mensagem)}</blockquote>`,
  };
}

/**
 * Recebe o feedback de quem NÃO quis avaliar o app na loja (resposta "Não" no
 * pedido de avaliação), guarda em `app_feedback` e avisa a equipe por e-mail.
 */
exports.registrarFeedbackApp = onCall(
  { region: "us-central1", secrets: [GMAIL_APP_PASSWORD] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Login necessário.");

    const data = request.data || {};
    const mensagem = String(data.mensagem || "").trim().slice(0, 2000);
    if (mensagem.length < 3) {
      throw new HttpsError("invalid-argument", "Mensagem muito curta.");
    }
    const papel = PAPEIS.has(data.papel) ? data.papel : "desconhecido";

    const feedback = {
      uid,
      papel,
      ...(await buscarContato(uid)),
      mensagem,
      versao: String(data.versao || "").slice(0, 40),
      plataforma: String(data.plataforma || "").slice(0, 20),
    };

    await db.collection("app_feedback").add({
      ...feedback,
      criadoEm: FieldValue.serverTimestamp(),
    });

    // E-mail é complementar: o feedback já está salvo, então uma falha de
    // envio só vai para o log e nunca devolve erro ao usuário.
    try {
      await enviarAvisoInterno(montarEmailFeedback(feedback));
    } catch (error) {
      logger.error("Falha ao enviar e-mail de feedback", { uid, motivo: error.message });
    }

    logger.info("app_feedback registrado", { uid, papel });
    return { ok: true };
  },
);

exports._montarEmailFeedback = montarEmailFeedback;
