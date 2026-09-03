const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const accountFunctions = require("./account-functions");
exports.discoverAccessProfiles = accountFunctions.discoverAccessProfiles;
exports.activateAccessAccount = accountFunctions.activateAccessAccount;
exports.refreshAccessAccount = accountFunctions.refreshAccessAccount;

const adminFunctions = require("./admin-functions");
exports.adminResetPassword = adminFunctions.adminResetPassword;
exports.completeMandatoryPasswordChange = adminFunctions.completeMandatoryPasswordChange;

const graduacaoFunctions = require("./graduacao-functions");
exports.editarGraduacao = graduacaoFunctions.editarGraduacao;

const turmaFunctions = require("./turma-functions");
exports.arquivarTurma = turmaFunctions.arquivarTurma;

const financeFunctions = require("./finance-functions");
exports.ensureChargesForPeriod = financeFunctions.ensureChargesForPeriod;
exports.gerarMensalidadesAutomaticas = financeFunctions.gerarMensalidadesAutomaticas;

const DIAS_ANTECEDENCIA = 3;

function hojeISO() {
  return new Date().toISOString().split("T")[0];
}

/**
 * Varre todas as academias, procura contas da academia (água, luz, aluguel etc.)
 * pendentes com vencimento em até DIAS_ANTECEDENCIA dias (ou já vencidas), cria
 * uma notificação in-app e dispara push para quem pode ver o financeiro
 * (Admin/Secretaria) daquela academia. Idempotente: usa `alerta_enviado_em`
 * para não notificar a mesma conta duas vezes no mesmo dia.
 */
async function processarVencimentosContasAcademia() {
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);
  const limite = new Date(hoje);
  limite.setDate(limite.getDate() + DIAS_ANTECEDENCIA);
  const hojeStr = hojeISO();

  const academiasSnap = await db.collection("academias").get();
  let totalAlertas = 0;

  for (const academiaDoc of academiasSnap.docs) {
    const academiaId = academiaDoc.id;

    const contasSnap = await db
      .collection("academias").doc(academiaId)
      .collection("contas_academia")
      .where("status", "==", "pendente")
      .get();

    const contasParaAlertar = contasSnap.docs.filter((doc) => {
      const c = doc.data();
      if (c.alerta_enviado_em === hojeStr) return false;
      if (!c.data_vencimento) return false;
      const venc = new Date(`${c.data_vencimento}T00:00:00`);
      return venc <= limite;
    });

    if (contasParaAlertar.length === 0) continue;

    // Busca funcionários com acesso ao financeiro (Admin/Secretaria) e seus tokens FCM.
    const funcionariosSnap = await db
      .collection("academias").doc(academiaId)
      .collection("funcionarios")
      .where("perfil", "in", ["Admin", "Secretaria"])
      .get();

    const tokens = [];
    funcionariosSnap.forEach((f) => {
      const dataFunc = f.data();
      if (Array.isArray(dataFunc.fcm_tokens)) tokens.push(...dataFunc.fcm_tokens);
    });

    for (const contaDoc of contasParaAlertar) {
      const conta = contaDoc.data();
      const venc = new Date(`${conta.data_vencimento}T00:00:00`);
      const vencida = venc < hoje;
      const titulo = vencida ? "Conta da academia vencida" : "Conta da academia vencendo";
      const mensagem = `${conta.descricao || "Conta"} (${conta.categoria || "Outros"}) - vencimento ${conta.data_vencimento}`;

      await db.collection("academias").doc(academiaId).collection("notificacoes").add({
        titulo,
        mensagem,
        tipo: vencida ? "alerta" : "info",
        lida: false,
        chave_dedup: `conta-academia-${contaDoc.id}-${hojeStr}`,
        criado_em: admin.firestore.FieldValue.serverTimestamp(),
      });

      await contaDoc.ref.update({ alerta_enviado_em: hojeStr });
      totalAlertas++;

      if (tokens.length > 0) {
        try {
          await messaging.sendEachForMulticast({
            tokens,
            notification: { title: titulo, body: mensagem },
            data: { tipo: "conta_academia", contaId: contaDoc.id },
          });
        } catch (err) {
          logger.error(`Erro ao enviar push para academia ${academiaId}`, err);
        }
      }
    }
  }

  logger.info(`Vencimentos de contas da academia processados: ${totalAlertas} alerta(s) gerado(s).`);
  return totalAlertas;
}

// Roda todo dia às 08:00 (horário de Brasília).
exports.checarVencimentosContasAcademia = onSchedule(
  { schedule: "0 8 * * *", timeZone: "America/Sao_Paulo" },
  async () => {
    await processarVencimentosContasAcademia();
  },
);

// Endpoint HTTP para disparar manualmente durante testes (sem esperar o cron).
// Ex.: curl -X POST https://<region>-<project>.cloudfunctions.net/testarVencimentosContasAcademia
exports.testarVencimentosContasAcademia = onRequest(async (req, res) => {
  const total = await processarVencimentosContasAcademia();
  res.status(200).json({ alertasGerados: total });
});
