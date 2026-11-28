import { Injectable, inject } from '@angular/core';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';

export type TipoLimitePlano = 'turma' | 'aluno' | 'funcionario';

/**
 * Mesmos limites de `mobile/lib/core/plan_limits.dart` e de
 * `dentroDoLimiteGratuito` nas Firestore rules — mudou em um, mude nos três.
 */
const LIMITES: Record<TipoLimitePlano, { campo: string; limite: number; descricao: string }> = {
  turma: { campo: 'turmas_ativas_contagem', limite: 1, descricao: '1 turma ativa' },
  aluno: { campo: 'alunos_ativos_contagem', limite: 5, descricao: '5 alunos ativos' },
  funcionario: { campo: 'funcionarios_contagem', limite: 1, descricao: '1 funcionário' },
};

@Injectable({ providedIn: 'root' })
export class PlanoLimiteService {
  private readonly authService = inject(FirebaseAuthService);

  /**
   * Explica uma gravação recusada pelo limite do plano gratuito — as rules só
   * devolvem `permission-denied`, sem dizer o motivo. Devolve `null` quando a
   * falha foi por outra coisa, pra tela manter a mensagem genérica. A trava de
   * verdade continua sendo no servidor; isto só escolhe o texto.
   */
  async mensagemSeAtingido(erro: unknown, tipo: TipoLimitePlano): Promise<string | null> {
    if ((erro as { code?: string } | null)?.code !== 'permission-denied') return null;

    const user = this.authService.currentUser();
    // Pra outros perfis a recusa é falta de permissão, não limite do plano.
    if (!user?.academiaId || !['Admin', 'Secretaria'].includes(user.perfil)) return null;

    try {
      const academia = (await getDoc(doc(db, 'academias', user.academiaId))).data();
      if (!academia || (academia['plano_tipo'] ?? 0) >= 1) return null;
      const { campo, limite, descricao } = LIMITES[tipo];
      if ((academia[campo] ?? 0) < limite) return null;
      return `Limite do plano gratuito atingido: ${descricao}. Para cadastrar mais, faça o upgrade para o PRO.`;
    } catch {
      return null;
    }
  }
}
