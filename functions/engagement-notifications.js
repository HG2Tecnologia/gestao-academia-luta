const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { calcularEvasao, contarPresencasModalidadeDesde } = require("./domain/engagement");

const db = admin.firestore();
const messaging = admin.messaging();

function hojeISO() {
  return new Date().toISOString().split("T")[0];
}

async function processarAcademia(academiaId, academia) {
  const evasaoAtiva = academia.notif_evasao_ativo === true;
  const graduacaoAtiva = academia.notif_graduacao_ativo === true;
  if (!evasaoAtiva && !graduacaoAtiva) return { evasao: 0, graduacao: 0 };

  const academiaRef = db.collection("academias").doc(academiaId);

  const [alunosSnap, presencasSnap, funcionariosSnap] = await Promise.all([
    academiaRef
      .collection("usuarios")
      .where("perfil", "==", 3)
      .where("ativo", "==", true)
      .get(),
    academiaRef.collection("presencas").get(),
    academiaRef.collection("funcionarios").where("perfil", "in", ["Admin", "Secretaria"]).get(),
  ]);

  const alunos = alunosSnap.docs.map((d) => ({ id: d.id, ref: d.ref, ...d.data() }));
  const presencas = presencasSnap.docs.map((d) => d.data());

  const tokens = [];
  funcionariosSnap.forEach((f) => {
    const dataFunc = f.data();
    if (Array.isArray(dataFunc.fcm_tokens)) tokens.push(...dataFunc.fcm_tokens);
  });

  let totalEvasao = 0;
  let totalGraduacao = 0;
  const hojeStr = hojeISO();

  // ── Evasão ────────────────────────────────────────────────────────────────
  if (evasaoAtiva) {
    const emRisco = calcularEvasao(alunos, presencas);
    const emRiscoPorId = new Map(emRisco.map((r) => [r.alunoId, r]));
    const novosAlertas = [];

    for (const aluno of alunos) {
      const risco = emRiscoPorId.get(aluno.id);
      const nivelAnterior = aluno.evasao_nivel_alertado || null;

      if (!risco) {
        if (nivelAnterior) await aluno.ref.update({ evasao_nivel_alertado: admin.firestore.FieldValue.delete() });
        continue;
      }
      if (risco.nivel !== nivelAnterior) {
        novosAlertas.push(risco);
        await aluno.ref.update({ evasao_nivel_alertado: risco.nivel });
      }
    }

    if (novosAlertas.length > 0) {
      novosAlertas.sort((a, b) => b.dias - a.dias);
      totalEvasao = novosAlertas.length;
      const titulo = novosAlertas.length === 1
        ? "Aluno sumindo"
        : `${novosAlertas.length} alunos sumindo`;
      const nomes = novosAlertas.slice(0, 3).map((a) => `${a.nome} (${a.dias}d)`).join(", ");
      const mensagem = novosAlertas.length > 3
        ? `${nomes} e mais ${novosAlertas.length - 3}`
        : nomes;

      await academiaRef.collection("notificacoes").add({
        titulo,
        mensagem,
        tipo: "evasao",
        lida: false,
        chave_dedup: `evasao-${hojeStr}-${novosAlertas.map((a) => a.alunoId).join("-")}`,
        criado_em: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (tokens.length > 0) {
        try {
          await messaging.sendEachForMulticast({
            tokens,
            notification: { title: titulo, body: mensagem },
            data: { tipo: "evasao" },
          });
        } catch (err) {
          logger.error(`Erro ao enviar push de evasão para academia ${academiaId}`, err);
        }
      }
    }
  }

  // ── Próximo de graduar (por quantidade de presenças desde a última graduação) ──
  if (graduacaoAtiva) {
    const limiar = Number(academia.notif_graduacao_presencas_minimas) || 40;

    const [turmasSnap, graduacoesSnap, matriculasSnap] = await Promise.all([
      academiaRef.collection("turmas").get(),
      academiaRef.collection("graduacoes").get(),
      academiaRef.collection("matriculas").where("ativo", "==", true).get(),
    ]);

    const turmaParaModalidade = {};
    turmasSnap.forEach((t) => {
      const data = t.data();
      turmaParaModalidade[t.id] = (data.modalidadeId || data.modalidade_id || "").toString();
    });

    // última graduação por aluno+modalidade
    const ultimaGradPorAlunoModalidade = {};
    graduacoesSnap.forEach((g) => {
      const data = g.data();
      const aId = (data.aluno_id || "").toString();
      const mId = (data.modalidade_id || "").toString();
      if (!aId || !mId) return;
      const dt = new Date(`${(data.data_exame || "").toString().slice(0, 10)}T00:00:00`);
      if (isNaN(dt.getTime())) return;
      const key = `${aId}__${mId}`;
      const atual = ultimaGradPorAlunoModalidade[key];
      if (!atual || dt > atual.data) ultimaGradPorAlunoModalidade[key] = { data: dt, faixaId: (data.faixa_id || "").toString() };
    });

    // modalidades por aluno via matrículas ativas
    const modalidadesPorAluno = {};
    matriculasSnap.forEach((m) => {
      const data = m.data();
      const aId = (data.aluno_id || "").toString();
      const turmaId = (data.turma_id || "").toString();
      const mId = turmaParaModalidade[turmaId];
      if (!aId || !mId) return;
      modalidadesPorAluno[aId] = modalidadesPorAluno[aId] || new Set();
      modalidadesPorAluno[aId].add(mId);
    });

    const presencasPorAluno = {};
    for (const p of presencas) {
      const aId = (p.aluno_id || "").toString();
      if (!aId) continue;
      presencasPorAluno[aId] = presencasPorAluno[aId] || [];
      presencasPorAluno[aId].push(p);
    }

    const novosAptos = [];
    for (const aluno of alunos) {
      const modalidades = modalidadesPorAluno[aluno.id];
      if (!modalidades) continue;
      const presencasAluno = presencasPorAluno[aluno.id] || [];
      const alertadoPorModalidade = aluno.graduacao_alertado_faixa_por_modalidade || {};

      for (const modalidadeId of modalidades) {
        const ultimaGrad = ultimaGradPorAlunoModalidade[`${aluno.id}__${modalidadeId}`];
        const desde = ultimaGrad ? ultimaGrad.data : null;
        const faixaAtualId = ultimaGrad ? ultimaGrad.faixaId : "nunca_graduado";
        if (alertadoPorModalidade[modalidadeId] === faixaAtualId) continue; // já alertado nesse ciclo

        const total = contarPresencasModalidadeDesde(presencasAluno, turmaParaModalidade, modalidadeId, desde);
        if (total < limiar) continue;

        novosAptos.push({ alunoId: aluno.id, nome: aluno.nome || "", modalidadeId, faixaAtualId, presencas: total });
        await aluno.ref.update({
          [`graduacao_alertado_faixa_por_modalidade.${modalidadeId}`]: faixaAtualId,
        });
      }
    }

    if (novosAptos.length > 0) {
      totalGraduacao = novosAptos.length;
      const titulo = novosAptos.length === 1
        ? "Aluno próximo de graduar"
        : `${novosAptos.length} alunos próximos de graduar`;
      const nomes = [...new Set(novosAptos.map((a) => a.nome))].slice(0, 3).join(", ");
      const mensagem = novosAptos.length > 3 ? `${nomes} e mais` : nomes;

      await academiaRef.collection("notificacoes").add({
        titulo,
        mensagem,
        tipo: "graduacao_proxima",
        lida: false,
        chave_dedup: `graduacao-${hojeStr}-${novosAptos.map((a) => `${a.alunoId}-${a.modalidadeId}`).join("-")}`,
        criado_em: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (tokens.length > 0) {
        try {
          await messaging.sendEachForMulticast({
            tokens,
            notification: { title: titulo, body: mensagem },
            data: { tipo: "graduacao_proxima" },
          });
        } catch (err) {
          logger.error(`Erro ao enviar push de graduação para academia ${academiaId}`, err);
        }
      }
    }
  }

  return { evasao: totalEvasao, graduacao: totalGraduacao };
}

async function processarAlertasEngajamento() {
  const academiasSnap = await db.collection("academias").get();
  let totalEvasao = 0;
  let totalGraduacao = 0;

  for (const academiaDoc of academiasSnap.docs) {
    try {
      const resultado = await processarAcademia(academiaDoc.id, academiaDoc.data());
      totalEvasao += resultado.evasao;
      totalGraduacao += resultado.graduacao;
    } catch (err) {
      logger.error(`Erro ao processar alertas de engajamento da academia ${academiaDoc.id}`, err);
    }
  }

  logger.info(`Alertas de engajamento processados: ${totalEvasao} evasão, ${totalGraduacao} graduação.`);
  return { totalEvasao, totalGraduacao };
}

// Roda todo dia às 09:00 (horário de Brasília) — depois do alerta de contas (08:00).
const checarAlertasEngajamento = onSchedule(
  { schedule: "0 9 * * *", timeZone: "America/Sao_Paulo" },
  async () => {
    await processarAlertasEngajamento();
  },
);

// Endpoint HTTP para disparar manualmente durante testes (sem esperar o cron).
const testarAlertasEngajamento = onRequest(async (req, res) => {
  const resultado = await processarAlertasEngajamento();
  res.status(200).json(resultado);
});

module.exports = {
  checarAlertasEngajamento,
  testarAlertasEngajamento,
  processarAlertasEngajamento,
  processarAcademia,
};
