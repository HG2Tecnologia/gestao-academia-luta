"use strict";

// Garante valores FALSOS para os segredos no emulador de Functions
// (`.secret.local`). Sem eles, o emulador pode buscar os segredos reais no
// projeto de produção — e, por exemplo, enviar e-mail de verdade ao criar uma
// academia de teste. Nunca sobrescreve valor que já exista no arquivo.

const fs = require("node:fs");
const path = require("node:path");

const VALORES_FALSOS = {
  APPLE_APP_ID: "0",
  APPLE_IAP_ISSUER_ID: "emulador",
  APPLE_IAP_KEY_ID: "emulador",
  APPLE_IAP_PRIVATE_KEY: "emulador",
  // Vazio de propósito: o teste de analytics confere o comportamento sem ele.
  GA4_API_SECRET: "",
  GMAIL_APP_PASSWORD: "emulador",
  GOOGLE_PLAY_SERVICE_ACCOUNT_JSON: "{}",
};

const arquivo = path.join(__dirname, "..", ".secret.local");
const atual = fs.existsSync(arquivo) ? fs.readFileSync(arquivo, "utf8") : "";
const definidos = new Set(
  atual.split(/\r?\n/).map((linha) => linha.split("=")[0].trim())
);
const faltando = Object.entries(VALORES_FALSOS).filter(([nome]) => !definidos.has(nome));

if (faltando.length > 0) {
  const separador = atual && !atual.endsWith("\n") ? "\n" : "";
  const novas = faltando.map(([nome, valor]) => `${nome}=${valor}`).join("\n");
  fs.writeFileSync(arquivo, `${atual}${separador}${novas}\n`);
  console.log(`.secret.local: ${faltando.length} segredo(s) falso(s) adicionado(s).`);
}
