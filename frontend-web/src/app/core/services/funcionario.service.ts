import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { collection, doc, getDoc, getDocs, addDoc, updateDoc, query, where, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/firebase';
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
        temAcesso: !!f['firebaseUid'],
        senhaTemporaria: String(f['acesso_senha_temporaria'] ?? '').trim() || undefined,
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
   * Mesmos campos de `equipe_criar_screen.dart`. O acesso (senha
   * temporária) é gerado em seguida pela tela, com `AcessoService`.
   */
  create(data: CreateFuncionarioRequest): Observable<BaseResponse<FuncionarioListaDto>> {
    const academiaId = this.academiaId;
    const payload = {
      nome: data.nome.trim(),
      email: data.email?.trim().toLowerCase() || null,
      telefone: data.telefone,
      telefone_digits: data.telefone?.replace(/\D/g, '') ?? '',
      cargo: data.cargo?.trim() || data.perfil,
      perfil: data.perfil,
      perfil_nome: data.perfil,
      permissoes: data.perfil === 'Admin' ? {} : (data.permissoes ?? {}),
      ativo: true,
      criado_em: serverTimestamp(),
    };
    return from(addDoc(collection(db, 'academias', academiaId, 'funcionarios'), payload)).pipe(
      map(({ id }) =>
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

  /** Só o status: regravar o cadastro inteiro apagava telefone e permissões. */
  definirAtivo(id: string, ativo: boolean): Observable<BaseResponse<void>> {
    const ref = doc(db, 'academias', this.academiaId, 'funcionarios', id);
    return from(updateDoc(ref, { ativo, atualizado_em: serverTimestamp() })).pipe(map(() => ok(undefined)));
  }

  /** Soft-delete (desativa), igual o mobile — nunca apaga o doc do funcionário. */
  delete(id: string): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    return from(updateDoc(doc(db, 'academias', academiaId, 'funcionarios', id), { ativo: false, atualizado_em: serverTimestamp() })).pipe(
      map(() => ok(undefined)),
    );
  }
}
