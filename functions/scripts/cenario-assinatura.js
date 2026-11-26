"use strict";

// Coloca a academia de teste do EMULADOR em um cenário de assinatura.
//
// Pré-requisito: `npm run emu` no ar e `npm run seed:emu` já executado.
//
//   npm run cenario                      # lista os cenários
//   npm run cenario -- black             # aplica um cenário
//   npm run cenario -- pro android       # define a loja (padrão: ios)
//
// Depois de aplicar, reabra o app ou recarregue o web.

const { apontarParaEmulador } = require("./emulador-env");
const { CENARIOS, montarCenario } = require("./cenarios-assinatura");

const ACADEMIA_ID = "academia-teste";

async function main() {
  const [nome, plataforma] = process.argv.slice(2);
  if (!nome) {
    console.log("Cenários disponíveis:");
    for (const [chave, { descricao }] of Object.entries(CENARIOS)) {
      console.log(`  ${chave.padEnd(16)} ${descricao}`);
    }
    return;
  }

  const { descricao, campos, remover } = montarCenario(nome, { plataforma });

  const projectId = apontarParaEmulador();
  const admin = require("firebase-admin");
  const { FieldValue } = require("firebase-admin/firestore");
  admin.initializeApp({ projectId });

  const ref = admin.firestore().doc(`academias/${ACADEMIA_ID}`);
  if (!(await ref.get()).exists) {
    throw new Error(`Academia ${ACADEMIA_ID} não existe. Rode antes: npm run seed:emu`);
  }

  const apagar = Object.fromEntries(remover.map((c) => [c, FieldValue.delete()]));
  await ref.update({ ...campos, ...apagar });
  console.log(`Cenário "${nome}" aplicado em ${ACADEMIA_ID}: ${descricao}.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
