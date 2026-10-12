import { Injectable, inject } from '@angular/core';
import { Observable, from, map, throwError } from 'rxjs';
import { collection, doc, getDoc, getDocs, setDoc, deleteDoc, addDoc, query, where, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import { statusEfetivo } from '../utils/pagamento-status.util';

export interface CatracaValidacaoDto {
  permitido: boolean;
  nomeAluno: string | null;
  motivo: string | null;
  presencaRegistrada: boolean;
  turmaNome: string | null;
}

export interface CatracaAberturaDto {
  aberta: boolean;
  abertaEm: string;
  operadorNome: string;
}

export interface CatracaAlunoVinculoDto {
  alunoId: string;
  nomeAluno: string;
  email: string | null;
  deviceUserId: number | null;
  vinculado: boolean;
}

export interface CatracaAgentConfigDto {
  /** Antes era a URL do backend C#; agora o agente fala direto com o Firestore, sem backend HTTP. */
  backendUrl: string;
  apiKey: string;
  academiaId: string;
  toletusCatracaIp: string;
}

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/**
 * Feature exclusiva do CRM — não existe equivalente no app mobile
 * (nenhum aluno/professor interage com catraca física pelo celular).
 * Antes falava com o backend C# morto (que por sua vez empurrava
 * comandos ao agente local via SignalR). Agora:
 *
 * - Vínculos, config e histórico são Firestore puro, mesmo padrão do
 *   resto do CRM.
 * - Como não existe push HTTP pro agente local (ele roda isolado no PC
 *   da academia, atrás de NAT, sem endereço público), os comandos
 *   (`abrir porta`, `cadastrar/remover usuário no Toletus`) são
 *   gravados como documentos em `catraca_comandos`; o agente local
 *   escuta essa coleção via `onSnapshot` (substitui o Hub SignalR) e
 *   marca `processado: true` ao executar. Esse é o lado que exige
 *   reescrever `backend/src/AcademiaFight.CatracaAgent` pra usar o
 *   client .NET do Firestore em vez de SignalR — fora do escopo deste
 *   arquivo Angular, tratado separadamente.
 */
@Injectable({ providedIn: 'root' })
export class CatracaService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  // ── Validação manual (busca por nome/e-mail/ID do dispositivo) ────

  validar(identificador: string): Observable<BaseResponse<CatracaValidacaoDto>> {
    const academiaId = this.academiaId;
    return from(this.validarAcesso(academiaId, identificador)).pipe(map((dto) => ok(dto)));
  }

  private async validarAcesso(academiaId: string, identificador: string): Promise<CatracaValidacaoDto> {
    const termo = identificador.trim();
    let alunoId: string | null = null;

    if (/^\d+$/.test(termo)) {
      const vinculoSnap = await getDocs(
        query(collection(db, 'academias', academiaId, 'catraca_vinculos'), where('device_user_id', '==', Number(termo))),
      );
      if (!vinculoSnap.empty) alunoId = vinculoSnap.docs[0].id;
    }

    if (!alunoId) {
      const usuariosSnap = await getDocs(query(collection(db, 'academias', academiaId, 'usuarios'), where('perfil', '==', 3)));
      const termoLower = termo.toLowerCase();
      const encontrado = usuariosSnap.docs.find((d) => {
        const u = d.data();
        return String(u['nome'] ?? '').toLowerCase().includes(termoLower) || String(u['email'] ?? '').toLowerCase() === termoLower;
      });
      if (encontrado) alunoId = encontrado.id;
    }

    if (!alunoId) {
      return { permitido: false, nomeAluno: null, motivo: 'Aluno não encontrado.', presencaRegistrada: false, turmaNome: null };
    }

    const alunoSnap = await getDoc(doc(db, 'academias', academiaId, 'usuarios', alunoId));
    const aluno = alunoSnap.data() ?? {};
    const nomeAluno = aluno['nome'] ?? null;

    if (aluno['ativo'] === false) {
      return { permitido: false, nomeAluno, motivo: 'Aluno inativo.', presencaRegistrada: false, turmaNome: null };
    }

    const academiaSnap = await getDoc(doc(db, 'academias', academiaId));
    const cfg = academiaSnap.data() ?? {};
    if (cfg['bloqueio_checkin_ativo'] === true) {
      const carenciaDias = cfg['bloqueio_checkin_carencia_dias'] ?? 0;
      const pagamentosSnap = await getDocs(query(collection(db, 'academias', academiaId, 'pagamentos'), where('aluno_id', '==', alunoId)));
      const hoje = Date.now();
      const bloqueado = pagamentosSnap.docs.some((d) => {
        const p = d.data();
        if (statusEfetivo(p['status'], p['data_vencimento']) !== 'Atrasado') return false;
        const vencimento = new Date(`${p['data_vencimento']}T00:00:00`).getTime();
        const diasAtraso = Math.floor((hoje - vencimento) / 86400000);
        return diasAtraso > carenciaDias;
      });
      if (bloqueado) {
        return { permitido: false, nomeAluno, motivo: 'Pagamento em atraso além da carência.', presencaRegistrada: false, turmaNome: null };
      }
    }

    return { permitido: true, nomeAluno, motivo: null, presencaRegistrada: false, turmaNome: null };
  }

  // ── Abertura manual ─────────────────────────────────────────────

  abrirManualmente(): Observable<BaseResponse<CatracaAberturaDto>> {
    const academiaId = this.academiaId;
    const operadorNome = this.authService.currentUser()?.nome ?? 'Operador';
    return from(
      addDoc(collection(db, 'academias', academiaId, 'catraca_comandos'), {
        tipo: 'abrir_porta',
        processado: false,
        operador_nome: operadorNome,
        criado_em: serverTimestamp(),
      }),
    ).pipe(
      map(() => ok<CatracaAberturaDto>({ aberta: true, abertaEm: new Date().toISOString(), operadorNome })),
    );
  }

  // ── Vínculos ────────────────────────────────────────────────────

  listarVinculos(): Observable<BaseResponse<CatracaAlunoVinculoDto[]>> {
    const academiaId = this.academiaId;
    return from(this.carregarVinculos(academiaId)).pipe(map((lista) => ok(lista)));
  }

  private async carregarVinculos(academiaId: string): Promise<CatracaAlunoVinculoDto[]> {
    const [usuariosSnap, vinculosSnap] = await Promise.all([
      getDocs(query(collection(db, 'academias', academiaId, 'usuarios'), where('perfil', '==', 3), where('ativo', '==', true))),
      getDocs(collection(db, 'academias', academiaId, 'catraca_vinculos')),
    ]);
    const vinculoPorAluno = new Map<string, number>();
    vinculosSnap.forEach((d) => vinculoPorAluno.set(d.id, d.data()['device_user_id'] ?? null));

    const lista = usuariosSnap.docs.map((d) => {
      const a = d.data();
      const deviceUserId = vinculoPorAluno.get(d.id) ?? null;
      return {
        alunoId: d.id,
        nomeAluno: a['nome'] ?? '',
        email: a['email'] ?? null,
        deviceUserId,
        vinculado: deviceUserId !== null,
      } as CatracaAlunoVinculoDto;
    });
    lista.sort((a, b) => a.nomeAluno.localeCompare(b.nomeAluno, 'pt-BR'));
    return lista;
  }

  vincularAluno(alunoId: string): Observable<BaseResponse<CatracaAlunoVinculoDto>> {
    const academiaId = this.academiaId;
    return from(this.criarVinculo(academiaId, alunoId)).pipe(map((dto) => ok(dto)));
  }

  private async criarVinculo(academiaId: string, alunoId: string): Promise<CatracaAlunoVinculoDto> {
    const [vinculosSnap, alunoSnap] = await Promise.all([
      getDocs(collection(db, 'academias', academiaId, 'catraca_vinculos')),
      getDoc(doc(db, 'academias', academiaId, 'usuarios', alunoId)),
    ]);
    const maiorId = vinculosSnap.docs.reduce((max, d) => Math.max(max, d.data()['device_user_id'] ?? 0), 0);
    const deviceUserId = maiorId + 1;

    await setDoc(doc(db, 'academias', academiaId, 'catraca_vinculos', alunoId), {
      device_user_id: deviceUserId,
      criado_em: serverTimestamp(),
    });
    await addDoc(collection(db, 'academias', academiaId, 'catraca_comandos'), {
      tipo: 'cadastrar_usuario',
      device_user_id: deviceUserId,
      aluno_id: alunoId,
      processado: false,
      criado_em: serverTimestamp(),
    });

    const aluno = alunoSnap.data() ?? {};
    return { alunoId, nomeAluno: aluno['nome'] ?? '', email: aluno['email'] ?? null, deviceUserId, vinculado: true };
  }

  desvincularAluno(alunoId: string): Observable<BaseResponse<boolean>> {
    const academiaId = this.academiaId;
    return from(this.removerVinculo(academiaId, alunoId)).pipe(map(() => ok(true)));
  }

  private async removerVinculo(academiaId: string, alunoId: string): Promise<void> {
    const vinculoRef = doc(db, 'academias', academiaId, 'catraca_vinculos', alunoId);
    const vinculoSnap = await getDoc(vinculoRef);
    const deviceUserId = vinculoSnap.data()?.['device_user_id'];
    await deleteDoc(vinculoRef);
    if (deviceUserId != null) {
      await addDoc(collection(db, 'academias', academiaId, 'catraca_comandos'), {
        tipo: 'remover_usuario',
        device_user_id: deviceUserId,
        aluno_id: alunoId,
        processado: false,
        criado_em: serverTimestamp(),
      });
    }
  }

  // ── Agente local ────────────────────────────────────────────────

  /** Lê (ou cria, na primeira vez) a config que o agente local precisa pra se conectar direto no Firestore desta academia. */
  getAgentConfig(): Observable<CatracaAgentConfigDto> {
    const academiaId = this.academiaId;
    return from(this.resolverConfig(academiaId));
  }

  private async resolverConfig(academiaId: string): Promise<CatracaAgentConfigDto> {
    const ref = doc(db, 'academias', academiaId, 'catraca_config', 'config');
    const snap = await getDoc(ref);
    if (snap.exists()) {
      const c = snap.data();
      return {
        backendUrl: 'firestore',
        apiKey: c['api_key'] ?? '',
        academiaId,
        toletusCatracaIp: c['toletus_ip'] ?? '169.254.37.21',
      };
    }
    const apiKey = crypto.randomUUID();
    const toletusCatracaIp = '169.254.37.21';
    await setDoc(ref, { api_key: apiKey, toletus_ip: toletusCatracaIp, criado_em: serverTimestamp() });
    return { backendUrl: 'firestore', apiKey, academiaId, toletusCatracaIp };
  }

  /**
   * Não existe mais backend pra gerar/servir esse pacote (era o
   * Render) — até decidirmos onde hospedar o executável compilado do
   * agente (Firebase Hosting, GitHub Releases etc.), este método
   * mantém o mesmo contrato de erro que a tela já trata ("ainda não
   * disponível"), em vez de fingir sucesso.
   */
  downloadAgentPacote(): Observable<Blob> {
    return throwError(() => new Error('Pacote do agente ainda não hospedado — defina onde publicar o executável.'));
  }
}
