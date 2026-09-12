"use strict";

function parseBillingPeriod(value) {
  const match = /^(\d{4})-(\d{2})$/.exec(String(value));
  if (!match) throw new TypeError(`Competência inválida: ${value}`);
  const year = Number(match[1]);
  const month = Number(match[2]);
  if (month < 1 || month > 12) {
    throw new TypeError(`Competência inválida: ${value}`);
  }
  return { year, month, value: `${match[1]}-${match[2]}` };
}

function addBillingMonths(periodValue, amount) {
  const { year, month } = parseBillingPeriod(periodValue);
  const date = new Date(Date.UTC(year, month - 1 + amount, 1));
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, "0")}`;
}

function dueDateForPeriod(periodValue, preferredDay) {
  const { year, month } = parseBillingPeriod(periodValue);
  const lastDay = new Date(Date.UTC(year, month, 0)).getUTCDate();
  const day = Math.min(Math.max(Number(preferredDay) || 1, 1), lastDay);
  return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

function resolveChargeStatus({ dueDate, today, paid, disregarded = false }) {
  if (paid) return "paid";
  if (disregarded) return "disregarded";
  return dueDate < today ? "overdue" : "pending";
}

function monthlyChargeDocumentId(studentId, periodValue) {
  const period = parseBillingPeriod(periodValue).value;
  return `mensalidade__${studentId}__${period}`;
}

const MONTH_LABELS_PT_BR = [
  "janeiro", "fevereiro", "março", "abril", "maio", "junho",
  "julho", "agosto", "setembro", "outubro", "novembro", "dezembro",
];

/** "2026-10" -> "outubro/2026" — usado em mensagens de notificação. */
function monthLabelPtBr(periodValue) {
  const { year, month } = parseBillingPeriod(periodValue);
  return `${MONTH_LABELS_PT_BR[month - 1]}/${year}`;
}

/**
 * Decide, dentro de um grupo de cobranças duplicadas (mesmo aluno + mesma
 * competência), qual documento manter e quais desconsiderar — pura, sem
 * Firestore, pra poder testar sem emulador.
 *
 * `docs`: lista de `{ id, status, criadoEmMillis }` (status: 0 Pendente,
 * 1 Pago, 3 Previsto, 4 Desconsiderado — já filtrados para excluir os
 * Desconsiderado e docs que não são mensalidade antes de chamar).
 *
 * Regra: se exatamente um está Pago, ele fica (nunca se apaga receita já
 * recebida). Se nenhum está pago, fica o de ID determinístico
 * (`mensalidade__...`, o caminho oficial) ou, na falta desse, o mais antigo.
 * Se DOIS OU MAIS estão pagos, o grupo é ambíguo — `ignorar: true`, nada é
 * decidido, fica pra revisão manual (não dá pra saber sozinho qual pagamento
 * é o espúrio sem apagar receita real).
 */
function resolveDuplicateGroup(docs) {
  if (docs.length < 2) {
    return { manterId: docs[0]?.id ?? null, desconsiderarIds: [], ignorar: false };
  }

  const pagos = docs.filter((d) => d.status === 1);
  if (pagos.length > 1) {
    return { manterId: null, desconsiderarIds: [], ignorar: true };
  }

  let manter;
  if (pagos.length === 1) {
    manter = pagos[0];
  } else {
    const determinista = docs.find((d) => d.id.startsWith("mensalidade__"));
    if (determinista) {
      manter = determinista;
    } else {
      manter = [...docs].sort((a, b) => (a.criadoEmMillis ?? 0) - (b.criadoEmMillis ?? 0))[0];
    }
  }

  return {
    manterId: manter.id,
    desconsiderarIds: docs.filter((d) => d.id !== manter.id).map((d) => d.id),
    ignorar: false,
  };
}

module.exports = {
  addBillingMonths,
  dueDateForPeriod,
  monthLabelPtBr,
  monthlyChargeDocumentId,
  parseBillingPeriod,
  resolveChargeStatus,
  resolveDuplicateGroup,
};
