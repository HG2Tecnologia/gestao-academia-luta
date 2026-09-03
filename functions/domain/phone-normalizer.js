"use strict";

function canonicalizePhone(value) {
  const raw = String(value ?? "").trim();
  if (!raw) return null;

  let digits = raw.replace(/\D/g, "");
  if (digits.startsWith("00")) digits = digits.slice(2);

  if (raw.startsWith("+")) {
    return digits.length >= 8 && digits.length <= 15 ? `+${digits}` : null;
  }

  if ((digits.length === 12 || digits.length === 13) && digits.startsWith("55")) {
    return `+${digits}`;
  }

  if (digits.length === 10 || digits.length === 11) {
    return `+55${digits}`;
  }

  return null;
}

function canonicalPhoneDigits(value) {
  return canonicalizePhone(value)?.slice(1) ?? null;
}

module.exports = { canonicalizePhone, canonicalPhoneDigits };
