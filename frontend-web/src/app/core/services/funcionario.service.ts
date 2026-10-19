import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { collection, doc, getDoc, getDocs, addDoc, updateDoc, query, where, serverTimestamp } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { db, functions } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import { FuncionarioListaDto, CreateFuncionarioRequest, UpdateFuncionarioRequest } from '../models/funcionario.model';
import { UsuarioResumoDto } from '../models/usuario.model';

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/**
 * Espelho de `academias/{id}/funcionarios` em
 * `mobile/lib/screens/admin/equipe_criar_screen.dart`. Perfis reais:
 * Admin, Professor, Secretaria (nunca "Recepcionista" — isso só existia
 * no C#, nenhum lugar do app ou do Firestore usa esse nome).
 */
@Injectable({ providedIn: 'root' })
export class FuncionarioService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  private async carregarTodos(): Promise<FuncionarioListaDto[]> {
    const academiaId = this.academiaId;
    const [funcionariosSnap, turmasSnap] = await Promise.all([
      getDocs(collection(db, 'academias', academiaId, 'funcionarios')),
      getDocs(collection(db, 'academias', academiaId, 'turmas')),
    ]);
    const turmasPorProfessor = new Map<string, string[]>();
    turmasSnap.forEach((d) => {
      const professorId = d.data()['professorId'];
      if (!professorId) return;
      if (!turmasPorProfessor.has(professorId)) turmasPorProfessor.set(professorId, []);
      turmasPorProfessor.get(professorId)!.push(d.data()['nome'] ?? '');
    });

