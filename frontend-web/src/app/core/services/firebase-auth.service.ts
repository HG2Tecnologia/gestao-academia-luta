import { Injectable, signal } from '@angular/core';
import { Router } from '@angular/router';
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut,
  onAuthStateChanged,
  reauthenticateWithCredential,
  updatePassword,
  sendPasswordResetEmail,
  EmailAuthProvider,
  User as FirebaseUser,
  AuthErrorCodes,
} from 'firebase/auth';
import { doc, collection, getDoc, addDoc, writeBatch, serverTimestamp } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { auth, db, functions } from '../firebase/firebase';
import { StoredUser } from '../models/stored-user.model';
import { permissoesParaPerfil } from '../models/permissoes.model';
import { MODALIDADES_DEFAULT } from '../firebase/academia-seeds';

export interface CadastrarAcademiaRequest {
  nome: string;
  email: string;
  senha: string;
  nomeAcademia: string;
  subdominio: string;
  telefone?: string;
}

const STORAGE_KEY = 'crm_stored_user';
const RETRY_CODES = new Set<string>([
  AuthErrorCodes.INVALID_PASSWORD,
  AuthErrorCodes.USER_DELETED,
  'auth/invalid-credential',
  'auth/wrong-password',
  'auth/user-not-found',
]);

/** Perfis que têm acesso ao CRM — nunca Aluno, diferente do app mobile. */
const PERFIS_STAFF = new Set(['Admin', 'Secretaria', 'Professor']);

export class LoginSemAcessoStaffError extends Error {
  constructor() {
    super('Esta conta não tem nenhum perfil de equipe (Admin/Secretaria/Professor) vinculado.');
  }
}

/**
 * Espelho de `mobile/lib/screens/auth/login_screen.dart` — mesmo fluxo
 * (telefone/e-mail → e-mail sintético `<digitos>@sensei.app` → Firebase
 * Auth → `usuariosFirebase/{uid}` → seletor de perfil se houver mais de
 * um), mas restrito a perfis de equipe (sem Aluno) e sem backend C#
 * nenhum no caminho — fala direto com o MESMO Firestore do app.
 *
 * Simplificação consciente em relação ao Dart: só suporta contas
 * `schemaVersion >= 2` (`profile_refs` já persistidos server-side). Contas
 * de equipe são criadas/mantidas ativamente, então a janela de compat v1
 * do mobile (telefone/e-mail legado) não se aplica aqui; se aparecer um
 * caso real de conta de equipe ainda em v1, portar o fallback dinâmico de
 * `firestore_service.dart::getUserByFirebaseUid` então.
 */
@Injectable({ providedIn: 'root' })
export class FirebaseAuthService {
  readonly currentUser = signal<StoredUser | null>(this.carregarDoStorage());
  readonly firebaseUser = signal<FirebaseUser | null>(null);

  /**
   * Resolve na primeira vez que o Firebase Auth termina de restaurar (ou
   * confirmar que não há) a sessão persistida. Logo após recarregar a
   * página, `auth.currentUser` fica `null` por um instante mesmo com
   * sessão válida — os guards de rota esperam essa promise antes de
   * decidir redirecionar pro login, pra não deslogar ninguém à toa.
   */
  readonly authReady: Promise<FirebaseUser | null>;

  constructor(private readonly router: Router) {
    this.authReady = new Promise((resolve) => {
      const unsubscribe = onAuthStateChanged(auth, (user) => {
        this.firebaseUser.set(user);
        resolve(user);
        unsubscribe();
      });
    });
    onAuthStateChanged(auth, (user) => this.firebaseUser.set(user));
  }

