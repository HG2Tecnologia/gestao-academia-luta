import { Injectable, inject } from '@angular/core';
import { DOCUMENT } from '@angular/common';
import { Meta } from '@angular/platform-browser';
import { ActivatedRouteSnapshot, Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs';

const SITE_URL = 'https://sensei-crm.web.app';
const OG_IMAGE = `${SITE_URL}/images/dashboard-sistema-web.png`;

/**
 * Mesmas perguntas do widget de FAQ em `LandingComponent` — mantidas aqui
 * também (pequena duplicação deliberada) porque o SEO não deve depender de
 * um componente de UI carregado sob demanda; se o texto do FAQ mudar, mude
 * nos dois lugares.
 */
const FAQ_ITEMS: ReadonlyArray<{ q: string; a: string }> = [
  {
    q: 'Como funciona o período grátis?',
    a: '30 dias com tudo liberado, inclusive o sistema web, sem cartão de crédito. Ao final, você assina pelo app o Sensei PRO (app) ou o Black Belt (app + web), ou continua no Grátis (até 5 alunos, 1 turma e 1 funcionário).',
  },
  {
    q: 'Posso migrar minha planilha de alunos?',
    a: 'Sim! Manda sua planilha e a gente importa tudo pra você sem custo, em até 4 horas.',
  },
  {
    q: 'Qual a diferença entre o Sensei PRO e o Black Belt?',
    a: 'Os dois liberam o aplicativo sem limites. O Black Belt inclui também o sistema web, para gerir a academia pelo computador.',
  },
  {
    q: 'Funciona para qual modalidade?',
    a: 'Qualquer uma. Jiu-Jitsu, Muay Thai, Boxe, MMA, Karatê, Judô, Taekwondo... feito para todas as artes marciais.',
  },
  {
    q: 'Como funciona a geração de mensalidades?',
    a: 'Você define o valor e o dia de vencimento por modalidade ou plano, e o sistema gera a cobrança automaticamente todo mês. O recebimento em si (Pix, dinheiro, cartão) é do seu jeito — o sistema organiza quem pagou, quem está pendente e quem está atrasado.',
  },
  {
    q: 'Posso cancelar quando quiser?',
    a: 'Sim. A assinatura é feita direto na sua conta da App Store ou do Google Play, então cancelamento, troca de plano e reembolso são tratados por lá (ou pelo próprio app) — sem taxa de cancelamento. O acesso vale até o fim do período já pago.',
  },
  {
    q: 'Os planos trimestral e anual são parcelados?',
    a: 'Não. O valor é cobrado em uma parcela única na sua conta da loja (ex.: R$ 149,90 de uma vez no plano trimestral) — o "preço por mês" mostrado aqui é só pra facilitar a comparação, não é parcelamento no cartão.',
  },
];

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
   * de app, preços mensais das lojas.
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
            'https://apps.apple.com/app/id6777092562',
            'https://play.google.com/store/apps/details?id=br.com.hg2tecnologia.senseimanager',
          ],
        },
        {
          '@type': 'SoftwareApplication',
          name: 'Sensei Manager',
          applicationCategory: 'BusinessApplication',
          operatingSystem: 'iOS, Android, Web',
          offers: [
            { '@type': 'Offer', name: 'Grátis', price: '0', priceCurrency: 'BRL' },
            { '@type': 'Offer', name: 'Sensei PRO (app)', price: '69.99', priceCurrency: 'BRL' },
            { '@type': 'Offer', name: 'Sensei Black Belt (app + web)', price: '99.99', priceCurrency: 'BRL' },
          ],
        },
        {
          '@type': 'FAQPage',
          mainEntity: FAQ_ITEMS.map((item) => ({
            '@type': 'Question',
            name: item.q,
            acceptedAnswer: { '@type': 'Answer', text: item.a },
          })),
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
