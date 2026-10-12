import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { doc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';

interface ApiResponse<T> { sucesso: boolean; mensagem?: string; dados?: T; }

export interface MeuPerfilDto {
  id: string;
  nome: string;
  email?: string;
  telefone?: string;
  perfil: string;
}

/**
 * "Meu perfil" (o funcionário logado editando os próprios dados) —
 * espelho de `academias/{id}/funcionarios/{uid}`, mesmo doc que
 * `FuncionarioService` gerencia pra outros funcionários. Lista de
 * professores foi removida daqui: já existe em
 * `FuncionarioService.getProfessores()`, sem sentido duplicar a
 * mesma query em dois services.
 */
@Injectable({ providedIn: 'root' })
export class UsuarioService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  getMeuPerfil(): Observable<ApiResponse<MeuPerfilDto>> {
    const academiaId = this.academiaId;
    const userId = this.authService.currentUser()?.id ?? '';
    return from(getDoc(doc(db, 'academias', academiaId, 'funcionarios', userId))).pipe(
      map((snap) => {
        const f = snap.data() ?? {};
        return {
          sucesso: true,
          dados: {
            id: snap.id,
            nome: f['nome'] ?? '',
            email: f['email'] ?? undefined,
            telefone: f['telefone'] ?? undefined,
            perfil: f['perfil'] ?? f['perfil_nome'] ?? '',
          },
        };
      }),
    );
  }

  atualizarMeuPerfil(data: { nome: string; telefone?: string }): Observable<ApiResponse<MeuPerfilDto>> {
    const academiaId = this.academiaId;
    const userId = this.authService.currentUser()?.id ?? '';
    const payload = {
      nome: data.nome,
      telefone: data.telefone ?? null,
      telefone_digits: data.telefone?.replace(/\D/g, '') ?? '',
      atualizado_em: serverTimestamp(),
    };
    return from(updateDoc(doc(db, 'academias', academiaId, 'funcionarios', userId), payload)).pipe(
      map(() => {
        this.authService.atualizarPerfilLocal({ nome: data.nome });
        const atual = this.authService.currentUser();
        return {
          sucesso: true,
          dados: { id: userId, nome: data.nome, email: atual?.email, telefone: data.telefone, perfil: atual?.perfil ?? '' },
        };
      }),
    );
  }
}