  private carregarDoStorage(): StoredUser | null {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return raw ? (JSON.parse(raw) as StoredUser) : null;
    } catch {
      return null;
    }
  }

  private salvarNoStorage(user: StoredUser): void {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(user));
    this.currentUser.set(user);
  }

  /** Igual a `PhoneNormalizer.digits` — só os dígitos, sem DDI duplicado. */
  private candidatosEmailSintetico(identificador: string): string[] {
    const digits = identificador.replace(/\D/g, '');
    if (!digits) return [];
    const candidatos = new Set<string>([`${digits}@sensei.app`]);
    if (!digits.startsWith('55') && digits.length <= 11) {
      candidatos.add(`55${digits}@sensei.app`);
    }
    return [...candidatos];
  }

  private pareceEmail(identificador: string): boolean {
    return /[a-zA-Z@]/.test(identificador);
  }

  /** Autentica no Firebase — tenta e-mail direto, ou cada candidato sintético de telefone. */
  private async autenticar(identificador: string, senha: string) {
    const valor = identificador.trim();
    if (this.pareceEmail(valor)) {
      return signInWithEmailAndPassword(auth, valor.toLowerCase(), senha);
    }
    const candidatos = this.candidatosEmailSintetico(valor);
    let ultimoErro: unknown;
    for (const email of candidatos) {
      try {
        return await signInWithEmailAndPassword(auth, email, senha);
      } catch (erro: any) {
        ultimoErro = erro;
        if (!RETRY_CODES.has(erro?.code)) throw erro;
      }
    }
    throw ultimoErro ?? new Error('auth/invalid-credential');
  }

  /**
   * Login completo: autentica, resolve `usuariosFirebase/{uid}`, filtra
   * pra perfis de equipe e devolve o `StoredUser` já salvo localmente.
   * Lança `LoginSemAcessoStaffError` se a conta não tiver NENHUM perfil
   * Admin/Secretaria/Professor — ela pode existir (ex: só Aluno no app),
   * mas não tem o que fazer no CRM.
   */
  async login(identificador: string, senha: string): Promise<StoredUser> {
    const credential = await this.autenticar(identificador, senha);
    const uid = credential.user.uid;

    try {
      const refreshAccount = httpsCallable(functions, 'refreshAccessAccount');
      await refreshAccount();
    } catch {
      // Best-effort, igual ao mobile — nunca bloqueia o login.
    }

    const contaSnap = await getDoc(doc(db, 'usuariosFirebase', uid));
    if (!contaSnap.exists()) {
      await firebaseSignOut(auth);
      throw new Error('Usuário não encontrado no sistema. Contate o administrador.');
    }
    const conta = contaSnap.data() as Record<string, any>;

    const schemaVersion = conta['schemaVersion'] ?? 1;
    const perfisTodos: Record<string, any>[] =
      schemaVersion >= 2 && Array.isArray(conta['profile_refs'])
        ? conta['profile_refs']
        : Array.isArray(conta['perfis'])
          ? conta['perfis']
          : [];

    const perfisStaff = perfisTodos.filter((p) => PERFIS_STAFF.has(p['perfil_nome']));
    if (perfisTodos.length > 0 && perfisStaff.length === 0) {
      await firebaseSignOut(auth);
      throw new LoginSemAcessoStaffError();
    }

    let usuarioId: string = conta['usuarioId'] ?? uid;
    let academiaId: string | null = conta['academiaId'] ?? null;
    let perfilNome: string = conta['perfil'] ?? '';
    let nomeUsuario: string = conta['nome'] ?? '';
    let permissoes: Record<string, boolean> = {};
    let colecao: string = conta['colecao'] ?? 'usuarios';

    const selecionado = perfisStaff.length >= 1 ? perfisStaff[0] : null;
    // Com 2+ perfis de equipe (raro — ex: a mesma pessoa é Admin em duas
    // academias), o componente de login mostra o seletor antes de chamar
    // este método de novo já com o perfil escolhido; aqui só resolve o caso
    // de 1 perfil direto. Ver `resolverPerfisStaff` usado pelo componente.
    if (selecionado) {
      usuarioId = selecionado['usuarioId'] ?? usuarioId;
      nomeUsuario = selecionado['nome'] ?? nomeUsuario;
      academiaId = selecionado['academiaId'] ?? academiaId;
      perfilNome = selecionado['perfil_nome'] ?? perfilNome;
      colecao = selecionado['colecao'] ?? colecao;
    }

    // Conta sem array de perfis nenhum (caso legado de perfil único) — o
    // perfil efetivo é o do próprio doc de conta. Precisa do mesmo bloqueio
    // de "só equipe" que o array já recebeu acima.
    if (perfisTodos.length === 0 && !PERFIS_STAFF.has(perfilNome)) {
      await firebaseSignOut(auth);
      throw new LoginSemAcessoStaffError();
    }

    if (colecao === 'funcionarios' && academiaId) {
      const funcSnap = await getDoc(doc(db, 'academias', academiaId, 'funcionarios', usuarioId));
      const func = funcSnap.data() as Record<string, any> | undefined;
      const rawPerm = func?.['permissoes'];
      permissoes =
        rawPerm && typeof rawPerm === 'object'
          ? Object.fromEntries(Object.entries(rawPerm).map(([k, v]) => [k, v === true]))
          : permissoesParaPerfil(perfilNome);
    } else {
      permissoes = permissoesParaPerfil(perfilNome);
    }

    const storedUser: StoredUser = {
      id: usuarioId,
      nome: nomeUsuario,
      email: conta['email'] ?? credential.user.email ?? '',
      perfil: perfilNome,
      academiaId,
      permissoes,
      perfis: perfisStaff,
      mustChangePassword: conta['must_change_password'] === true,
    };
    this.salvarNoStorage(storedUser);
    return storedUser;
  }

  /** Devolve os perfis de equipe quando há mais de um — pro componente mostrar o seletor. */
  resolverPerfisStaff(user: StoredUser): Record<string, any>[] {
    return user.perfis ?? [];
  }

  async trocarParaPerfil(selecionado: Record<string, any>): Promise<StoredUser> {
    const usuarioId: string = selecionado['usuarioId'];
    const academiaId: string = selecionado['academiaId'];
    const colecao: string = selecionado['colecao'] ?? 'usuarios';
    const perfilNome: string = selecionado['perfil_nome'];

    let permissoes: Record<string, boolean> = permissoesParaPerfil(perfilNome);
    if (colecao === 'funcionarios') {
      const funcSnap = await getDoc(doc(db, 'academias', academiaId, 'funcionarios', usuarioId));
      const func = funcSnap.data() as Record<string, any> | undefined;
      const rawPerm = func?.['permissoes'];
      if (rawPerm && typeof rawPerm === 'object') {
        permissoes = Object.fromEntries(Object.entries(rawPerm).map(([k, v]) => [k, v === true]));
      }
    }

    const atual = this.currentUser();
    const storedUser: StoredUser = {
      id: usuarioId,
      nome: selecionado['nome'] ?? atual?.nome ?? '',
      email: atual?.email ?? '',
      perfil: perfilNome,
      academiaId,
      permissoes,
      perfis: atual?.perfis ?? [],
      mustChangePassword: atual?.mustChangePassword ?? false,
    };
    this.salvarNoStorage(storedUser);
    return storedUser;
  }

  async logout(): Promise<void> {
    await firebaseSignOut(auth);
    localStorage.removeItem(STORAGE_KEY);
    this.currentUser.set(null);
    this.router.navigate(['/login']);
  }

  isAuthenticated(): boolean {
    return this.currentUser() !== null && auth.currentUser !== null;
  }

  getUser(): StoredUser | null {
    return this.currentUser();
  }

  /** Atualiza o `StoredUser` em memória + localStorage (ex: após editar o próprio nome em "Meu perfil"), sem precisar relogar. */
  atualizarPerfilLocal(dados: Partial<StoredUser>): void {
    const atual = this.currentUser();
    if (!atual) return;
    this.salvarNoStorage({ ...atual, ...dados });
  }

  /** Troca a própria senha — reautentica com a senha atual (exigência do Firebase Auth pra operações sensíveis) antes de chamar `updatePassword`. */
  async alterarSenha(senhaAtual: string, novaSenha: string): Promise<void> {
    const user = auth.currentUser;
    if (!user?.email) throw new Error('Sessão inválida.');
    const credential = EmailAuthProvider.credential(user.email, senhaAtual);
    await reauthenticateWithCredential(user, credential);
    await updatePassword(user, novaSenha);
  }

  /**
   * Espelho de `mobile/lib/screens/auth/cadastro_screen.dart::_cadastrar` —
   * mesma sequência (Auth → doc da academia → doc do usuário Admin → lookup
   * `usuariosFirebase` → seed de modalidades/faixas), cliente-Firestore
   * direto como lá (sem Cloud Function; as regras de segurança já permitem
   * esse bootstrap pro próprio uid recém-criado). Se o Firestore falhar
   * depois da conta Auth criada, apaga a conta Auth — mesmo rollback do
   * mobile, pra não deixar login "fantasma" sem academia.
   */
  async cadastrarAcademia(req: CadastrarAcademiaRequest): Promise<StoredUser> {
    const email = req.email.trim().toLowerCase();
    const credential = await createUserWithEmailAndPassword(auth, email, req.senha);
    const uid = credential.user.uid;

    try {
      const academiaRef = doc(collection(db, 'academias'));
      const academiaId = academiaRef.id;
      const usuarioRef = doc(collection(db, 'academias', academiaId, 'usuarios'));
      const usuarioId = usuarioRef.id;
      const telefone = req.telefone?.trim();

      const batch = writeBatch(db);
      batch.set(academiaRef, {
        id: academiaId,
        nome: req.nomeAcademia,
        email,
        subdominio: req.subdominio,
        ...(telefone ? { telefone } : {}),
        ativo: true,
        plano_tipo: 0,
        noticias_ativas: false,
        created_by_uid: uid,
        criado_em: serverTimestamp(),
      });
      batch.set(usuarioRef, {
        id: usuarioId,
        academia_id: academiaId,
        firebase_uid: uid,
        firebaseUid: uid,
        nome: req.nome,
        email,
        perfil: 0,
        perfil_nome: 'Admin',
        ativo: true,
        xp_total: 0,
        xp_mensal: 0,
        nivel: 0,
        ...(telefone ? { telefone } : {}),
        criado_em: serverTimestamp(),
      });

      const profileKey = `${academiaId}|usuarios|${usuarioId}`;
      const profileRef = {
        key: profileKey,
        academiaId,
        usuarioId,
        colecao: 'usuarios',
        perfil_nome: 'Admin',
        nome: req.nome,
      };
      batch.set(doc(db, 'usuariosFirebase', uid), {
        schemaVersion: 2,
        uid,
        status: 'active',
        primary_profile_key: profileKey,
        profile_keys: [profileKey],
        profile_refs: [profileRef],
        academy_ids: [academiaId],
        roles_by_academy: { [academiaId]: ['Admin'] },
        email_canonical: email,
        academiaId,
        usuarioId,
        colecao: 'usuarios',
        perfil: 'Admin',
        nome: req.nome,
        email,
        perfis: [profileRef],
      });
      await batch.commit();

      await this.popularModalidadesDefault(academiaId);

      const storedUser: StoredUser = {
        id: usuarioId,
        nome: req.nome,
        email,
        perfil: 'Admin',
        academiaId,
        permissoes: permissoesParaPerfil('Admin'),
        perfis: [profileRef],
        mustChangePassword: false,
      };
      this.salvarNoStorage(storedUser);
      return storedUser;
    } catch (erro) {
      await credential.user.delete().catch(() => {});
      throw erro;
    }
  }

  /** Espelho de `firestore_service.dart::popularModalidadesDefault` — mesmos dados em `academia-seeds.ts`. */
  private async popularModalidadesDefault(academiaId: string): Promise<void> {
    for (const modalidade of MODALIDADES_DEFAULT) {
      const modRef = await addDoc(collection(db, 'academias', academiaId, 'modalidades'), {
        nome: modalidade.nome,
        cor: modalidade.cor,
        ativo: true,
        criado_em: serverTimestamp(),
      });
      for (const faixa of modalidade.faixas) {
        await addDoc(collection(db, 'academias', academiaId, 'faixas'), {
          modalidadeId: modRef.id,
          nome: faixa.nome,
          cor: faixa.cor,
          ordem: faixa.ordem,
          tem_graus: faixa.tem_graus,
          max_graus: faixa.max_graus,
          criado_em: serverTimestamp(),
        });
      }
    }
  }

  /** Espelho do fluxo "academia/funcionário" em `esqueci_senha_screen.dart::_enviarLinkEmail` — link do Firebase, sem tela de reset própria (o próprio Firebase cuida disso fora do app). */
  async enviarLinkRedefinicaoSenha(email: string): Promise<void> {
    await sendPasswordResetEmail(auth, email.trim().toLowerCase());
  }
}
