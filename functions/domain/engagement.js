"use strict";

/**
 * Mesmo critério já usado na tela "Risco de evasão" (admin_evasao_screen.dart):
 * aluno ativo, com pelo menos 1 presença registrada, 7+ dias desde a última,
 * e que não "voltou com força" (4+ presenças nos últimos 7 dias desconsidera
 * o alerta mesmo que haja uma presença isolada antiga há mais de 7 dias).
 */
function calcularEvasao(alunosAtivos, presencas, hoje = new Date()) {
  const hojeZero = new Date(hoje);
  hojeZero.setHours(0, 0, 0, 0);
  const limite7 = new Date(hojeZero);
  limite7.setDate(limite7.getDate() - 7);

  const ultimaPresenca = {};
  const presencas7 = {};
  for (const p of presencas) {
    const aId = (p.aluno_id || "").toString();
    if (!aId) continue;
    const d = new Date(`${(p.data || p.data_presenca || "").toString().slice(0, 10)}T00:00:00`);
    if (isNaN(d.getTime())) continue;
    if (!ultimaPresenca[aId] || d > ultimaPresenca[aId]) ultimaPresenca[aId] = d;
    if (d > limite7) presencas7[aId] = (presencas7[aId] || 0) + 1;
  }

  const resultado = [];
  for (const aluno of alunosAtivos) {
    const aId = (aluno.id || "").toString();
    const ultima = ultimaPresenca[aId];
    if (!ultima) continue; // nunca treinou → não é evasão
    if ((presencas7[aId] || 0) >= 4) continue; // voltou com força
    const dias = Math.floor((hojeZero - ultima) / 86400000);
    if (dias < 7) continue;
    resultado.push({ alunoId: aId, nome: aluno.nome || "", dias, nivel: dias >= 14 ? "red" : "yellow" });
  }
  return resultado;
}

/**
 * Conta presenças de um aluno numa modalidade desde uma data (exclusive).
 * Resolve a modalidade de cada presença via turma_id -> turmas.modalidadeId
 * (presenças não guardam modalidade diretamente).
 */
function contarPresencasModalidadeDesde(presencasDoAluno, turmaParaModalidade, modalidadeId, desde) {
  let total = 0;
  for (const p of presencasDoAluno) {
    const turmaId = (p.turma_id || "").toString();
    if (!turmaId || turmaParaModalidade[turmaId] !== modalidadeId) continue;
    const d = new Date(`${(p.data || p.data_presenca || "").toString().slice(0, 10)}T00:00:00`);
    if (isNaN(d.getTime())) continue;
    if (!desde || d > desde) total++;
  }
  return total;
}

module.exports = { calcularEvasao, contarPresencasModalidadeDesde };
