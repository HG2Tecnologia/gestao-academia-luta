"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

const db = admin.firestore();

/**
 * Espelho de `frontend-web/.../academia-seeds.ts` e
 * `mobile/.../academia_seeds.dart` — MESMOS nomes/cores/faixas. A única
 * coisa nova aqui é `chave`: um identificador interno, nunca mostrado ao
 * usuário, que existe só pra esta function conseguir gerar IDs
 * determinísticos e marcar documentos já vinculados. Academias antigas
 * (criadas pelo mobile, com IDs aleatórios em `addDoc`) não têm esse
 * campo — por isso a lógica abaixo nunca depende dele sozinho pra
 * encontrar equivalência, só pra marcar o que ela mesma já resolveu.
 */
const MODALIDADES_PADRAO = [
  {
    chave: "jiu_jitsu_adulto",
    nome: "Jiu-Jitsu Adulto",
    cor: "#1565C0",
    faixas: [
      { nome: "Branca", cor: "#F5F5F5", ordem: 1, tem_graus: true, max_graus: 4 },
      { nome: "Azul", cor: "#1565C0", ordem: 2, tem_graus: true, max_graus: 4 },
      { nome: "Roxa", cor: "#7B1FA2", ordem: 3, tem_graus: true, max_graus: 4 },
      { nome: "Marrom", cor: "#5D4037", ordem: 4, tem_graus: true, max_graus: 4 },
      { nome: "Preta", cor: "#212121", ordem: 5, tem_graus: true, max_graus: 6 },
    ],
  },
  {
    chave: "jiu_jitsu_infantil",
    nome: "Jiu-Jitsu Infantil",
    cor: "#2E7D32",
    faixas: [
      { nome: "Branca", cor: "#F5F5F5", ordem: 1, tem_graus: true, max_graus: 4 },
      { nome: "Cinza/Branca", cor: "#90A4AE", ordem: 2, tem_graus: true, max_graus: 4 },
      { nome: "Cinza", cor: "#607D8B", ordem: 3, tem_graus: true, max_graus: 4 },
      { nome: "Cinza/Preta", cor: "#455A64", ordem: 4, tem_graus: true, max_graus: 4 },
      { nome: "Amarela/Branca", cor: "#FDD835", ordem: 5, tem_graus: true, max_graus: 4 },
      { nome: "Amarela", cor: "#F9A825", ordem: 6, tem_graus: true, max_graus: 4 },
      { nome: "Amarela/Preta", cor: "#F57F17", ordem: 7, tem_graus: true, max_graus: 4 },
      { nome: "Laranja/Branca", cor: "#FF8A65", ordem: 8, tem_graus: true, max_graus: 4 },
      { nome: "Laranja", cor: "#F4511E", ordem: 9, tem_graus: true, max_graus: 4 },
      { nome: "Laranja/Preta", cor: "#E64A19", ordem: 10, tem_graus: true, max_graus: 4 },
      { nome: "Verde/Branca", cor: "#66BB6A", ordem: 11, tem_graus: true, max_graus: 4 },
      { nome: "Verde", cor: "#388E3C", ordem: 12, tem_graus: true, max_graus: 4 },
      { nome: "Verde/Preta", cor: "#1B5E20", ordem: 13, tem_graus: true, max_graus: 4 },
    ],
  },
  {
    chave: "muay_thai",
    nome: "Muay Thai",
    cor: "#C62828",
    faixas: [
      { nome: "Branca", cor: "#F5F5F5", ordem: 1, tem_graus: false, max_graus: 0 },
      { nome: "Amarela", cor: "#F9A825", ordem: 2, tem_graus: false, max_graus: 0 },
      { nome: "Laranja", cor: "#F4511E", ordem: 3, tem_graus: false, max_graus: 0 },
      { nome: "Verde", cor: "#388E3C", ordem: 4, tem_graus: false, max_graus: 0 },
      { nome: "Azul", cor: "#1565C0", ordem: 5, tem_graus: false, max_graus: 0 },
      { nome: "Vermelha", cor: "#C62828", ordem: 6, tem_graus: false, max_graus: 0 },
      { nome: "Marrom", cor: "#5D4037", ordem: 7, tem_graus: false, max_graus: 0 },
      { nome: "Preta", cor: "#212121", ordem: 8, tem_graus: false, max_graus: 0 },
    ],
  },
  {
    chave: "karate",
    nome: "Karatê",
    cor: "#E65100",
    faixas: [
      { nome: "Branca", cor: "#F5F5F5", ordem: 1, tem_graus: false, max_graus: 0 },
      { nome: "Amarela", cor: "#F9A825", ordem: 2, tem_graus: false, max_graus: 0 },
      { nome: "Laranja", cor: "#F4511E", ordem: 3, tem_graus: false, max_graus: 0 },
      { nome: "Verde", cor: "#388E3C", ordem: 4, tem_graus: false, max_graus: 0 },
      { nome: "Azul", cor: "#1565C0", ordem: 5, tem_graus: false, max_graus: 0 },
      { nome: "Vermelha", cor: "#C62828", ordem: 6, tem_graus: false, max_graus: 0 },
      { nome: "Marrom", cor: "#5D4037", ordem: 7, tem_graus: false, max_graus: 0 },
      { nome: "Preta", cor: "#212121", ordem: 8, tem_graus: false, max_graus: 0 },
    ],
  },
  {
    chave: "judo",
    nome: "Judô",
    cor: "#4A148C",
    faixas: [
      { nome: "Branca", cor: "#F5F5F5", ordem: 1, tem_graus: false, max_graus: 0 },
      { nome: "Amarela", cor: "#F9A825", ordem: 2, tem_graus: false, max_graus: 0 },
      { nome: "Laranja", cor: "#F4511E", ordem: 3, tem_graus: false, max_graus: 0 },
      { nome: "Verde", cor: "#388E3C", ordem: 4, tem_graus: false, max_graus: 0 },
      { nome: "Azul", cor: "#1565C0", ordem: 5, tem_graus: false, max_graus: 0 },
      { nome: "Marrom", cor: "#5D4037", ordem: 6, tem_graus: false, max_graus: 0 },
      { nome: "Preta", cor: "#212121", ordem: 7, tem_graus: false, max_graus: 0 },
    ],
  },
  {
    chave: "boxe",
    nome: "Boxe",
    cor: "#B71C1C",
    faixas: [
      { nome: "Iniciante", cor: "#90CAF9", ordem: 1, tem_graus: false, max_graus: 0 },
      { nome: "Intermediário", cor: "#42A5F5", ordem: 2, tem_graus: false, max_graus: 0 },
      { nome: "Avançado", cor: "#1565C0", ordem: 3, tem_graus: false, max_graus: 0 },
    ],
  },
  {
    chave: "kickboxing",
    nome: "Kickboxing",
    cor: "#880E4F",
    faixas: [
      { nome: "Branca", cor: "#F5F5F5", ordem: 1, tem_graus: false, max_graus: 0 },
      { nome: "Amarela", cor: "#F9A825", ordem: 2, tem_graus: false, max_graus: 0 },
      { nome: "Laranja", cor: "#F4511E", ordem: 3, tem_graus: false, max_graus: 0 },
      { nome: "Verde", cor: "#388E3C", ordem: 4, tem_graus: false, max_graus: 0 },
      { nome: "Azul", cor: "#1565C0", ordem: 5, tem_graus: false, max_graus: 0 },
      { nome: "Vermelha", cor: "#C62828", ordem: 6, tem_graus: false, max_graus: 0 },
      { nome: "Preta", cor: "#212121", ordem: 7, tem_graus: false, max_graus: 0 },
    ],
  },
  {
    chave: "mma",
    nome: "MMA",
    cor: "#37474F",
    faixas: [
      { nome: "Iniciante", cor: "#90CAF9", ordem: 1, tem_graus: false, max_graus: 0 },
      { nome: "Intermediário", cor: "#42A5F5", ordem: 2, tem_graus: false, max_graus: 0 },
      { nome: "Avançado", cor: "#1565C0", ordem: 3, tem_graus: false, max_graus: 0 },
    ],
  },
];

