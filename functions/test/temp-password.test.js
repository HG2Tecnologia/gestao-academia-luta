"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const { generateTemporaryPassword, ALPHABET } = require("../domain/temp-password");

function sequentialRandom(sequence) {
  let i = 0;
  return (max) => {
    const value = sequence[i % sequence.length] % max;
    i++;
    return value;
  };
}

test("senha temporária: tem o tamanho pedido e usa só o alfabeto sem ambiguidade", () => {
  const senha = generateTemporaryPassword(sequentialRandom([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]), 10);
  assert.equal(senha.length, 10);
  for (const char of senha) {
    assert.ok(ALPHABET.includes(char), `caractere inesperado: ${char}`);
  }
  assert.ok(!/[0O1Il]/.test(senha), "não deve conter caracteres ambíguos");
});

test("senha temporária: garante ao menos uma letra e um dígito", () => {
  // Mesmo com um gerador que sempre devolve zero (o índice mais "vazio"),
  // as duas primeiras posições reservadas garantem letra + dígito.
  const senha = generateTemporaryPassword(() => 0, 8);
  assert.ok(/[A-Za-z]/.test(senha));
  assert.ok(/[2-9]/.test(senha));
});

test("senha temporária: é determinística para um gerador determinístico", () => {
  const gerar = () => generateTemporaryPassword(sequentialRandom([3, 7, 1, 9, 2, 5, 0, 4, 6, 8]), 10);
  assert.equal(gerar(), gerar());
});

test("senha temporária: exige ao menos 6 caracteres", () => {
  assert.throws(() => generateTemporaryPassword(() => 0, 5), RangeError);
});
