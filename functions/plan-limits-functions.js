"use strict";

/**
 * Mantém contadores denormalizados no documento da academia, usados pelas
 * Firestore rules pra bloquear o plano gratuito nos limites de negócio
 * (1 turma ativa, 5 alunos ativos, 1 funcionário). Regras de segurança não
 * conseguem fazer uma query de contagem ao vivo — por isso o contador
 * precisa ser mantido aqui, a cada escrita relevante, e lido pela regra
 * como um campo comum do documento.
 *
 * Os três contadores:
 *   - turmas_ativas_contagem:   turmas com `ativo === true`
 *   - alunos_ativos_contagem:   usuarios com `perfil === 3 && ativo === true`
 *   - funcionarios_contagem:    total de documentos em `funcionarios`
 *     (exclusão é sempre hard-delete, então a própria existência do
 *     documento já representa "ativo")
 */

const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

const db = admin.firestore();

async function ajustarContador(academiaId, campo, delta) {
  if (delta === 0) return;
  try {
    await db
      .collection("academias")
      .doc(academiaId)
      .update({ [campo]: FieldValue.increment(delta) });
  } catch (e) {
    // Documento da academia pode já ter sido removido (exclusão de conta) —
    // não há contador pra ajustar nesse caso, só loga e segue.
    logger.warn(`ajustarContador: falha ao ajustar ${campo} para academia ${academiaId}`, {
      erro: e.message,
    });
  }
}

exports.manterContagemTurmasAtivas = onDocumentWritten(
  "academias/{academiaId}/turmas/{turmaId}",
  async (event) => {
    const antes = event.data.before.exists ? event.data.before.data().ativo === true : false;
    const depois = event.data.after.exists ? event.data.after.data().ativo === true : false;
    if (antes === depois) return;
    await ajustarContador(event.params.academiaId, "turmas_ativas_contagem", depois ? 1 : -1);
  },
);

exports.manterContagemAlunosAtivos = onDocumentWritten(
  "academias/{academiaId}/usuarios/{usuarioId}",
  async (event) => {
    const antesDados = event.data.before.exists ? event.data.before.data() : null;
    const depoisDados = event.data.after.exists ? event.data.after.data() : null;
    const antes = !!antesDados && antesDados.perfil === 3 && antesDados.ativo === true;
    const depois = !!depoisDados && depoisDados.perfil === 3 && depoisDados.ativo === true;
    if (antes === depois) return;
    await ajustarContador(event.params.academiaId, "alunos_ativos_contagem", depois ? 1 : -1);
  },
);

exports.manterContagemFuncionarios = onDocumentWritten(
  "academias/{academiaId}/funcionarios/{funcionarioId}",
  async (event) => {
    const antes = event.data.before.exists;
    const depois = event.data.after.exists;
    if (antes === depois) return;
    await ajustarContador(event.params.academiaId, "funcionarios_contagem", depois ? 1 : -1);
  },
);
