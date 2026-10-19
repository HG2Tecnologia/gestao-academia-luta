"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { profileKey, removeProfileRef } = require("./domain/account");

const db = admin.firestore();
const auth = admin.auth();
const IDENTITY_FUNCTION_OPTIONS = {
  serviceAccount: "identity-functions@sensei-manager-d64c0.iam.gserviceaccount.com",
};

// Exclusão de aluno é um ato administrativo — igual exclusão de turma.
const DELETE_ROLES = new Set(["Admin", "Secretaria"]);

// Coleções que referenciam o aluno por `aluno_id` e podem ser hard-deletadas
// (Admin SDK ignora as Firestore Rules). `atestados` e `par_qs` ficam de
// fora de propósito: são registros de saúde/legais imutáveis por desenho
// (a própria regra do Firestore já bloqueia `delete` neles) — continuam
// existindo, órfãos por `aluno_id`, pelo mesmo motivo de responsabilidade
// civil que já os torna imutáveis hoje.
const COLECOES_POR_ALUNO_ID = [
  "matriculas",
  "pagamentos",
  "presencas",
  "graduacoes",
  "notificacoes",
  "conquistas_aluno",
  "contratos",
  "respostas_pesquisa",
  "planos_modalidade",
];

const BATCH_LIMIT = 400;

async function loadDeleterAuthority(callerUid, academiaId) {
  const accountSnap = await db.collection("usuariosFirebase").doc(callerUid).get();
  const account = accountSnap.data();
  if (!account) return null;

  const refs = Array.isArray(account.profile_refs) ? account.profile_refs : [];
  const staffRef = refs.find(
    (ref) => ref.academiaId === academiaId && DELETE_ROLES.has(ref.perfil_nome),
  );
  if (!staffRef) return null;
  return { usuarioId: staffRef.usuarioId, nome: staffRef.nome, perfil: staffRef.perfil_nome };
}

/** Apaga, em lotes de até `BATCH_LIMIT`, todos os docs de uma query. */
async function apagarQueryEmLotes(query) {
  const snap = await query.get();
  let apagados = 0;
  for (let i = 0; i < snap.docs.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    for (const doc of snap.docs.slice(i, i + BATCH_LIMIT)) {
      batch.delete(doc.ref);
      apagados++;
    }
    await batch.commit();
  }
  return apagados;
}

/**
 * Remove o aluno de `grupos_familiares.membros[]` e limpa `responsavel_id`.
 * `membros` guarda `{id, nome}` com nome variável, então `array-contains` não
 * serve pra achar o objeto exato — varre os grupos da academia (coleção
 * pequena, poucas dezenas de grupos por academia) e filtra em memória.
 */
async function limparGruposFamiliares(academiaId, alunoId) {
  const gruposRef = db.collection("academias").doc(academiaId).collection("grupos_familiares");
  const snap = await gruposRef.get();

  let tocados = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    const membros = Array.isArray(data.membros) ? data.membros : [];
    const eraMembro = membros.some((m) => m?.id === alunoId);
    const eraResponsavel = data.responsavel_id === alunoId;
    if (!eraMembro && !eraResponsavel) continue;

    const patch = {};
    if (eraMembro) patch.membros = membros.filter((m) => m?.id !== alunoId);
    if (eraResponsavel) patch.responsavel_id = null;
    await doc.ref.update(patch);
    tocados++;
  }
  return tocados;
}

/**
 * Remove só o `profile_ref` do aluno excluído da conta compartilhada
 * (`usuariosFirebase/{uid}`), preservando qualquer outro perfil (ex.: irmão
 * com o mesmo telefone/e-mail). Se a conta ficar sem nenhum perfil, apaga o
 * doc e o usuário do Firebase Auth.
 */
async function desvincularContaCompartilhada(academiaId, alunoId, aluno) {
  const uid = aluno.firebaseUid || aluno.firebase_uid;
  if (!uid) return { tocado: false };

  const accountRef = db.collection("usuariosFirebase").doc(uid);
  const accountSnap = await accountRef.get();
  if (!accountSnap.exists) return { tocado: false };

  const key = profileKey({ academiaId, colecao: "usuarios", usuarioId: alunoId });
  const resultado = removeProfileRef(accountSnap.data(), key);

  if (resultado.deleted) {
    await accountRef.delete();
    try {
      await auth.deleteUser(uid);
    } catch (error) {
      // Conta Auth já pode não existir mais (ex.: exclusão parcial anterior)
      // — não bloqueia a exclusão do aluno por isso.
      logger.warn("Falha ao apagar usuário do Firebase Auth", { uid, error: error.message });
    }
    return { tocado: true, contaApagada: true };
  }

  await accountRef.update(resultado.data);
  return { tocado: true, contaApagada: false };
}

exports.excluirAluno = onCall(IDENTITY_FUNCTION_OPTIONS, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "É necessário autenticar antes de excluir um aluno.");
  }

  const academiaId = String(request.data?.academiaId ?? "").trim();
  const alunoId = String(request.data?.alunoId ?? "").trim();
  if (!academiaId || !alunoId) {
    throw new HttpsError("invalid-argument", "Informe a academia e o aluno a excluir.");
  }

  const authority = await loadDeleterAuthority(request.auth.uid, academiaId);
  if (!authority) {
    throw new HttpsError("permission-denied", "Você não tem permissão para excluir alunos nesta academia.");
  }

  const alunoRef = db.collection("academias").doc(academiaId).collection("usuarios").doc(alunoId);
  const alunoSnap = await alunoRef.get();
  if (!alunoSnap.exists) {
    throw new HttpsError("not-found", "Aluno não encontrado.");
  }
  const aluno = alunoSnap.data();

  const totais = {};
  for (const colecao of COLECOES_POR_ALUNO_ID) {
    const query = db
      .collection("academias").doc(academiaId)
      .collection(colecao)
      .where("aluno_id", "==", alunoId);
    totais[colecao] = await apagarQueryEmLotes(query);
  }

  totais.grupos_familiares = await limparGruposFamiliares(academiaId, alunoId);

  const contaResultado = await desvincularContaCompartilhada(academiaId, alunoId, aluno);

  await db.collection("academias").doc(academiaId).collection("auditoria").doc().set({
    tipo: "exclusao_aluno",
    alvo: { alunoId, nome: aluno.nome || "" },
    registros_apagados: totais,
    conta_compartilhada: contaResultado,
    realizado_por: {
      uid: request.auth.uid,
      usuarioId: authority.usuarioId,
      nome: authority.nome,
      perfil: authority.perfil,
    },
    criado_em: FieldValue.serverTimestamp(),
  });

  await alunoRef.delete();

  logger.info("Aluno excluído (hard delete + cascata)", {
    academiaId,
    alunoId,
    realizadoPor: request.auth.uid,
    totais,
    contaResultado,
  });

  return { ok: true, registrosApagados: totais };
});

exports._test = {
  loadDeleterAuthority,
  desvincularContaCompartilhada,
};
