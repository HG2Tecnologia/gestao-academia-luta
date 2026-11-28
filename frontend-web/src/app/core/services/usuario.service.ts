import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { DocumentSnapshot, doc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
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
 * "Meu perfil" (a pessoa logada editando os próprios dados). O documento
 * fica em `academias/{id}/funcionarios/{id}` pra quem foi cadastrado como
 * funcionário, mas em `academias/{id}/usuarios/{id}` pro Admin criado no
 * cadastro da academia. Lista de professores foi removida daqui: já existe em
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

  /** Procura em `funcionarios` e, se não existir lá, em `usuarios`. */
  private async carregarDocDoPerfil(): Promise<DocumentSnapshot> {
    const academiaId = this.academiaId;
    const userId = this.authService.currentUser()?.id ?? '';
    const funcionario = await getDoc(doc(db, 'academias', academiaId, 'funcionarios', userId));
    if (funcionario.exists()) return funcionario;
    return getDoc(doc(db, 'academias', academiaId, 'usuarios', userId));
  }

  getMeuPerfil(): Observable<ApiResponse<MeuPerfilDto>> {
    return from(this.carregarDocDoPerfil()).pipe(
      map((snap) => {
        const f = snap.data() ?? {};
        const atual = this.authService.currentUser();
        return {
          sucesso: true,
          dados: {
            id: snap.id,
            nome: f['nome'] ?? '',
            email: f['email'] ?? atual?.email,
            telefone: f['telefone'] ?? undefined,
            // Em `usuarios` o campo `perfil` é numérico — o nome do perfil vem da sessão.
            perfil: atual?.perfil ?? '',
          },
        };
      }),
    );
  }

  atualizarMeuPerfil(data: { nome: string; telefone?: string }): Observable<ApiResponse<MeuPerfilDto>> {
    const userId = this.authService.currentUser()?.id ?? '';
    const payload = {
      nome: data.nome,
      telefone: data.telefone ?? null,
      telefone_digits: data.telefone?.replace(/\D/g, '') ?? '',
      atualizado_em: serverTimestamp(),
    };
    return from(this.carregarDocDoPerfil().then((snap) => updateDoc(snap.ref, payload))).pipe(
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
