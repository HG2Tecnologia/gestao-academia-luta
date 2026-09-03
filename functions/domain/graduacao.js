"use strict";

function toDateValue(value) {
  if (!value) return null;
  if (typeof value === "object" && typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function toInt(value) {
  if (typeof value === "number") return Math.trunc(value);
  const parsed = parseInt(value, 10);
  return Number.isNaN(parsed) ? 0 : parsed;
}

/**
 * Ordena do registro mais antigo para o mais novo — espelha
 * `compararGraduacoesCronologicamente` de `mobile/lib/core/graduacao_order.dart`.
 * Mantido em paridade com o cliente para que o alerta de conflito descreva a
 * mesma ordem que a pessoa vê no histórico do app.
 */
function compararCronologicamente(a, b) {
  const dataA = toDateValue(a.data_exame ?? a.dataExame);
  const dataB = toDateValue(b.data_exame ?? b.dataExame);
  if (dataA && dataB) {
    const diff = dataA.getTime() - dataB.getTime();
    if (diff !== 0) return diff;
  } else if (dataA) {
    return -1;
  } else if (dataB) {
    return 1;
  }

  const criadoA = toDateValue(a.criado_em ?? a.criadoEm);
  const criadoB = toDateValue(b.criado_em ?? b.criadoEm);
  if (criadoA && criadoB) {
    const diff = criadoA.getTime() - criadoB.getTime();
    if (diff !== 0) return diff;
  } else if (criadoA) {
    return 1;
  } else if (criadoB) {
    return -1;
  }

  const faixaDiff = toInt(a.faixaOrdem ?? a.faixa_ordem) - toInt(b.faixaOrdem ?? b.faixa_ordem);
  if (faixaDiff !== 0) return faixaDiff;
  const grauDiff = toInt(a.grau) - toInt(b.grau);
  if (grauDiff !== 0) return grauDiff;
  return String(a.id ?? "").localeCompare(String(b.id ?? ""));
}

/** Compara só a progressão (faixa + grau), independente do nome da faixa. */
function compararProgressao(a, b) {
  const faixaDiff = toInt(a.faixaOrdem ?? a.faixa_ordem) - toInt(b.faixaOrdem ?? b.faixa_ordem);
  if (faixaDiff !== 0) return faixaDiff;
  const grauDiff = toInt(a.grau) - toInt(b.grau);
  if (grauDiff !== 0) return grauDiff;
  return compararCronologicamente(a, b);
}

/**
 * Detecta uma inversão: um registro cronologicamente mais novo com
 * progressão menor que a de um registro anterior no tempo, na mesma
 * modalidade. Só considera graduações aprovadas. Retorna o primeiro par
 * invertido encontrado, ou null se o histórico está consistente.
 */
function detectarConflitoDeOrdem(graduacoes) {
  const aprovadas = graduacoes.filter((g) => g.aprovado === true);
  const ordenadas = [...aprovadas].sort(compararCronologicamente);
  for (let i = 1; i < ordenadas.length; i++) {
    const anterior = ordenadas[i - 1];
    const atual = ordenadas[i];
    if (compararProgressao(atual, anterior) < 0) {
      return { anterior, atual };
    }
  }
  return null;
}

module.exports = { compararCronologicamente, compararProgressao, detectarConflitoDeOrdem };