function normalizarTexto(valor) {
  return String(valor ?? "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .trim()
    .replace(/\s+/g, " ");
}

/**
 * Resolve UMA modalidade padrão contra o que já existe na academia — sem
 * nunca depender só do nome exibido (que pode ter sido personalizado).
 * Ordem de verificação, da mais barata/segura pra mais arriscada:
 *   1. Doc com o ID determinístico já existe → é nossa, pronto.
 *   2. Algum doc já foi marcado com `chave_padrao` igual (de uma execução
 *      anterior desta mesma function, possivelmente com ID aleatório
 *      antigo) → é nossa, pronto.
 *   3. Heurística: nome normalizado (sem acento/maiúscula) E cor batem
 *      EXATAMENTE com exatamente UM doc ainda não marcado → provável
 *      equivalente legado (ex.: academia criada pelo mobile antes desta
 *      function existir). Marca com `chave_padrao`, sem alterar mais nada
 *      — não renomeia, não recolore, não mexe em faixas existentes dele.
 *   4. Ambíguo (0 ou 2+ candidatos) ou já existe conteúdo claramente
 *      diferente → NUNCA cria duplicata, NUNCA vincula advinhando.
 *      Registra como pendência pra revisão manual.
 */
async function resolverModalidade(academiaId, def, existentesSnap) {
  const detRef = db.doc(`academias/${academiaId}/modalidades/${def.chave}`);
  const detSnap = await detRef.get();
  if (detSnap.exists) {
    return { id: def.chave, status: "ja_existia_deterministico" };
  }

  const docsExistentes = existentesSnap.docs;
  const jaMarcado = docsExistentes.find((d) => d.data().chave_padrao === def.chave);
  if (jaMarcado) {
    return { id: jaMarcado.id, status: "ja_vinculada" };
  }

  const naoVinculados = docsExistentes.filter((d) => !d.data().chave_padrao);
  const nomeAlvo = normalizarTexto(def.nome);
  const candidatosFortes = naoVinculados.filter((d) => {
    const data = d.data();
    return normalizarTexto(data.nome) === nomeAlvo && data.cor === def.cor;
  });

  if (candidatosFortes.length === 1) {
    // Nome normalizado E cor batendo exatamente — confiança alta o
    // suficiente pra vincular automaticamente.
    const alvo = candidatosFortes[0];
    await alvo.ref.update({ chave_padrao: def.chave });
    return { id: alvo.id, status: "vinculada_por_heuristica" };
  }

  if (candidatosFortes.length > 1) {
    return { status: "pendente", motivo: "multiplos_candidatos_ambiguos", tipo: "modalidade", chave: def.chave };
  }

  // Nenhum candidato forte — mas se existe algo com a MESMA cor e nome
  // diferente, pode ser a mesma modalidade renomeada (ex.: "Jiu-Jitsu
  // Adulto" virou só "Jiu-Jitsu"). Não dá pra confirmar com segurança
  // (nome sozinho não vale, como pedido), então não cria por cima — fica
  // como pendência pra alguém decidir manualmente, em vez de arriscar
  // criar uma modalidade visualmente duplicada.
  const candidatosFracos = naoVinculados.filter((d) => d.data().cor === def.cor);
  if (candidatosFracos.length > 0) {
    return { status: "pendente", motivo: "possivel_renomeacao_cor_coincide", tipo: "modalidade", chave: def.chave };
  }

  try {
    await detRef.create({
      id: def.chave,
      chave_padrao: def.chave,
      nome: def.nome,
      cor: def.cor,
      ativo: true,
      criado_em: FieldValue.serverTimestamp(),
    });
    return { id: def.chave, status: "criada" };
  } catch (erro) {
    if (erro.code === 6 || /ALREADY_EXISTS/i.test(String(erro.message))) {
      // Corrida: outra execução concorrente criou entre o passo 1 e agora.
      // `.create()` falha atomicamente, não sobrescreve — exatamente o
      // comportamento de "pré-condição de criação" pedido.
      return { id: def.chave, status: "ja_existia_deterministico" };
    }
    throw erro;
  }
}

/** Mesma lógica de `resolverModalidade`, aplicada às faixas de UMA modalidade já resolvida. */
async function resolverFaixa(academiaId, modalidadeId, defModalidade, defFaixa, existentesSnap) {
  const chaveFaixa = `${defModalidade.chave}_${defFaixa.ordem}`;
  const detRef = db.doc(`academias/${academiaId}/faixas/${chaveFaixa}`);
  const detSnap = await detRef.get();
  if (detSnap.exists) {
    return { id: chaveFaixa, status: "ja_existia_deterministico" };
  }

  const docsExistentes = existentesSnap.docs.filter((d) => d.data().modalidadeId === modalidadeId);
  const jaMarcado = docsExistentes.find((d) => d.data().chave_padrao === chaveFaixa);
  if (jaMarcado) {
    return { id: jaMarcado.id, status: "ja_vinculada" };
  }

  // Ordem de graduação é um sinal estrutural mais estável que nome pra
  // faixas (a progressão raramente é reordenada), mas ainda exigimos o
  // nome normalizado batendo junto pra vincular automaticamente — nunca
  // só um dos dois.
  const naoVinculadas = docsExistentes.filter((d) => !d.data().chave_padrao);
  const nomeAlvo = normalizarTexto(defFaixa.nome);
  const candidatosFortes = naoVinculadas.filter((d) => {
    const data = d.data();
    return data.ordem === defFaixa.ordem && normalizarTexto(data.nome) === nomeAlvo;
  });

  if (candidatosFortes.length === 1) {
    const alvo = candidatosFortes[0];
    await alvo.ref.update({ chave_padrao: chaveFaixa });
    return { id: alvo.id, status: "vinculada_por_heuristica" };
  }

  if (candidatosFortes.length > 1) {
    return { status: "pendente", motivo: "multiplos_candidatos_ambiguos", tipo: "faixa", chave: chaveFaixa };
  }

  // Mesma posição na progressão (`ordem`), nome diferente — pode ser uma
  // faixa renomeada (ex.: cor/nome de graduação ajustado pela academia).
  // Não decide sozinho: registra como pendência em vez de criar uma
  // faixa visualmente duplicada na mesma posição.
  const candidatosFracos = naoVinculadas.filter((d) => d.data().ordem === defFaixa.ordem);
  if (candidatosFracos.length > 0) {
    return { status: "pendente", motivo: "possivel_renomeacao_ordem_coincide", tipo: "faixa", chave: chaveFaixa };
  }

  try {
    await detRef.create({
      id: chaveFaixa,
      chave_padrao: chaveFaixa,
      modalidadeId,
      nome: defFaixa.nome,
      cor: defFaixa.cor,
      ordem: defFaixa.ordem,
      tem_graus: defFaixa.tem_graus,
      max_graus: defFaixa.max_graus,
      criado_em: FieldValue.serverTimestamp(),
    });
    return { id: chaveFaixa, status: "criada" };
  } catch (erro) {
    if (erro.code === 6 || /ALREADY_EXISTS/i.test(String(erro.message))) {
      return { id: chaveFaixa, status: "ja_existia_deterministico" };
    }
    throw erro;
  }
}

/**
 * Inicializa (ou completa) as modalidades/faixas padrão de uma academia.
 * Seguro de chamar quantas vezes forem necessárias, pra qualquer
 * academia — nova (vazia) ou antiga (criada pelo mobile, com dados
 * reais e possivelmente personalizados). Nunca apaga nada, nunca
 * sobrescreve nome/cor de um doc existente, nunca cria uma segunda
 * academia nem um segundo administrador — só resolve modalidades/faixas.
 */
async function inicializarModalidadesPadraoCore(academiaId) {
  const [modalidadesSnap, faixasSnap] = await Promise.all([
    db.collection(`academias/${academiaId}/modalidades`).get(),
    db.collection(`academias/${academiaId}/faixas`).get(),
  ]);

  const pendencias = [];
  const resumo = { criadas: 0, ja_existiam: 0, vinculadas_por_heuristica: 0, pendentes: 0 };

  for (const defModalidade of MODALIDADES_PADRAO) {
    const resultadoModalidade = await resolverModalidade(academiaId, defModalidade, modalidadesSnap);

    if (resultadoModalidade.status === "pendente") {
      pendencias.push(resultadoModalidade);
      resumo.pendentes += 1;
      continue; // sem modalidade resolvida, não dá pra resolver as faixas dela com segurança
    }

    if (resultadoModalidade.status === "criada") resumo.criadas += 1;
    else if (resultadoModalidade.status === "vinculada_por_heuristica") resumo.vinculadas_por_heuristica += 1;
    else resumo.ja_existiam += 1;

    for (const defFaixa of defModalidade.faixas) {
      const resultadoFaixa = await resolverFaixa(
        academiaId,
        resultadoModalidade.id,
        defModalidade,
        defFaixa,
        faixasSnap
      );
      if (resultadoFaixa.status === "pendente") {
        pendencias.push({ ...resultadoFaixa, modalidadeId: resultadoModalidade.id });
        resumo.pendentes += 1;
      } else if (resultadoFaixa.status === "criada") resumo.criadas += 1;
      else if (resultadoFaixa.status === "vinculada_por_heuristica") resumo.vinculadas_por_heuristica += 1;
      else resumo.ja_existiam += 1;
    }
  }

  return { resumo, pendencias };
}

async function autorizado(uid, academiaId) {
  const perfilSnap = await db.doc(`usuariosFirebase/${uid}`).get();
  if (!perfilSnap.exists) return false;
  const perfil = perfilSnap.data();
  if (perfil.academiaId === academiaId && perfil.perfil === "Admin") return true;
  const papeis = perfil.roles_by_academy?.[academiaId];
  return Array.isArray(papeis) && papeis.includes("Admin");
}

/**
 * Callable — chamada pelo CRM logo após `cadastrarAcademia()` confirmar o
 * batch principal, e reaproveitável como retry (ver `ModalidadeInitService`
 * no frontend, que decide QUANDO vale a pena chamar de novo: só quando
 * `modalidades_status` está ausente, `'pendente'` ou `'erro'` — nunca
 * para `'completo'` ou `'pendente_revisao'`, que são estados finais do
 * ponto de vista automático). Nunca cria usuário Auth, nunca cria outra
 * academia — só modalidades/faixas e o campo de status na academia já
 * existente.
 */
exports.inicializarModalidadesPadrao = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "É necessário autenticar.");
  }

  const academiaId = String(request.data?.academiaId ?? "").trim();
  if (!academiaId) {
    throw new HttpsError("invalid-argument", "Informe a academia.");
  }

  const academiaRef = db.doc(`academias/${academiaId}`);
  const academiaSnap = await academiaRef.get();
  if (!academiaSnap.exists) {
    throw new HttpsError("not-found", "Academia não encontrada.");
  }

  if (!(await autorizado(request.auth.uid, academiaId))) {
    logger.warn("Inicialização de modalidades rejeitada: uid não é Admin da academia", { academiaId });
    throw new HttpsError("permission-denied", "Você não tem permissão para inicializar esta academia.");
  }

  const statusAtual = academiaSnap.data().modalidades_status;
  // `pendente_revisao` NUNCA é reprocessado automaticamente — rodar de
  // novo não resolve uma ambiguidade que só um humano pode decidir (ex.:
  // nome tão personalizado que não bate com nada do padrão). Só reprocessa
  // de novo se for pedido explicitamente (`forcarReexecucao`).
  const jaResolvido = statusAtual === "completo" || statusAtual === "pendente_revisao";
  if (jaResolvido && !request.data?.forcarReexecucao) {
    return { ok: true, status: statusAtual, jaEstavaCompleto: true };
  }

  try {
    const { resumo, pendencias } = await inicializarModalidadesPadraoCore(academiaId);
    // `pendente_revisao`: terminou de rodar (não travou, não deu erro),
    // mas ficou alguma ambiguidade que precisa de decisão humana — não é
    // "completo" porque ainda falta uma ação, mesmo que não seja um erro.
    const status = pendencias.length > 0 ? "pendente_revisao" : "completo";

    await academiaRef.update({
      modalidades_status: status,
      modalidades_pendencias: pendencias,
      modalidades_atualizado_em: FieldValue.serverTimestamp(),
    });

    logger.info("Inicialização de modalidades concluída", { academiaId, status, resumo });
    return { ok: true, status, resumo, pendencias };
  } catch (erro) {
    logger.error("Falha ao inicializar modalidades", { academiaId, erro: String(erro?.message ?? erro) });
    await academiaRef
      .update({
        modalidades_status: "erro",
        modalidades_ultimo_erro: String(erro?.message ?? "erro desconhecido").slice(0, 300),
        modalidades_tentativas: FieldValue.increment(1),
        modalidades_atualizado_em: FieldValue.serverTimestamp(),
      })
      .catch(() => {});
    throw new HttpsError("internal", "Não foi possível concluir a inicialização agora. Pode tentar de novo.");
  }
});

exports.MODALIDADES_PADRAO = MODALIDADES_PADRAO;
exports.inicializarModalidadesPadraoCore = inicializarModalidadesPadraoCore;
exports.normalizarTexto = normalizarTexto;
