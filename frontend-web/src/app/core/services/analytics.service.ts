import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { DOCUMENT, isPlatformBrowser } from '@angular/common';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs/operators';
import { ConsentService } from './consent.service';

type NomeEvento = 'page_view' | 'cadastro_iniciado' | 'sign_up';

const CLIENT_ID_KEY = 'sm_ga_cid';
const SESSION_ID_KEY = 'sm_ga_sid';

function gerarIdNumerico(): string {
  return `${Math.floor(Math.random() * 1e10)}.${Math.floor(Date.now() / 1000)}`;
}

/**
 * Envia os eventos de conversão do cadastro pro GA4 via Measurement
 * Protocol, pelo servidor (`registrarEventoAnalytics`), não por `gtag.js`
 * no navegador.
 *
 * Por quê: investigação de causa raiz (comparando com o `gtag.js` já em
 * produção na HG2, mesmo Measurement ID `G-1TW34PNK8R`) provou, com
 * evidência de rede reproduzida em 3 cenários independentes — página
 * isolada sem nenhum código nosso, este app, e o próprio `gtag.js` da HG2
 * quando carregado fora do contêiner GTM dela — que esse Measurement ID
 * nunca envia dados ao GA4 quando carregado de forma autônoma: só
 * dispara os pixels da conta de Google Ads vinculada. O destino GA4
 * desse "Google tag" só é alcançado através daquele contêiner GTM
 * específico da HG2, que não faz sentido reusar aqui (misturaria
 * tráfego do produto com o site institucional). Ver cabeçalho completo
 * em `functions/analytics-functions.js`.
 *
 * `clientId`/`sessionId`: identificadores opacos (não PII) persistidos
 * em `localStorage`/`sessionStorage`, equivalentes ao `_ga`/`_ga_*` que o
 * `gtag.js` padrão geraria — só existem pra o GA4 agrupar eventos da
 * mesma visita/sessão, nunca são lidos como identidade real.
 */
@Injectable({ providedIn: 'root' })
export class AnalyticsService {
  private readonly document = inject(DOCUMENT);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly consent = inject(ConsentService);
  private readonly router = inject(Router);

  private iniciado = false;
  private cadastroIniciadoDisparado = false;
  private ultimoPageViewPath: string | null = null;

  iniciar(): void {
    if (this.iniciado || !this.isBrowser) return;
    this.iniciado = true;

    this.dispararPageView();
    this.router.events.pipe(filter((e) => e instanceof NavigationEnd)).subscribe(() => {
      this.dispararPageView();
    });
  }

  /** Entrada no funil de cadastro — uma vez por sessão de formulário. */
  cadastroIniciado(): void {
    if (!this.isBrowser || this.cadastroIniciadoDisparado) return;
    this.cadastroIniciadoDisparado = true;
    void this.enviar('cadastro_iniciado', {});
  }

  /** Disparado só depois que `cadastrarAcademia()` confirma sucesso. */
  cadastroConcluido(): void {
    if (!this.isBrowser) return;
    void this.enviar('sign_up', {});
  }

  private dispararPageView(): void {
    if (!this.isBrowser) return;
    const caminhoAtual = this.document.location.pathname + this.document.location.search;
    if (caminhoAtual === this.ultimoPageViewPath) return;
    this.ultimoPageViewPath = caminhoAtual;
    void this.enviar('page_view', {
      page_location: this.document.location.href,
      page_title: this.document.title,
    });
  }

  private async enviar(nome: NomeEvento, params: Record<string, unknown>): Promise<void> {
    if (this.consent.estado().analytics_storage !== 'granted') return;
    try {
      const [{ httpsCallable }, { functions }] = await Promise.all([
        import('firebase/functions'),
        import('../firebase/firebase'),
      ]);
      const registrar = httpsCallable(functions, 'registrarEventoAnalytics');
      await registrar({
        clientId: this.obterClientId(),
        consentimentoAnalytics: true,
        evento: {
          name: nome,
          params: { ...params, session_id: this.obterSessionId() },
        },
      });
    } catch (erro) {
      // Nunca propaga — analytics é complementar, não pode quebrar a
      // navegação nem o cadastro.
      console.warn('[AnalyticsService] Falha ao enviar evento:', erro);
    }
  }

  private obterClientId(): string {
    try {
      const existente = localStorage.getItem(CLIENT_ID_KEY);
      if (existente) return existente;
      const novo = gerarIdNumerico();
      localStorage.setItem(CLIENT_ID_KEY, novo);
      return novo;
    } catch {
      return gerarIdNumerico();
    }
  }

  private obterSessionId(): string {
    try {
      const existente = sessionStorage.getItem(SESSION_ID_KEY);
      if (existente) return existente;
      const novo = String(Math.floor(Date.now() / 1000));
      sessionStorage.setItem(SESSION_ID_KEY, novo);
      return novo;
    } catch {
      return String(Math.floor(Date.now() / 1000));
    }
  }
}
