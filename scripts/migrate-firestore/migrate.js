/**
 * Migração Neon PostgreSQL → Firebase Firestore
 *
 * Como usar:
 * 1. Coloque serviceAccount.json nesta pasta (baixe do Firebase Console →
 *    Configurações do Projeto → Contas de serviço → Gerar nova chave privada)
 * 2. npm install
 * 3. node migrate.js
 */

const { Pool } = require('pg');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ─── Verificações iniciais ────────────────────────────────────────────────────

// ─── Credencial (serviceAccount.json ou Firebase CLI) ────────────────────────

const os = require('os');

function resolveCredential() {
  const serviceAccountPath = path.join(__dirname, 'serviceAccount.json');
  if (fs.existsSync(serviceAccountPath)) {
    console.log('🔑 Usando serviceAccount.json\n');
    return admin.credential.cert(require(serviceAccountPath));
  }

  // ADC já configurado (gcloud auth application-default login)
  const adcPath = path.join(os.homedir(), '.config', 'gcloud', 'application_default_credentials.json');
  if (fs.existsSync(adcPath)) {
    console.log('🔑 Usando Application Default Credentials (gcloud)\n');
    return admin.credential.applicationDefault();
  }

  // Fallback: cria arquivo ADC temporário a partir das credenciais do Firebase CLI
  const cliConfigPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (fs.existsSync(cliConfigPath)) {
    try {
      const config = JSON.parse(fs.readFileSync(cliConfigPath, 'utf8'));
      const token = config?.tokens?.refresh_token;
      if (token) {
        const adcJson = JSON.stringify({
          type: 'authorized_user',
          client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
          client_secret: 'j9iVZfS8ywKVglSahm6j-g',
          refresh_token: token,
        });
        const tmpAdc = path.join(__dirname, '.tmp_adc.json');
        fs.writeFileSync(tmpAdc, adcJson);
        process.env.GOOGLE_APPLICATION_CREDENTIALS = tmpAdc;
        console.log('🔑 Usando credenciais do Firebase CLI (via ADC)\n');
        return admin.credential.applicationDefault();
      }
    } catch (_) {}
  }

  console.error('\n❌ Nenhuma credencial encontrada!');
  console.error('Execute: gcloud auth application-default login');
  console.error('Ou coloque serviceAccount.json nesta pasta.\n');
  process.exit(1);
}

// ─── Inicialização ────────────────────────────────────────────────────────────

admin.initializeApp({
  credential: resolveCredential(),
  projectId: 'sensei-manager-d64c0',
});

const db = admin.firestore();
const auth = admin.auth();

const pool = new Pool({
  connectionString:
    'postgresql://neondb_owner:npg_TwgBl3QPC0vy@ep-tiny-forest-aqg4attx-pooler.c-8.us-east-1.aws.neon.tech/neondb?sslmode=require',
  ssl: { rejectUnauthorized: false },
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

// Mapeamento de enum Perfil (inteiro → string)
const PERFIL_MAP = { 0: 'Admin', 1: 'Secretaria', 2: 'Professor', 3: 'Aluno' };
function perfilNome(num) {
  return PERFIL_MAP[num] ?? 'Aluno';
}

const MAX_FIELD_BYTES = 500_000; // Firestore doc limit ~1MB; campos base64 podem estourar

// Converte row do PG para objeto Firestore (remove nulls, converte Dates, descarta blobs grandes)
function toFirestore(row) {
  const result = {};
  for (const [key, value] of Object.entries(row)) {
    if (value === null || value === undefined) continue;
    if (value instanceof Date) {
      result[key] = admin.firestore.Timestamp.fromDate(value);
    } else if (typeof value === 'string' && Buffer.byteLength(value, 'utf8') > MAX_FIELD_BYTES) {
      console.log(`   ⚠️  Campo "${key}" omitido (${(Buffer.byteLength(value, 'utf8') / 1024).toFixed(0)}KB — use Firebase Storage para imagens)`);
    } else {
      result[key] = value;
    }
  }
  return result;
}

// Remove campos sensíveis do usuário antes de gravar no Firestore
function sanitizeUsuario(row) {
  const {
    senha_hash,
    refresh_token,
    refresh_token_expiry,
    reset_password_token,
    reset_password_token_expiry,
    ...rest
  } = row;
  return rest;
}

// Grava documentos em lotes de 400 (limite Firestore = 500)
async function batchWrite(docs) {
  const BATCH_SIZE = 400;
  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + BATCH_SIZE);
    for (const { path: docPath, data } of chunk) {
      batch.set(db.doc(docPath), data);
    }
    await batch.commit();
  }
}

