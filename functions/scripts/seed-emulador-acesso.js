"use strict";

// Semeia uma academia de teste + um Admin no EMULADOR, para testar no
// simulador os fluxos novos de acesso ao app (provisionar senha ao criar
// aluno, fan-out da redefinição, login por e-mail ou telefone).
//
// Pré-requisito: emuladores no ar (firestore + auth + functions).
//
//   npm run seed:emu
//
// Sem variáveis de ambiente, usa as portas de `firebase.json`. Nunca grava
// fora do emulador (ver `emulador-env.js`).
//
// Depois, no app (apontado para o emulador), entre como:
//   e-mail:  admin.teste@academia.com
//   senha:   admin123

const admin = require("firebase-admin");
const { apontarParaEmulador } = require("./emulador-env");

admin.initializeApp({ projectId: apontarParaEmulador() });
const db = admin.firestore();
const auth = admin.auth();

const ACADEMIA_ID = "academia-teste";
const ADMIN_EMAIL = "admin.teste@academia.com";
const ADMIN_SENHA = "admin123";

async function ensureUser(email, password) {
  try {
    return await auth.getUserByEmail(email);
  } catch (_) {
    return auth.createUser({ email, password });
  }
}

(async () => {
  await db.doc(`academias/${ACADEMIA_ID}`).set({
    nome: "Academia Teste",
    plano_tipo: 1,
    criado_em: new Date(),
    noticias_ativas: false,
  });

  const adminUser = await ensureUser(ADMIN_EMAIL, ADMIN_SENHA);
  const adminUid = adminUser.uid;
  const key = `${ACADEMIA_ID}|funcionarios|admin-teste`;

  await db.doc(`academias/${ACADEMIA_ID}/funcionarios/admin-teste`).set({
    id: "admin-teste",
    nome: "Admin Teste",
    perfil: "Admin",
    perfil_nome: "Admin",
    ativo: true,
    email: ADMIN_EMAIL,
    firebaseUid: adminUid,
    permissoes: { acesso_redefinir_senha: true },
  });

  await db.doc(`usuariosFirebase/${adminUid}`).set({
    schemaVersion: 2,
    uid: adminUid,
    status: "active",
    primary_profile_key: key,
    profile_keys: [key],
    profile_refs: [
      {
        key,
        academiaId: ACADEMIA_ID,
        colecao: "funcionarios",
        usuarioId: "admin-teste",
        perfil_nome: "Admin",
        nome: "Admin Teste",
      },
    ],
    academiaId: ACADEMIA_ID,
    usuarioId: "admin-teste",
    colecao: "funcionarios",
    perfil: "Admin",
    nome: "Admin Teste",
    email: ADMIN_EMAIL,
  });

  console.log("Seed OK.");
  console.log(`  Academia: ${ACADEMIA_ID}`);
  console.log(`  Login Admin no app:  ${ADMIN_EMAIL} / ${ADMIN_SENHA}`);
  process.exit(0);
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
