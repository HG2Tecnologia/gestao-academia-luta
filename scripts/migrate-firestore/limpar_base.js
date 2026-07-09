/**
 * Limpa TODOS os usuários (Firebase Auth + Firestore).
 * Preserva: academia, modalidades, faixas.
 * Apaga: todos os usuariosFirebase, todos os usuarios (subcoleções),
 *        matriculas, pagamentos, presencas, graduacoes, turmas, horarios,
 *        noticias, rankings, conquistas, grupos_familiares, parq, atestados,
 *        planos, contratos, modelos_contrato + todas as contas Firebase Auth.
 */

const admin = require('firebase-admin');
const os = require('os');
const path = require('path');
const fs = require('fs');

const PROJECT_ID = 'sensei-manager-d64c0';

// Credencial
function resolveCredential() {
  const sa = path.join(__dirname, 'serviceAccount.json');
  if (fs.existsSync(sa)) return admin.credential.cert(require(sa));
  return admin.credential.applicationDefault();
}

admin.initializeApp({ credential: resolveCredential(), projectId: PROJECT_ID });
const db = admin.firestore();

// Coleções transacionais a apagar (subcoleções da academia)
const COLECOES_TRANSACIONAIS = [
  'usuarios',        // alunos e equipe (perfil 2/3)
  'matriculas',
  'pagamentos',
  'presencas',
  'graduacoes',
  'turmas',
  'horarios',
  'noticias',
  'rankings',
  'conquistas',
  'grupos_familiares',
  'parq',
  'atestados',
  'planos',
  'contratos',
  'modelos_contrato',
];

// Exclui do usuariosFirebase apenas os não-admin (perfil != 1)
// Deixa o admin intacto.

async function deletarColecao(colRef, batchSize = 400) {
  const snap = await colRef.get();
  if (snap.empty) return 0;

  let total = 0;
  const chunks = [];
  for (let i = 0; i < snap.docs.length; i += batchSize) {
    chunks.push(snap.docs.slice(i, i + batchSize));
  }
  for (const chunk of chunks) {
    const batch = db.batch();
    chunk.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    total += chunk.length;
  }
  return total;
}

async function main() {
  console.log(`\n🔥 Conectando ao projeto: ${PROJECT_ID}\n`);

  // Encontra o(s) documento(s) de academia
  const academiasSnap = await db.collection('academias').get();
  if (academiasSnap.empty) {
    console.log('❌ Nenhuma academia encontrada.');
    process.exit(1);
  }

  for (const academiaDoc of academiasSnap.docs) {
    const academiaId = academiaDoc.id;
    const academiaNome = academiaDoc.data().nome || academiaId;
    console.log(`\n📌 Academia: ${academiaNome} (${academiaId})`);
    console.log('─'.repeat(50));

    for (const colecao of COLECOES_TRANSACIONAIS) {
      const colRef = db.collection('academias').doc(academiaId).collection(colecao);
      const total = await deletarColecao(colRef);
      if (total > 0) {
        console.log(`  ✅ ${colecao}: ${total} documento(s) apagado(s)`);
      } else {
        console.log(`  ⚪ ${colecao}: vazia`);
      }
    }
  }

  // Apaga TODOS os documentos de usuariosFirebase
  console.log('\n📌 usuariosFirebase (apagando todos)');
  console.log('─'.repeat(50));
  const ubTotal = await deletarColecao(db.collection('usuariosFirebase'));
  if (ubTotal > 0) {
    console.log(`  ✅ usuariosFirebase: ${ubTotal} documento(s) apagado(s)`);
  } else {
    console.log(`  ⚪ usuariosFirebase: já vazia`);
  }

  // Apaga TODAS as contas do Firebase Auth
  console.log('\n📌 Firebase Auth (apagando todas as contas)');
  console.log('─'.repeat(50));
  let authTotal = 0;
  let pageToken;
  do {
    const result = await admin.auth().listUsers(1000, pageToken);
    if (result.users.length > 0) {
      const uids = result.users.map(u => u.uid);
      await admin.auth().deleteUsers(uids);
      authTotal += uids.length;
      console.log(`  🗑  Apagados ${uids.length} usuários Auth (total: ${authTotal})`);
    }
    pageToken = result.pageToken;
  } while (pageToken);

  if (authTotal === 0) {
    console.log('  ⚪ Firebase Auth: nenhuma conta encontrada');
  }

  console.log('\n✨ Base limpa! Modalidades e faixas preservadas.\n');
}

main().catch(err => {
  console.error('\n❌ Erro:', err.message);
  process.exit(1);
});