    return funcionariosSnap.docs.map((d) => {
      const f = d.data();
      const rawPerm = f['permissoes'];
      const dto: FuncionarioListaDto = {
        id: d.id,
        usuarioId: d.id,
        nome: f['nome'] ?? '',
        email: f['email'] ?? '',
        telefone: f['telefone'] ?? undefined,
        cargo: f['cargo'] ?? '',
        perfil: f['perfil'] ?? f['perfil_nome'] ?? 'Professor',
        turmasVinculadas: turmasPorProfessor.get(d.id) ?? [],
        ativo: f['ativo'] !== false,
        dataAdmissao: f['criado_em']?.toDate?.()?.toISOString?.() ?? '',
        permissoes: rawPerm && typeof rawPerm === 'object' ? rawPerm : {},
      };
      return dto;
    });
  }

  getAll(filtros?: { nome?: string; perfil?: string }): Observable<BaseResponse<FuncionarioListaDto[]>> {
    return from(this.carregarTodos()).pipe(
      map((lista) => {
        let filtrada = lista;
        if (filtros?.nome) {
          const q = filtros.nome.toLowerCase();
          filtrada = filtrada.filter((f) => f.nome.toLowerCase().includes(q));
        }
        if (filtros?.perfil) filtrada = filtrada.filter((f) => f.perfil === filtros.perfil);
        filtrada.sort((a, b) => a.nome.localeCompare(b.nome, 'pt-BR'));
        return ok(filtrada);
      }),
    );
  }

  getProfessores(): Observable<BaseResponse<UsuarioResumoDto[]>> {
    return from(this.carregarTodos()).pipe(
      map((lista) =>
        ok(
          lista
            .filter((f) => f.perfil === 'Professor' && f.ativo)
            .map((f) => ({ id: f.id, nome: f.nome, email: f.email } as UsuarioResumoDto)),
        ),
      ),
    );
  }

  getById(id: string): Observable<BaseResponse<FuncionarioListaDto>> {
    const academiaId = this.academiaId;
    return from(getDoc(doc(db, 'academias', academiaId, 'funcionarios', id))).pipe(
      map((snap) => {
        const f = snap.data() ?? {};
        const rawPerm = f['permissoes'];
        return ok<FuncionarioListaDto>({
          id: snap.id,
          usuarioId: snap.id,
          nome: f['nome'] ?? '',
          email: f['email'] ?? '',
          telefone: f['telefone'] ?? undefined,
          cargo: f['cargo'] ?? '',
          perfil: f['perfil'] ?? f['perfil_nome'] ?? 'Professor',
          turmasVinculadas: [],
          ativo: f['ativo'] !== false,
          dataAdmissao: f['criado_em']?.toDate?.()?.toISOString?.() ?? '',
          permissoes: rawPerm && typeof rawPerm === 'object' ? rawPerm : {},
        });
      }),
    );
  }

  /**
   * Cria o funcionário e, tendo telefone ou e-mail, já provisiona o
   * acesso ao app via `adminResetPassword` (mesma Cloud Function e mesmo
   * `motivo: 'provisao_criacao'` que o mobile usa em
   * `equipe_criar_screen.dart`) — sem isso a pessoa seria cadastrada mas
   * nunca conseguiria logar em lugar nenhum. Falha no provisionamento
   * nunca desfaz o cadastro (mesmo comportamento do mobile).
   */
  create(data: CreateFuncionarioRequest): Observable<BaseResponse<FuncionarioListaDto>> {
    const academiaId = this.academiaId;
    const payload = {
      nome: data.nome,
      email: data.email ?? null,
      telefone: data.telefone,
      telefone_digits: data.telefone?.replace(/\D/g, '') ?? '',
      cargo: data.cargo,
      perfil: data.perfil,
      perfil_nome: data.perfil,
      permissoes: data.perfil === 'Admin' ? {} : (data.permissoes ?? {}),
      ativo: true,
      criado_em: serverTimestamp(),
    };
    return from(this.criarEProvisionar(academiaId, payload)).pipe(
      map((id) =>
        ok<FuncionarioListaDto>({
          id,
          usuarioId: id,
          nome: data.nome,
          email: data.email ?? '',
          telefone: data.telefone,
          cargo: data.cargo,
          perfil: data.perfil,
          turmasVinculadas: [],
          ativo: true,
          dataAdmissao: new Date().toISOString(),
          permissoes: payload.permissoes,
        }),
      ),
    );
  }

  private async criarEProvisionar(academiaId: string, payload: Record<string, any>): Promise<string> {
    const ref = await addDoc(collection(db, 'academias', academiaId, 'funcionarios'), payload);
    if (payload['email'] || payload['telefone_digits']) {
      try {
        const adminResetPassword = httpsCallable(functions, 'adminResetPassword');
        await adminResetPassword({
          academiaId,
          colecao: 'funcionarios',
          usuarioId: ref.id,
          motivo: 'provisao_criacao',
        });
      } catch {
        // Mesmo comportamento do mobile: falha aqui não desfaz o cadastro.
      }
    }
    return ref.id;
  }

  update(id: string, data: UpdateFuncionarioRequest): Observable<BaseResponse<FuncionarioListaDto>> {
    const academiaId = this.academiaId;
    const payload = {
      nome: data.nome,
      email: data.email ?? null,
      telefone: data.telefone,
      telefone_digits: data.telefone?.replace(/\D/g, '') ?? '',
      cargo: data.cargo,
      perfil: data.perfil,
      perfil_nome: data.perfil,
      permissoes: data.perfil === 'Admin' ? {} : (data.permissoes ?? {}),
      ativo: data.ativo,
      atualizado_em: serverTimestamp(),
    };
    return from(updateDoc(doc(db, 'academias', academiaId, 'funcionarios', id), payload)).pipe(
      map(() =>
        ok<FuncionarioListaDto>({
          id,
          usuarioId: id,
          nome: data.nome,
          email: data.email ?? '',
          telefone: data.telefone,
          cargo: data.cargo,
          perfil: data.perfil,
          turmasVinculadas: [],
          ativo: data.ativo,
          dataAdmissao: '',
          permissoes: payload.permissoes,
        }),
      ),
    );
  }

  /** Soft-delete (desativa), igual o mobile — nunca apaga o doc do funcionário. */
  delete(id: string): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    return from(updateDoc(doc(db, 'academias', academiaId, 'funcionarios', id), { ativo: false, atualizado_em: serverTimestamp() })).pipe(
      map(() => ok(undefined)),
    );
  }
}
