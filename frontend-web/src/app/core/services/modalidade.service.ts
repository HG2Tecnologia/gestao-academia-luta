import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { collection, doc, getDoc, getDocs, addDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import { MODALIDADES_DEFAULT } from '../data/academia-seeds';

export interface ModalidadeDto {
  id: string;
  nome: string;
  cor?: string;
  descricao?: string;
  ativo: boolean;
}

export interface CreateModalidadeRequest {
  nome: string;
  cor?: string;
  descricao?: string;
  ativo?: boolean;
}

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/** Espelho de `academias/{id}/modalidades` em `mobile/lib/core/firestore_service.dart`. */
@Injectable({ providedIn: 'root' })
export class ModalidadeService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  private dto(id: string, m: Record<string, any>): ModalidadeDto {
    return {
      id,
      nome: m['nome'] ?? '',
      cor: m['cor'] ?? undefined,
      descricao: m['descricao'] ?? undefined,
      ativo: m['ativo'] === true,
    };
  }

  getAll(): Observable<BaseResponse<ModalidadeDto[]>> {
    const academiaId = this.academiaId;
    return from(getDocs(collection(db, 'academias', academiaId, 'modalidades'))).pipe(
      map((snap) => {
        const lista = snap.docs.map((d) => this.dto(d.id, d.data()));
        lista.sort((a, b) => a.nome.localeCompare(b.nome, 'pt-BR'));
        return ok(lista);
      }),
    );
  }

  getById(id: string): Observable<BaseResponse<ModalidadeDto>> {
    const academiaId = this.academiaId;
    return from(getDoc(doc(db, 'academias', academiaId, 'modalidades', id))).pipe(
      map((snap) => ok(this.dto(snap.id, snap.data() ?? {}))),
    );
  }

  create(data: CreateModalidadeRequest): Observable<BaseResponse<ModalidadeDto>> {
    const academiaId = this.academiaId;
    const payload = {
      nome: data.nome,
      cor: data.cor ?? null,
      descricao: data.descricao ?? null,
      ativo: true,
      criado_em: serverTimestamp(),
    };
    return from(addDoc(collection(db, 'academias', academiaId, 'modalidades'), payload)).pipe(
      map((ref) => ok<ModalidadeDto>({ id: ref.id, nome: data.nome, cor: data.cor, descricao: data.descricao, ativo: true })),
    );
  }

  update(id: string, data: CreateModalidadeRequest & { ativo: boolean }): Observable<BaseResponse<ModalidadeDto>> {
    const academiaId = this.academiaId;
    const payload = {
      nome: data.nome,
      cor: data.cor ?? null,
      descricao: data.descricao ?? null,
      ativo: data.ativo,
      atualizado_em: serverTimestamp(),
    };
    return from(updateDoc(doc(db, 'academias', academiaId, 'modalidades', id), payload)).pipe(
      map(() => ok<ModalidadeDto>({ id, ...data })),
    );
  }

  /** Soft-delete, igual o mobile — nunca apaga o doc (turmas/faixas continuam referenciando o id). */
  delete(id: string): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    return from(updateDoc(doc(db, 'academias', academiaId, 'modalidades', id), { ativo: false, atualizado_em: serverTimestamp() })).pipe(
      map(() => ok(undefined)),
    );
  }

  /**
   * Espelho de `FirestoreService.seedModalidadesDefault` no mobile — só
   * roda se a academia ainda não tiver NENHUMA modalidade cadastrada
   * (idempotente, nunca duplica ao clicar de novo).
   */
  seed(): Observable<{ sucesso: boolean; mensagem: string }> {
    return from(this.seedModalidadesDefault()).pipe(map((mensagem) => ({ sucesso: true, mensagem })));
  }

  private async seedModalidadesDefault(): Promise<string> {
    const academiaId = this.academiaId;
    const existentes = await getDocs(collection(db, 'academias', academiaId, 'modalidades'));
    if (!existentes.empty) return 'A academia já tem modalidades cadastradas.';

    for (const mod of MODALIDADES_DEFAULT) {
      const modRef = await addDoc(collection(db, 'academias', academiaId, 'modalidades'), {
        nome: mod.nome,
        cor: mod.cor,
        ativo: true,
        criado_em: serverTimestamp(),
      });
      for (const f of mod.faixas) {
        await addDoc(collection(db, 'academias', academiaId, 'faixas'), {
          modalidadeId: modRef.id,
          nome: f.nome,
          cor: f.cor,
          ordem: f.ordem,
          tem_graus: f.tem_graus,
          max_graus: f.max_graus,
          criado_em: serverTimestamp(),
        });
      }
    }
    return 'Modalidades padrão criadas com sucesso.';
  }
}
