"use strict";

// Sem caracteres ambíguos (0/O, 1/I/l) — a senha é lida e digitada por um
// humano, geralmente por telefone ou anotada no papel.
const LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz";
const DIGITS = "23456789";
const ALPHABET = LETTERS + DIGITS;

function randomChar(alphabet, randomInt) {
  return alphabet[randomInt(alphabet.length)];
}

/**
 * Gera uma senha temporária segura e legível.
 *
 * `randomInt(max)` deve devolver um inteiro uniforme em [0, max) — em
 * produção, um CSPRNG (`crypto.randomInt`); em teste, um gerador
 * determinístico para resultados reproduzíveis.
 *
 * Garante ao menos uma letra e um dígito, depois embaralha para não deixar
 * sempre letra+dígito nas duas primeiras posições.
 */
function generateTemporaryPassword(randomInt, length = 10) {
  if (length < 6) {
    throw new RangeError("A senha temporária precisa ter ao menos 6 caracteres.");
  }

  const chars = [randomChar(LETTERS, randomInt), randomChar(DIGITS, randomInt)];
  for (let i = chars.length; i < length; i++) {
    chars.push(randomChar(ALPHABET, randomInt));
  }

  for (let i = chars.length - 1; i > 0; i--) {
    const j = randomInt(i + 1);
    [chars[i], chars[j]] = [chars[j], chars[i]];
  }

  return chars.join("");
}

module.exports = { generateTemporaryPassword, ALPHABET };
