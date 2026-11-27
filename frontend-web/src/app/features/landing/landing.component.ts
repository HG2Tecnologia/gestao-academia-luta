import {
  AfterViewInit,
  Component,
  computed,
  ElementRef,
  inject,
  OnDestroy,
  OnInit,
  PLATFORM_ID,
  signal,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { DOCUMENT, isPlatformBrowser } from '@angular/common';

@Component({
  selector: 'app-landing',
  standalone: true,
  imports: [RouterLink],
  templateUrl: './landing.component.html',
  styleUrls: ['./landing.component.css'],
})
export class LandingComponent implements OnInit, AfterViewInit, OnDestroy {
  private readonly el = inject(ElementRef);
  private readonly document = inject(DOCUMENT);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly intervals: ReturnType<typeof setInterval>[] = [];
  private observer: IntersectionObserver | null = null;

  readonly tick = signal(0);
  readonly billingPeriod = signal<'mensal' | 'trimestral' | 'anual'>('mensal');
  readonly menuAberto = signal(false);

  readonly bars = computed(() => {
    const seed = this.tick();
    const base = [55, 62, 48, 70, 65, 78, 82, 75, 88, 92, 84, 95];
    return base.map((b, i) => Math.max(20, Math.min(100, b + Math.sin((seed + i) * 0.7) * 6)));
  });

  readonly dashStats = computed(() => [
    { label: 'Alunos ativos', val: String(247 + (this.tick() % 4)), delta: '+12%' },
    { label: 'Turmas ativas', val: '14', delta: '+2' },
    { label: 'Presenças hoje', val: String(38 + (this.tick() % 3)), delta: '+9%' },
    { label: 'Sem turma', val: '7', delta: '−3' },
  ]);

  readonly chatOpen = signal(false);
  readonly faqAberto = signal<number | null>(null);
  toggleChat(): void { this.chatOpen.update(v => !v); }
  toggleFaq(i: number): void { this.faqAberto.update(v => v === i ? null : i); }

  readonly faqItems = [
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

  /** Preços das lojas. Mudou lá, mude aqui, no SEO e em plan_catalog.dart. */
  private readonly precos = {
    mensal: {
      pro: { porMes: '69,99', nota: 'Cobrado todo mês', economia: '' },
      black: { porMes: '99,99', nota: 'Cobrado todo mês', economia: '' },
    },
    trimestral: {
      pro: { porMes: '49,97', nota: 'Cobrado R$ 149,90 em parcela única a cada 3 meses', economia: '29%' },
      black: { porMes: '76,63', nota: 'Cobrado R$ 229,90 em parcela única a cada 3 meses', economia: '23%' },
    },
    anual: {
      pro: { porMes: '41,66', nota: 'Cobrado R$ 499,90 em parcela única por ano', economia: '40%' },
      black: { porMes: '62,49', nota: 'Cobrado R$ 749,90 em parcela única por ano', economia: '38%' },
    },
  };

  readonly planosPagos = computed(() => {
    const preco = this.precos[this.billingPeriod()];
    return [
      {
        chave: 'pro',
        nome: 'Sensei PRO',
        selo: 'Só app',
        descricao: 'O aplicativo completo, sem limites e sem anúncios.',
        destaque: false,
        recursos: this.recursosPro,
        ...preco.pro,
      },
      {
        chave: 'black',
        nome: 'Black Belt',
        selo: 'App + web',
        descricao: 'Tudo do PRO e o sistema web para gerir pelo computador.',
        destaque: true,
        recursos: ['Tudo do Sensei PRO', 'Sistema web no computador', 'Os mesmos dados no app e no web'],
        ...preco.black,
      },
    ];
  });

  readonly problemas = [
    {
      num: '01',
      title: 'Inadimplência fora de controle',
      body: 'Você não sabe quem pagou, quem deve, e gasta a semana cobrando no WhatsApp.',
      strike: 'Cobrança manual, toda semana',
    },
    {
      num: '02',
      title: 'Aluno some e ninguém percebe',
      body: 'Frequência cai, ninguém liga, ele cancela sem avisar.',
      strike: 'Nenhuma visão de quem sumiu',
    },
    {
      num: '03',
      title: 'Planilha que ninguém entende',
      body: 'Cada professor anota num caderno, num celular, num papel. Você reza pra dar certo.',
      strike: 'Horas perdidas toda segunda',
    },
    {
      num: '04',
      title: 'Sem visão financeira nenhuma',
      body: 'Quanto entrou esse mês? Quanto está pendente? Quanto está atrasado? Ninguém sabe sem abrir uma planilha.',
      strike: 'Decisões no escuro',
    },
  ];

  readonly transforms = [
    ['Planilha de Excel quebrando', 'Dashboard ao vivo no celular'],
    ['Cobrar aluno por WhatsApp', 'Mensalidade gerada automaticamente'],
    ['Aluno some sem você ver', 'Lista de quem está sem turma ou sumiu'],
    ['Decidir no achômetro', 'Relatórios em tempo real'],
    ['Aluno desmotivado', 'Ranking gamificado por faixa'],
  ];

  readonly passos = [
    {
      num: 'Passo 01',
      title: 'Crie sua conta grátis',
      body: 'Em 60 segundos. Não pedimos cartão. Só email e o nome da academia.',
    },
    {
      num: 'Passo 02',
      title: 'Importe seus alunos',
      body: 'Mande sua planilha. Importamos pra você sem custo.',
    },
    {
      num: 'Passo 03',
      title: 'Configure suas mensalidades',
      body: 'Defina o valor e o dia de vencimento por modalidade ou plano. O sistema gera a cobrança automaticamente todo mês.',
    },
    {
      num: 'Passo 04',
      title: 'Convide seus alunos',
      body: 'Manda o link, eles baixam o app, veem o ranking e nunca mais te ligam pedindo recibo.',
    },
  ];

  readonly disciplinas = [
    'JIU-JITSU', 'MUAY THAI', 'BOXE', 'MMA',
    'KARATÊ', 'TAEKWONDO', 'WRESTLING', 'KICKBOXING', 'JUDÔ', 'CAPOEIRA',
  ];
  readonly disciplinasMarquee = [...this.disciplinas, ...this.disciplinas];

  private readonly recursosPro = [
    'Alunos, turmas e equipe sem limite',
    'App sem anúncios',
    'Relatório oficial de presenças',
    'Exportação financeira em PDF e Excel',
    'Alertas de evasão e de próximos da graduação',
    'Rankings personalizados sem limite',
    'Notícias da academia',
    'Regras de check-in e cobrança por modalidade',
  ];

  ngOnInit(): void {
    this.document.body.style.setProperty('background', '#0a0a0a');
    this.document.body.style.setProperty('color', '#fafaf7');
  }

  ngAfterViewInit(): void {
    if (!this.isBrowser) return;
    this.intervals.push(setInterval(() => this.tick.update((t) => t + 1), 1800));

    this.observer = new IntersectionObserver(
      (entries) =>
        entries.forEach((e) => {
          if (e.isIntersecting) {
            e.target.classList.add('in');
            this.observer!.unobserve(e.target);
          }
        }),
      { threshold: 0.1 },
    );
    this.el.nativeElement.querySelectorAll('[data-reveal]').forEach((el: Element) => {
      this.observer!.observe(el);
    });
  }

  ngOnDestroy(): void {
    this.intervals.forEach(clearInterval);
    this.observer?.disconnect();
    this.document.body.style.removeProperty('background');
    this.document.body.style.removeProperty('color');
  }

}
