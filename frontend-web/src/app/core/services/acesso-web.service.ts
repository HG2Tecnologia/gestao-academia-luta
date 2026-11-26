import { Injectable, inject, signal } from '@angular/core';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { AcessoWeb, avaliarAcessoWeb } from '../models/acesso-web';
import { FirebaseAuthService } from './firebase-auth.service';

/** Por quanto tempo uma leitura vale, para não consultar a cada troca de tela. */
const VALIDADE_MS = 60_000;

@Injectable({ providedIn: 'root' })
export class AcessoWebService {
  private readonly authService = inject(FirebaseAuthService);

  /** Última avaliação conhecida; `null` antes da primeira leitura ou se ela falhar. */
  readonly acesso = signal<AcessoWeb | null>(null);

  private cache: { academiaId: string; em: number; leitura: Promise<AcessoWeb | null> } | null = null;

  /**
   * Devolve `null` quando não dá para saber (sem academia ou falha de leitura).
   * Quem chama deve liberar nesse caso: uma falha de rede não pode trancar um
   * assinante para fora. A trava é de interface; os dados continuam protegidos
   * pelas regras do Firestore.
   */
  verificar(forcar = false): Promise<AcessoWeb | null> {
    const academiaId = this.authService.currentUser()?.academiaId;
    if (!academiaId) {
      this.acesso.set(null);
      return Promise.resolve(null);
    }

    const cache = this.cache;
    if (!forcar && cache?.academiaId === academiaId && Date.now() - cache.em < VALIDADE_MS) {
      return cache.leitura;
    }

    const leitura = this.ler(academiaId);
    this.cache = { academiaId, em: Date.now(), leitura };
    return leitura;
  }

  private async ler(academiaId: string): Promise<AcessoWeb | null> {
    try {
      const [academia, config] = await Promise.all([
        getDoc(doc(db, 'academias', academiaId)),
        getDoc(doc(db, 'config', 'geral')),
      ]);
      const resultado = academia.exists()
        ? avaliarAcessoWeb(academia.data(), config.data() ?? {})
        : null;
      this.acesso.set(resultado);
      return resultado;
    } catch {
      this.cache = null;
      this.acesso.set(null);
      return null;
    }
  }
}
