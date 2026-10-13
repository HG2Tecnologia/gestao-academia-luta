import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { DOCUMENT, isPlatformBrowser } from '@angular/common';
import { ConsentService } from './consent.service';

/**
 * Mesma propriedade GA4 já ativa na HG2 (`G-1TW34PNK8R`) — NÃO criar uma
 * segunda propriedade. Antes de produção, confirmar no painel do GA4 que
 * `sensei-crm.web.app` foi adicionado como stream/domínio desta
 * propriedade e que o "Cross-domain linking" inclui os dois domínios
 * (hg2tecnologia.com.br + sensei-crm.web.app) — isso só é configurável no
 * painel do Google, não por código.
 */
const GA4_MEASUREMENT_ID = 'G-1TW34PNK8R';

/**
 * Carrega o gtag.js (idêntico ao da HG2, mesmo Measurement ID) e expõe os
 * eventos de conversão do cadastro. SEMPRE chamado depois de
 * `ConsentService.iniciar()` — o `consent default` já precisa estar no
 * `dataLayer` antes do script do GA4 processar qualquer coisa.
 *
 * `page_view` da navegação SPA: por padrão NÃO disparamos manualmente.
 * A Medição Aprimorada do GA4 detecta `history.pushState` (o que o Angular
 * Router usa) automaticamente — ver instruções de validação no relatório
 * final. Se o DebugView mostrar que rotas da SPA não geram `page_view`,
 * ativar `dispararPageViewManual()` abaixo (método já pronto, só não é
 * chamado hoje).
 */
@Injectable({ providedIn: 'root' })
export class AnalyticsService {
  private readonly document = inject(DOCUMENT);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly consent = inject(ConsentService);

  private carregado = false;
  private cadastroIniciadoDisparado = false;

  iniciar(): void {
    if (this.carregado || !this.isBrowser) return;
    this.carregado = true;

    window.gtag?.('js', new Date());
    window.gtag?.('config', GA4_MEASUREMENT_ID, {
      // Enhanced Measurement já cobre page_view via history.pushState; não
      // duplicamos aqui (ver nota de cabeçalho).
      send_page_view: true,
    });

    const script = this.document.createElement('script');
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtag/js?id=${GA4_MEASUREMENT_ID}`;
    this.document.head.appendChild(script);
  }

  /** Usado só se o DebugView mostrar que a Medição Aprimorada não cobre a navegação da SPA. */
  dispararPageViewManual(caminho: string, titulo: string): void {
    if (!this.isBrowser) return;
    window.gtag?.('event', 'page_view', {
      page_location: `${this.document.location.origin}${caminho}`,
      page_title: titulo,
    });
  }

  /**
   * Entrada no funil de cadastro — dispara uma vez por sessão de
   * formulário (ex.: não dispara de novo só por ir da Etapa 2 pra Etapa 1
   * e voltar). Não é um evento padrão do GA4; documentado aqui porque é
   * customizado: "usuário abriu a tela de criar conta".
   */
  cadastroIniciado(): void {
    if (!this.isBrowser || this.cadastroIniciadoDisparado) return;
    this.cadastroIniciadoDisparado = true;
    window.gtag?.('event', 'cadastro_iniciado');
  }

  /**
   * Disparado SÓ depois que `cadastrarAcademia()` confirma sucesso (ver
   * `cadastro.component.ts`). Sem PII, sem `academiaId` — `method` é o
   * único parâmetro, igual à recomendação padrão do GA4 para `sign_up`.
   * Duplicidade: o próprio `guestGuard` impede voltar pra /cadastro depois
   * de autenticado, então não há como este método ser chamado 2x pro
   * mesmo cadastro em condições normais de uso.
   */
  cadastroConcluido(): void {
    if (!this.isBrowser) return;
    window.gtag?.('event', 'sign_up', { method: 'email' });
  }
}
