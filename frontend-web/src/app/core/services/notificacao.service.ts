import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { collection, doc, getDocs, updateDoc, deleteDoc, query, where, writeBatch } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { NotificacaoDto } from '../models/notificacao.model';

interface ApiResponse<T> { sucesso: boolean; dados?: T; mensagem?: string; }

function ok<T>(dados: T): ApiResponse<T> {
  return { sucesso: true, dados };
}

/**
 * Espelho de `academias/{id}/notificacoes` em `mobile/lib/core/firestore_service.dart`.
 * É uma coleção ÚNICA e COMPARTILHADA pra toda a academia — não existe
 * `usuarios/{uid}/notificacoes`. A separação "pessoal do aluno" vs. "feed
 * da equipe" é feita só pela presença do campo `aluno_id`: docs com
 * `aluno_id` são notificações pessoais de um aluno (não aparecem aqui, já
 * que o CRM não tem login de aluno); os demais são o feed do staff
 * (Admin/Secretaria/Professor veem o mesmo feed, sem filtro por perfil —
 * confirmado: não existe ACL por perfil no mobile).
 *
 * O mobile NÃO usa `onSnapshot` pra notificações em lugar nenhum (confirmado
 * por investigação) — é tudo busca sob demanda (`.get()`) ao abrir a tela ou
 * no pull-to-refresh. Aqui replica o mesmo: sem listener em tempo real.
 */
@Injectable({ providedIn: 'root' })
export class NotificacaoService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  listar(): Observable<ApiResponse<NotificacaoDto[]>> {
    const academiaId = this.academiaId;
    return from(getDocs(collection(db, 'academias', academiaId, 'notificacoes'))).pipe(
      map((snap) => {
        const lista = snap.docs
          .filter((d) => d.data()['aluno_id'] == null)
          .map((d) => this.toDto(d.id, d.data()));
        lista.sort((a, b) => b.criadoEm.localeCompare(a.criadoEm));
        return ok(lista);
      }),
    );
  }

  private toDto(id: string, n: Record<string, any>): NotificacaoDto {
    return {
      id,
      titulo: n['titulo'] ?? '',
      mensagem: n['mensagem'] ?? '',
      tipo: n['tipo'] ?? 'info',
      lida: n['lida'] === true,
      criadoEm: n['criado_em']?.toDate?.()?.toISOString?.() ?? '',
      usuarioId: n['usuario_id'] ?? undefined,
    };
  }

  marcarLida(id: string): Observable<ApiResponse<void>> {
    const academiaId = this.academiaId;
    return from(updateDoc(doc(db, 'academias', academiaId, 'notificacoes', id), { lida: true })).pipe(map(() => ok(undefined)));
  }

  marcarTodasLidas(): Observable<ApiResponse<void>> {
    const academiaId = this.academiaId;
    return from(this.marcarTodas(academiaId)).pipe(map(() => ok(undefined)));
  }

  private async marcarTodas(academiaId: string): Promise<void> {
    const snap = await getDocs(
      query(collection(db, 'academias', academiaId, 'notificacoes'), where('lida', '==', false)),
    );
    const naoLidasDaEquipe = snap.docs.filter((d) => d.data()['aluno_id'] == null);
    if (naoLidasDaEquipe.length === 0) return;
    const batch = writeBatch(db);
    naoLidasDaEquipe.forEach((d) => batch.update(d.ref, { lida: true }));
    await batch.commit();
  }

  excluir(id: string): Observable<ApiResponse<void>> {
    const academiaId = this.academiaId;
    return from(deleteDoc(doc(db, 'academias', academiaId, 'notificacoes', id))).pipe(map(() => ok(undefined)));
  }
}
