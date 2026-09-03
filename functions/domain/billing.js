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

module.exports = {
  addBillingMonths,
  dueDateForPeriod,
  monthlyChargeDocumentId,
  parseBillingPeriod,
  resolveChargeStatus,
};
