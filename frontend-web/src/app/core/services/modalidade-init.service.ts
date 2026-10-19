import { Injectable, inject } from '@angular/core';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';

const CHAVE_STORAGE = 'sm_modalidades_retry_v1';
const MAX_TENTATIVAS = 3;
const COOLDOWN_MS = 60 * 60 * 1000; // 1h entre tentativas automáticas — nunca fica tentando em loop

interface EstadoRetry {
  tentativas: number;
  ultimaTentativaEm: number;
}

/**
 * Decide SE vale a pena rechamar `inicializarModalidadesPadrao` e chama
 * com segurança. Não é dono da lógica de inicialização em si (isso é só
 * da Cloud Function, que já garante idempotência/concorrência sozinha,
 * independente de qualquer coisa salva no navegador — ver
 * `test:modalidades`, cenário "duas inicializações simultâneas", que
 * chama a function direto, sem passar por este service) — aqui é só o
 * lado "quando retomar automaticamente, sem virar loop de custo".
 *
 * Status que disparam retry automático: ausente ou `'pendente'`/`'erro'`
 * (a inicialização nunca rodou até o fim, ou rodou e falhou). Status que
 * NUNCA disparam retry automático: `'completo'` (nada a fazer) e
 * `'pendente_revisao'` (terminou de rodar, mas ficou uma ambiguidade que
 * só um humano resolve — rodar de novo não muda o resultado).
 *
 * O limite de 3 tentativas/1h é só pra evitar custo em loop dentro da
 * MESMA sessão (sessionStorage) — uma falha temporária (ex.: instabilidade
 * passageira da function) não fica bloqueada pra sempre: outra aba, outro
 * login, ou simplesmente fechar e reabrir o navegador já reseta o
 * contador. Além disso, `forcarAgora()` dá um caminho manual explícito
 * que ignora cooldown/limite — usado pelo botão "Tentar novamente" na
 * tela, pra quem não quiser esperar o reset automático.
 */
@Injectable({ providedIn: 'root' })
export class ModalidadeInitService {
  private readonly authService = inject(FirebaseAuthService);

  /** Lock em memória — evita 2 chamadas simultâneas disparadas pela mesma aba (ex.: dois componentes montando ao mesmo tempo). */
  private emAndamento = false;

  /** Lê o status atual direto do Firestore, sem decidir nada — usado pela UI pra saber o que mostrar. */
  async obterStatusAtual(academiaId: string): Promise<string | undefined> {
    try {
      const snap = await getDoc(doc(db, 'academias', academiaId));
      return snap.data()?.['modalidades_status'];
    } catch {
      return undefined;
    }
  }

  /**
   * Chamado automaticamente (ex.: ao abrir o dashboard). Resolve
   * silenciosamente em qualquer caso que não precise de ação.
   */
  async verificarERetomarSeNecessario(): Promise<void> {
    const academiaId = this.authService.currentUser()?.academiaId;
    const perfil = this.authService.currentUser()?.perfil;
    if (!academiaId || perfil !== 'Admin' || this.emAndamento) return;

    const status = await this.obterStatusAtual(academiaId);
    const precisaRetomar = status === undefined || status === 'pendente' || status === 'erro';
    if (!precisaRetomar) return;

    const estado = this.lerEstadoRetry(academiaId);
    if (estado.tentativas >= MAX_TENTATIVAS) return;
    if (Date.now() - estado.ultimaTentativaEm < COOLDOWN_MS) return;

    this.salvarEstadoRetry(academiaId, {
      tentativas: estado.tentativas + 1,
      ultimaTentativaEm: Date.now(),
    });
    await this.executar(academiaId);
  }

  /**
   * Caminho manual — botão "Tentar novamente" na tela. Ignora cooldown e
   * limite de tentativas automáticas (é uma ação explícita da pessoa, não
   * um loop automático), mas ainda respeita o lock contra 2 cliques
   * simultâneos. Reseta o contador automático também, pra não "gastar"
   * uma tentativa automática por uma ação manual.
   */
  async forcarAgora(academiaId: string): Promise<void> {
    if (this.emAndamento) return;
    this.salvarEstadoRetry(academiaId, { tentativas: 0, ultimaTentativaEm: Date.now() });
    await this.executar(academiaId);
  }

  private async executar(academiaId: string): Promise<void> {
    this.emAndamento = true;
    try {
      const [{ httpsCallable }, { functions }] = await Promise.all([
        import('firebase/functions'),
        import('../firebase/firebase'),
      ]);
      const inicializar = httpsCallable(functions, 'inicializarModalidadesPadrao');
      await inicializar({ academiaId });
    } catch (erro) {
      console.warn('[ModalidadeInitService] Tentativa de inicialização falhou:', erro);
    } finally {
      this.emAndamento = false;
    }
  }

  private lerEstadoRetry(academiaId: string): EstadoRetry {
    try {
      const bruto = sessionStorage.getItem(`${CHAVE_STORAGE}_${academiaId}`);
      if (bruto) return JSON.parse(bruto);
    } catch {
      // ignora storage corrompido/bloqueado
    }
    return { tentativas: 0, ultimaTentativaEm: 0 };
  }

  private salvarEstadoRetry(academiaId: string, estado: EstadoRetry): void {
    try {
      sessionStorage.setItem(`${CHAVE_STORAGE}_${academiaId}`, JSON.stringify(estado));
    } catch {
      // modo privado / storage bloqueado — segue sem persistir o contador,
      // só perde a proteção de cooldown entre recarregamentos da aba
    }
  }
}
