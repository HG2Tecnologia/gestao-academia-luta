import { Injectable, PLATFORM_ID, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

/**
 * Os 5 sinais de Consent Mode v2 que a Google reconhece, mais os 2 sinais
 * "essenciais" (`functionality_storage`/`security_storage`) que o produto em
 * si já usa (sessão de login, preferência de tema) independente de
 * marketing — esses dois nunca são perguntados ao usuário, só documentados.
 */
export interface ConsentState {
  analytics_storage: 'granted' | 'denied';
  ad_storage: 'granted' | 'denied';
  ad_user_data: 'granted' | 'denied';
  ad_personalization: 'granted' | 'denied';
  personalization_storage: 'granted' | 'denied';
  functionality_storage: 'granted' | 'denied';
  security_storage: 'granted' | 'denied';
}

const STORAGE_KEY = 'sm_consent_v1';

const ESTADO_PADRAO_NEGADO: ConsentState = {
  analytics_storage: 'denied',
  ad_storage: 'denied',
  ad_user_data: 'denied',
  ad_personalization: 'denied',
  personalization_storage: 'denied',
  // Essenciais: o próprio login/tema do CRM depende disso funcionar sempre,
  // não são escolha do usuário — ver nota na política de privacidade.
  functionality_storage: 'granted',
  security_storage: 'granted',
};

declare global {
  interface Window {
    dataLayer?: unknown[];
    gtag?: (...args: unknown[]) => void;
  }
}

/**
 * Consentimento real (controla se as tags disparam), não um banner
 * decorativo. `iniciar()` precisa correr ANTES de qualquer script do GA4
 * ser injetado — ver `AnalyticsService.iniciar()`, que só injeta o
 * `gtag.js` depois de `ConsentService.iniciar()` já ter empurrado o
 * `consent default` pro `dataLayer`.
 */
@Injectable({ providedIn: 'root' })
export class ConsentService {
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  readonly estado = signal<ConsentState>(ESTADO_PADRAO_NEGADO);
  /** true depois que o usuário já aceitou/recusou/personalizou — controla a visibilidade do banner. */
  readonly jaDecidiu = signal(false);
  /** Reaberto manualmente via "Revisar preferências" no footer/privacidade. */
  readonly banerAberto = signal(false);

  private iniciado = false;

  iniciar(): void {
    if (this.iniciado || !this.isBrowser) return;
    this.iniciado = true;

    window.dataLayer = window.dataLayer || [];
    window.gtag = window.gtag || ((...args: unknown[]) => window.dataLayer!.push(args));

    const salvo = this.lerDoStorage();
    if (salvo) {
      this.estado.set(salvo);
      this.jaDecidiu.set(true);
    } else {
      this.banerAberto.set(true);
    }

    // `consent default` precisa ser o primeiro comando pro gtag — garante
    // que, mesmo que o gtag.js ainda não tenha carregado, qualquer tag que
    // vier depois já nasce respeitando o estado atual.
    window.gtag('consent', 'default', this.estado());
  }

  aceitarTudo(): void {
    this.salvar({
      ...this.estado(),
      analytics_storage: 'granted',
      ad_storage: 'granted',
      ad_user_data: 'granted',
      ad_personalization: 'granted',
      personalization_storage: 'granted',
    });
  }

  recusarTudo(): void {
    this.salvar({
      ...ESTADO_PADRAO_NEGADO,
    });
  }

  salvarPersonalizado(opcoes: {
    analytics: boolean;
    ads: boolean;
    personalization: boolean;
  }): void {
    this.salvar({
      ...this.estado(),
      analytics_storage: opcoes.analytics ? 'granted' : 'denied',
      ad_storage: opcoes.ads ? 'granted' : 'denied',
      ad_user_data: opcoes.ads ? 'granted' : 'denied',
      ad_personalization: opcoes.ads ? 'granted' : 'denied',
      personalization_storage: opcoes.personalization ? 'granted' : 'denied',
    });
  }

  /** Reabre o banner pra revisão posterior (link fixo em /privacidade ou no footer). */
  abrirPreferencias(): void {
    this.banerAberto.set(true);
  }

  private salvar(novoEstado: ConsentState): void {
    this.estado.set(novoEstado);
    this.jaDecidiu.set(true);
    this.banerAberto.set(false);
    if (this.isBrowser) {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(novoEstado));
      } catch {
        // Modo privado / storage bloqueado: a escolha vale só pra sessão atual.
      }
      window.gtag?.('consent', 'update', novoEstado);
    }
  }

  private lerDoStorage(): ConsentState | null {
    try {
      const bruto = localStorage.getItem(STORAGE_KEY);
      if (!bruto) return null;
      const dados = JSON.parse(bruto);
      if (dados && typeof dados === 'object' && 'analytics_storage' in dados) {
        return { ...ESTADO_PADRAO_NEGADO, ...dados };
      }
    } catch {
      // ignora storage corrompido, trata como "ainda não decidiu"
    }
    return null;
  }
}
