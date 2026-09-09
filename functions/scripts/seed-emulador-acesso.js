"use strict";

// Semeia uma academia de teste + um Admin no EMULADOR, para testar no
// simulador os fluxos novos de acesso ao app (provisionar senha ao criar
// aluno, fan-out da redefinição, login por e-mail ou telefone).
//
// Pré-requisito: emuladores no ar (firestore + auth + functions).
//
//   FIRESTORE_EMULATOR_HOST=localhost:8080 \
//   FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
//   node scripts/seed-emulador-acesso.js
//
// Depois, no app (apontado para o emulador), entre como:
//   e-mail:  admin.teste@academia.com
//   senha:   admin123

const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error(
    "Defina FIRESTORE_EMULATOR_HOST e FIREBASE_AUTH_EMULATOR_HOST antes de rodar " +
      "(senão isso escreveria em produção).",
  );
  process.exit(1);
}

admin.initializeApp({ projectId: "sensei-manager-d64c0" });
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
