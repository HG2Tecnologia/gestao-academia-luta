import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { collection, doc, getDoc, getDocs, addDoc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import { ModeloContratoDto, CreateModeloContratoRequest, UpdateModeloContratoRequest } from '../models/contrato.model';

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/** Espelho de `academias/{id}/modelos_contrato` em `mobile/lib/core/firestore_service.dart` — mesma coleção real, com UI própria no mobile (`modelos_contrato_screen.dart`). */
@Injectable({ providedIn: 'root' })
export class ModeloContratoService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  listar(): Observable<BaseResponse<ModeloContratoDto[]>> {
    const academiaId = this.academiaId;
    return from(getDocs(collection(db, 'academias', academiaId, 'modelos_contrato'))).pipe(
      map((snap) => {
        const lista = snap.docs.map((d) => this.toDto(d.id, d.data()));
        lista.sort((a, b) => b.criadoEm.localeCompare(a.criadoEm));
        return ok(lista);
      }),
    );
  }

  obter(id: string): Observable<BaseResponse<ModeloContratoDto>> {
    const academiaId = this.academiaId;
    return from(getDoc(doc(db, 'academias', academiaId, 'modelos_contrato', id))).pipe(
      map((snap) => ok(this.toDto(snap.id, snap.data() ?? {}))),
    );
  }

  criar(data: CreateModeloContratoRequest): Observable<BaseResponse<ModeloContratoDto>> {
    const academiaId = this.academiaId;
    const payload = { nome: data.nome, conteudoHtml: data.conteudoHtml, criado_em: serverTimestamp() };
    return from(addDoc(collection(db, 'academias', academiaId, 'modelos_contrato'), payload)).pipe(
      map((ref) => ok<ModeloContratoDto>({ id: ref.id, nome: data.nome, conteudoHtml: data.conteudoHtml, criadoEm: new Date().toISOString() })),
    );
  }

  atualizar(id: string, data: UpdateModeloContratoRequest): Observable<BaseResponse<ModeloContratoDto>> {
    const academiaId = this.academiaId;
    const payload = { nome: data.nome, conteudoHtml: data.conteudoHtml, atualizado_em: serverTimestamp() };
    return from(updateDoc(doc(db, 'academias', academiaId, 'modelos_contrato', id), payload)).pipe(
      map(() => ok<ModeloContratoDto>({ id, nome: data.nome, conteudoHtml: data.conteudoHtml, criadoEm: '' })),
    );
  }

  excluir(id: string): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    return from(deleteDoc(doc(db, 'academias', academiaId, 'modelos_contrato', id))).pipe(map(() => ok(undefined)));
  }

  private toDto(id: string, m: Record<string, any>): ModeloContratoDto {
    return {
      id,
      nome: m['nome'] ?? '',
      conteudoHtml: m['conteudoHtml'] ?? '',
      criadoEm: m['criado_em']?.toDate?.()?.toISOString?.() ?? '',
    };
  }
}
