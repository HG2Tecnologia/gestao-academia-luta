"use strict";

// Aponta o firebase-admin para os emuladores locais. Chamar ANTES de
// `admin.initializeApp()`. Sem variáveis definidas, usa as portas de
// `firebase.json` — assim os scripts funcionam em qualquer terminal (inclusive
// no Windows) e nunca caem em produção por esquecimento.

const HOSTS_LOCAIS = new Set(["127.0.0.1", "localhost"]);
const PADROES = {
  FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080",
  FIREBASE_AUTH_EMULATOR_HOST: "127.0.0.1:9099",
};

function apontarParaEmulador(env = process.env) {
  for (const [nome, padrao] of Object.entries(PADROES)) {
    if (!env[nome]) env[nome] = padrao;
    const host = env[nome].split(":")[0];
    if (!HOSTS_LOCAIS.has(host)) {
      throw new Error(`${nome}=${env[nome]} não é um endereço local. Abortando.`);
    }
  }
  return env.GCLOUD_PROJECT || "sensei-manager-d64c0";
}

module.exports = { apontarParaEmulador };