// Tenta múltiplos nomes de tabela (alguns são snake_case, outros PascalCase no PG)
async function queryTable(primaryName, ...fallbackNames) {
  const attempts = [primaryName, ...fallbackNames];
  for (const name of attempts) {
    try {
      const { rows } = await pool.query(`SELECT * FROM ${name}`);
      return rows;
    } catch (e) {
      if (e.code === '42P01') continue; // tabela não existe, tenta próxima
      throw e;
    }
  }
  console.log(`    ⚠️  Tabela ${primaryName} não encontrada, pulando.`);
  return [];
}

// ─── Migração ─────────────────────────────────────────────────────────────────

async function migrate() {
  console.log('\n🚀 Iniciando migração Neon → Firestore...\n');
  const start = Date.now();

  try {
    // 1. Academias
    console.log('📚 Academias...');
    const academias = await queryTable('academias');
    await batchWrite(
      academias.map((row) => ({ path: `academias/${row.id}`, data: toFirestore(row) }))
    );
    console.log(`   ✓ ${academias.length} registros\n`);

    // 2. Conquistas (globais, não por academia)
    console.log('🏆 Conquistas (globais)...');
    const conquistas = await queryTable('conquistas');
    await batchWrite(
      conquistas.map((row) => ({ path: `conquistas/${row.id}`, data: toFirestore(row) }))
    );
    console.log(`   ✓ ${conquistas.length} registros\n`);

    // 3. Tabelas por academia
    const tabelas = [
      { pg: 'modalidades',      sub: 'modalidades' },
      { pg: 'faixas',           sub: 'faixas' },
      { pg: 'turmas',           sub: 'turmas' },
      { pg: 'horarios',         sub: 'horarios' },
      { pg: 'matriculas',       sub: 'matriculas' },
      { pg: 'presencas',        sub: 'presencas' },
      { pg: 'graduacoes',       sub: 'graduacoes' },
      { pg: 'funcionarios',     sub: 'funcionarios' },
      { pg: 'conquistas_aluno', sub: 'conquistas_aluno' },
      { pg: 'atestados_medicos',sub: 'atestados' },
      { pg: 'par_qs',           sub: 'par_qs' },
      { pg: 'rankings_custom',  sub: 'rankings_custom' },
      { pg: 'lancamentos_ponto',sub: 'lancamentos_ponto' },
      { pg: 'pontos_ranking',   sub: 'pontos_ranking' },
      { pg: 'noticias',         sub: 'noticias' },
      { pg: 'notificacoes',     sub: 'notificacoes',      alt: ['"Notificacoes"'] },
      { pg: 'contratos',        sub: 'contratos',         alt: ['"Contratos"'] },
      { pg: 'modelos_contrato', sub: 'modelos_contrato',  alt: ['"ModelosContrato"'] },
      { pg: 'grupos_familiares',sub: 'grupos_familiares', alt: ['"GruposFamiliares"'] },
      { pg: 'pagamentos',       sub: 'pagamentos',        alt: ['"Pagamentos"'] },
      { pg: 'planos',           sub: 'planos',            alt: ['"Planos"'] },
    ];

    for (const t of tabelas) {
      console.log(`📦 ${t.pg}...`);
      const rows = await queryTable(t.pg, ...(t.alt ?? []));
      if (rows.length === 0) { console.log('   (vazio)\n'); continue; }
      await batchWrite(
        rows.map((row) => ({
          path: `academias/${row.academia_id}/${t.sub}/${row.id}`,
          data: toFirestore(row),
        }))
      );
      console.log(`   ✓ ${rows.length} registros\n`);
    }

    // 4. Usuários (especial: cria contas Firebase Auth e documentos de lookup)
    console.log('👥 Usuários (+ contas Firebase Auth)...');
    const usuarios = await queryTable('usuarios');

    // 4a. Grava documentos no Firestore (sem campos sensíveis)
    await batchWrite(
      usuarios.map((row) => ({
        path: `academias/${row.academia_id}/usuarios/${row.id}`,
        data: {
          ...toFirestore(sanitizeUsuario(row)),
          perfil_nome: perfilNome(row.perfil),
        },
      }))
    );
    console.log(`   ✓ ${usuarios.length} documentos Firestore gravados`);

    // 4b. Cria contas Firebase Auth e documentos de lookup usuariosFirebase/{uid}
    console.log('   Criando/vinculando contas Firebase Auth...');
    let criadas = 0, vinculadas = 0, erros = 0;
    const resetLinks = [];

    for (const user of usuarios) {
      if (!user.email) continue;

      let uid = user.firebase_uid;

      if (!uid) {
        // Usuário sem conta Firebase: cria uma
        try {
          const userRecord = await auth.createUser({
            email: user.email,
            displayName: user.nome ?? '',
            emailVerified: false,
          });
          uid = userRecord.uid;
          criadas++;

          // Gera link de redefinição de senha (usuário precisará definir uma nova senha)
          try {
            const link = await auth.generatePasswordResetLink(user.email);
            resetLinks.push({ email: user.email, link });
          } catch (_) {}
        } catch (e) {
          if (e.code === 'auth/email-already-exists') {
            // Já existe no Firebase Auth, só busca o UID
            try {
              const existing = await auth.getUserByEmail(user.email);
              uid = existing.uid;
              vinculadas++;
            } catch (_) {}
          } else {
            console.warn(`   ⚠️  Erro ao criar conta para ${user.email}: ${e.message}`);
            erros++;
            continue;
          }
        }
      } else {
        vinculadas++;
      }

      if (!uid) continue;

      // Documento de lookup: permite encontrar academiaId pelo Firebase UID
      await db.collection('usuariosFirebase').doc(uid).set({
        academiaId: user.academia_id,
        usuarioId: user.id,
        perfil: perfilNome(user.perfil),
        nome: user.nome ?? '',
        email: user.email,
      });

      // Atualiza o documento do usuário com o Firebase UID (se não tinha)
      if (!user.firebase_uid) {
        await db.doc(`academias/${user.academia_id}/usuarios/${user.id}`).update({
          firebase_uid: uid,
        });
      }
    }

    console.log(`   ✓ ${criadas} contas Firebase novas criadas`);
    console.log(`   ✓ ${vinculadas} contas existentes vinculadas`);
    if (erros > 0) console.log(`   ⚠️  ${erros} erros`);

    // Salva links de redefinição em arquivo
    if (resetLinks.length > 0) {
      const linksPath = path.join(__dirname, 'reset_links.txt');
      const content = resetLinks
        .map((r) => `${r.email}\n${r.link}\n`)
        .join('\n');
      fs.writeFileSync(linksPath, content);
      console.log(`\n   📧 ${resetLinks.length} links de redefinição de senha salvos em reset_links.txt`);
      console.log('      Envie esses links para os usuários que nunca fizeram login via Firebase.\n');
    }

    const elapsed = ((Date.now() - start) / 1000).toFixed(1);
    console.log(`\n✅ Migração concluída em ${elapsed}s!`);
    console.log('\nPróximos passos:');
    console.log('1. Faça upload das regras Firestore (firestore.rules) no Firebase Console');
    console.log('2. Rebuilde e instale o app Flutter');
    console.log('3. Usuários com contas novas precisam usar "Esqueci minha senha" no app\n');
  } catch (err) {
    console.error('\n❌ Migração falhou:', err);
    throw err;
  } finally {
    await pool.end();
    const tmpAdc = path.join(__dirname, '.tmp_adc.json');
    if (fs.existsSync(tmpAdc)) fs.unlinkSync(tmpAdc);
    process.exit(0);
  }
}

migrate();
