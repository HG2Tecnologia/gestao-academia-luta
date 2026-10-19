import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { doc, getDoc, updateDoc } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import { AcademiaDto, UpdateAcademiaRequest } from '../models/academia.model';

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/**
 * Espelho do doc raiz `academias/{id}` em
 * `mobile/lib/screens/admin/configuracoes_screen.dart`. O doc mistura
 * snake_case (maioria dos campos) com um único camelCase (`logoUrl`,
 * que guarda a imagem em base64 inline, não uma URL de storage) —
 * mantido assim de propósito pra bater com o que o mobile já grava.
 * `update()` sempre usa `updateDoc` (nunca `set`), pra não sobrescrever
 * os campos de configuração avançada (bloqueio de check-in, limite de
 * dias/semana etc.) que esta tela do CRM ainda não edita.
 */
@Injectable({ providedIn: 'root' })
export class AcademiaService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  getCurrent(): Observable<BaseResponse<AcademiaDto>> {
    const academiaId = this.academiaId;
    return from(getDoc(doc(db, 'academias', academiaId))).pipe(
      map((snap) => {
        const a = snap.data() ?? {};
        return ok<AcademiaDto>({
          id: snap.id,
          nome: a['nome'] ?? '',
          subdominio: a['subdominio'] ?? '',
          logoUrl: a['logoUrl'] ?? undefined,
          email: a['email'] ?? '',
          telefone: a['telefone'] ?? undefined,
          cnpj: a['cnpj'] ?? undefined,
          ativo: a['ativo'] !== false,
          criadoEm: a['criado_em']?.toDate?.()?.toISOString?.() ?? '',
        });
      }),
    );
  }

  update(data: UpdateAcademiaRequest): Observable<BaseResponse<AcademiaDto>> {
    const academiaId = this.academiaId;
    const payload = {
      nome: data.nome,
      email: data.email,
      telefone: data.telefone ?? null,
      cnpj: data.cnpj ?? null,
    };
    return from(updateDoc(doc(db, 'academias', academiaId), payload)).pipe(
      map(() =>
        ok<AcademiaDto>({
          id: academiaId,
          nome: data.nome,
          subdominio: '',
          email: data.email,
          telefone: data.telefone,
          cnpj: data.cnpj,
          ativo: true,
          criadoEm: '',
        }),
      ),
    );
  }
}
