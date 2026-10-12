import { Injectable, inject } from '@angular/core';
import { DOCUMENT } from '@angular/common';
import { Meta } from '@angular/platform-browser';
import { ActivatedRouteSnapshot, Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs';

const SITE_URL = 'https://sensei-crm.web.app';
const OG_IMAGE = `${SITE_URL}/images/dashboard-sistema-web.png`;

/**
 * Lê `data.description`/`data.robots` da rota ativa (`app.routes.ts`) e
 * aplica via `Meta`/canonical a cada navegação. O `<title>` por rota já
 * funciona nativamente pelo Angular Router (propriedade `title`) — isso
 * cobre só o que falta (description, robots, canonical, Open Graph,
 * Twitter Card).
 */
@Injectable({ providedIn: 'root' })
export class SeoService {
  private readonly meta = inject(Meta);
  private readonly router = inject(Router);
  private readonly document = inject(DOCUMENT);

  iniciar(): void {
    this.router.events.pipe(filter((e) => e instanceof NavigationEnd)).subscribe(() => {
      this.aplicar();
    });
    this.aplicar();
  }

  /** Acumula `data` E o `title` estático da rota mais profunda — não lê de volta o `Title` service (evita corrida com o `DefaultTitleStrategy` durante o prerender/SSR). */
  private dadosDaRota(): { dados: Record<string, any>; titulo: string } {
    let snapshot: ActivatedRouteSnapshot | null = this.router.routerState.snapshot.root;
    let dados: Record<string, any> = {};
    let titulo = 'Sensei Manager';
    while (snapshot) {
      dados = { ...dados, ...snapshot.data };
      if (typeof snapshot.title === 'string') titulo = snapshot.title;
      snapshot = snapshot.firstChild;
    }
    return { dados, titulo };
  }

  private aplicar(): void {
    const { dados, titulo } = this.dadosDaRota();
    const descricao: string = dados['description'] ?? 'Sensei Manager — sistema de gestão para academias de artes marciais.';
    const robots: string = dados['robots'] ?? 'noindex, nofollow';
    const caminho = this.document.location.pathname || '/';
    const url = `${SITE_URL}${caminho}`;

    this.meta.updateTag({ name: 'description', content: descricao });
    this.meta.updateTag({ name: 'robots', content: robots });
    this.meta.updateTag({ property: 'og:title', content: titulo });
    this.meta.updateTag({ property: 'og:description', content: descricao });
    this.meta.updateTag({ property: 'og:type', content: 'website' });
    this.meta.updateTag({ property: 'og:url', content: url });
    this.meta.updateTag({ property: 'og:image', content: OG_IMAGE });
    this.meta.updateTag({ property: 'og:locale', content: 'pt_BR' });
    this.meta.updateTag({ name: 'twitter:card', content: 'summary_large_image' });
    this.meta.updateTag({ name: 'twitter:title', content: titulo });
    this.meta.updateTag({ name: 'twitter:description', content: descricao });
    this.meta.updateTag({ name: 'twitter:image', content: OG_IMAGE });

    this.atualizarCanonical(url);
    this.atualizarJsonLd(caminho === '/');
  }

  /**
   * Só na home, só com dados verificáveis (nome, URL, links reais das lojas
   * de app, preços reais confirmados — R$70 só app / R$99,99 app+CRM).
   * Sem nota, sem depoimento, sem contagem de clientes — nada que não dê
   * pra comprovar (ver auditoria de SEO: números de prova social na tela
   * de login são um problema separado, ainda pendente de decisão, não
   * replicado aqui).
   */
  private atualizarJsonLd(naHome: boolean): void {
    const id = 'seo-jsonld';
    this.document.getElementById(id)?.remove();
    if (!naHome) return;

    const dados = {
      '@context': 'https://schema.org',
      '@graph': [
        {
          '@type': 'Organization',
          name: 'Sensei Manager',
          url: SITE_URL,
          logo: `${SITE_URL}/images/logo_sistema.png`,
          sameAs: [
            'https://apps.apple.com/app/id6745397960',
            'https://play.google.com/store/apps/details?id=br.com.hg2tecnologia.senseimanager',
          ],
        },
        {
          '@type': 'SoftwareApplication',
          name: 'Sensei Manager',
          applicationCategory: 'BusinessApplication',
          operatingSystem: 'iOS, Android, Web',
          offers: [
            { '@type': 'Offer', name: 'App', price: '70.00', priceCurrency: 'BRL' },
            { '@type': 'Offer', name: 'App + CRM Web', price: '99.99', priceCurrency: 'BRL' },
          ],
        },
      ],
    };

    const script = this.document.createElement('script');
    script.id = id;
    script.type = 'application/ld+json';
    script.text = JSON.stringify(dados);
    this.document.head.appendChild(script);
  }

  private atualizarCanonical(url: string): void {
    let link = this.document.querySelector('link[rel="canonical"]');
    if (!link) {
      link = this.document.createElement('link');
      link.setAttribute('rel', 'canonical');
      this.document.head.appendChild(link);
    }
    link.setAttribute('href', url);
  }
}
