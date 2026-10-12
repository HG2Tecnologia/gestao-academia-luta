import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { collection, doc, getDoc, getDocs, addDoc, updateDoc, deleteDoc, query, where, serverTimestamp, deleteField } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';

export interface MembroDto {
  id: string;
  nome: string;
  email?: string;
  perfil: string;
}

export interface GrupoFamiliarDto {
  id: string;
  nome: string;
  criadoEm: string;
  membros: MembroDto[];
}

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/**
 * Espelho de `academias/{id}/grupos_familiares` em
 * `mobile/lib/core/firestore_service.dart`. O doc do grupo guarda um
 * array `membros` só como cache de exibição, mas a fonte de verdade
 * do vínculo (confirmada no próprio comentário do mobile) é o campo
 * `grupo_familiar_id` no doc de cada aluno em `usuarios/{id}` — por
 * isso toda leitura de membros aqui consulta `usuarios` por esse
 * campo, em vez de confiar só no array (que pode ficar desatualizado).
 */
@Injectable({ providedIn: 'root' })
export class GruposFamiliaresService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  private async carregarMembros(academiaId: string, grupoId: string): Promise<MembroDto[]> {
    const snap = await getDocs(
      query(collection(db, 'academias', academiaId, 'usuarios'), where('grupo_familiar_id', '==', grupoId), where('perfil', '==', 3)),
    );
    return snap.docs.map((d) => {
      const u = d.data();
      return { id: d.id, nome: u['nome'] ?? '', email: u['email'] ?? undefined, perfil: 'Aluno' } as MembroDto;
    });
  }

  listar(): Observable<BaseResponse<GrupoFamiliarDto[]>> {
    const academiaId = this.academiaId;
    return from(this.carregarTodos(academiaId)).pipe(map((lista) => ok(lista)));
  }

  private async carregarTodos(academiaId: string): Promise<GrupoFamiliarDto[]> {
    const snap = await getDocs(collection(db, 'academias', academiaId, 'grupos_familiares'));
    const lista = await Promise.all(
      snap.docs.map(async (d) => {
        const g = d.data();
        const membros = await this.carregarMembros(academiaId, d.id);
        return {
          id: d.id,
          nome: g['nome'] ?? '',
          criadoEm: g['criado_em']?.toDate?.()?.toISOString?.() ?? '',
          membros,
        } as GrupoFamiliarDto;
      }),
    );
    lista.sort((a, b) => a.nome.localeCompare(b.nome, 'pt-BR'));
    return lista;
  }

  criar(nome: string): Observable<BaseResponse<GrupoFamiliarDto>> {
    const academiaId = this.academiaId;
    const payload = { nome, membros: [], criado_em: serverTimestamp() };
    return from(addDoc(collection(db, 'academias', academiaId, 'grupos_familiares'), payload)).pipe(
      map((ref) => ok<GrupoFamiliarDto>({ id: ref.id, nome, criadoEm: new Date().toISOString(), membros: [] })),
    );
  }

  renomear(id: string, nome: string): Observable<BaseResponse<GrupoFamiliarDto>> {
    const academiaId = this.academiaId;
    return from(updateDoc(doc(db, 'academias', academiaId, 'grupos_familiares', id), { nome })).pipe(
      map(() => ok<GrupoFamiliarDto>({ id, nome, criadoEm: '', membros: [] })),
    );
  }

  excluir(id: string): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    return from(this.excluirComMembros(academiaId, id)).pipe(map(() => ok(undefined)));
  }

  private async excluirComMembros(academiaId: string, grupoId: string): Promise<void> {
    const membros = await this.carregarMembros(academiaId, grupoId);
    await Promise.all(membros.map((m) => updateDoc(doc(db, 'academias', academiaId, 'usuarios', m.id), { grupo_familiar_id: deleteField() })));
    await deleteDoc(doc(db, 'academias', academiaId, 'grupos_familiares', grupoId));
  }

  adicionarMembro(grupoId: string, alunoId: string): Observable<BaseResponse<GrupoFamiliarDto>> {
    const academiaId = this.academiaId;
    return from(this.vincular(academiaId, grupoId, alunoId)).pipe(map((dto) => ok(dto)));
  }

  private async vincular(academiaId: string, grupoId: string, alunoId: string): Promise<GrupoFamiliarDto> {
    await updateDoc(doc(db, 'academias', academiaId, 'usuarios', alunoId), { grupo_familiar_id: grupoId });
    const [grupoSnap, membros] = await Promise.all([
      getDoc(doc(db, 'academias', academiaId, 'grupos_familiares', grupoId)),
      this.carregarMembros(academiaId, grupoId),
    ]);
    await updateDoc(doc(db, 'academias', academiaId, 'grupos_familiares', grupoId), {
      membros: membros.map((m) => ({ id: m.id, nome: m.nome })),
    });
    const g = grupoSnap.data() ?? {};
    return { id: grupoId, nome: g['nome'] ?? '', criadoEm: g['criado_em']?.toDate?.()?.toISOString?.() ?? '', membros };
  }

  obterPorAluno(alunoId: string): Observable<BaseResponse<GrupoFamiliarDto | null>> {
    const academiaId = this.academiaId;
    return from(this.carregarDoAluno(academiaId, alunoId)).pipe(map((dto) => ok(dto)));
  }

  private async carregarDoAluno(academiaId: string, alunoId: string): Promise<GrupoFamiliarDto | null> {
    const alunoSnap = await getDoc(doc(db, 'academias', academiaId, 'usuarios', alunoId));
    const grupoId = alunoSnap.data()?.['grupo_familiar_id'];
    if (!grupoId) return null;

    const [grupoSnap, membros] = await Promise.all([
      getDoc(doc(db, 'academias', academiaId, 'grupos_familiares', grupoId)),
      this.carregarMembros(academiaId, grupoId),
    ]);
    if (!grupoSnap.exists()) return null;
    const g = grupoSnap.data();
    return { id: grupoId, nome: g['nome'] ?? '', criadoEm: g['criado_em']?.toDate?.()?.toISOString?.() ?? '', membros };
  }

  removerMembro(grupoId: string, membroId: string): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    return from(this.desvincular(academiaId, grupoId, membroId)).pipe(map(() => ok(undefined)));
  }

  private async desvincular(academiaId: string, grupoId: string, membroId: string): Promise<void> {
    await updateDoc(doc(db, 'academias', academiaId, 'usuarios', membroId), { grupo_familiar_id: deleteField() });
    const membros = await this.carregarMembros(academiaId, grupoId);
    await updateDoc(doc(db, 'academias', academiaId, 'grupos_familiares', grupoId), {
      membros: membros.map((m) => ({ id: m.id, nome: m.nome })),
    });
  }
}
