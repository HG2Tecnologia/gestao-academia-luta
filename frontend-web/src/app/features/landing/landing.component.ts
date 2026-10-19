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
import { DecimalPipe, DOCUMENT, isPlatformBrowser } from '@angular/common';

@Component({
  selector: 'app-landing',
  standalone: true,
  imports: [RouterLink, DecimalPipe],
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
  readonly rankingRows = signal([
    { name: 'Bruno Yamamoto', pts: 1284, faixa: 'Roxa' },
    { name: 'Letícia Andrade', pts: 1247, faixa: 'Azul' },
    { name: 'Diego Ferreira', pts: 1198, faixa: 'Roxa' },
    { name: 'Rafael Costa', pts: 1142, faixa: 'Azul' },
    { name: 'Mariana Silva', pts: 1098, faixa: 'Branca' },
  ]);

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
      a: '30 dias com acesso completo ao plano Black Belt — sem cartão de crédito. Ao final, você assina pelo app ou continua no Grátis (até 20 alunos, sem app de aluno).',
    },
    {
      q: 'Posso migrar minha planilha de alunos?',
      a: 'Sim! Manda sua planilha e a gente importa tudo pra você sem custo, em até 4 horas.',
    },
    {
      q: 'O app do aluno é incluso em todos os planos?',
      a: 'O app do aluno é incluso no plano Black Belt. No Grátis, só o gestor e os professores têm acesso ao app — sem anúncios, sem limitações no sistema web.',
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
      a: 'Sim. Cancele a qualquer momento direto no app, sem burocracia e sem taxa de cancelamento.',
    },
  ];

  readonly blackBeltMensalEquiv = computed(() => {
    switch (this.billingPeriod()) {
      case 'trimestral': return '83,30';
      case 'anual': return '66,66';
      default: return '99,99';
    }
  });
  readonly blackBeltTotalNote = computed(() => {
    switch (this.billingPeriod()) {
      case 'trimestral': return 'Cobrado R$ 249,90 trimestral · economia de 17%';
      case 'anual': return 'Cobrado R$ 799,90 anual · economia de 33%';
      default: return 'Assine pelo app · Cancele quando quiser';
    }
  });
  readonly blackBeltSavings = computed(() => {
    switch (this.billingPeriod()) {
      case 'trimestral': return 'Economize R$ 50/trimestre vs mensal';
      case 'anual': return 'Economize R$ 400/ano vs mensal';
      default: return null;
    }
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

  readonly diferenciais = [
    {
      num: '01',
      title: 'Financeiro sem planilha',
      body: 'Mensalidade gerada automaticamente todo mês, com vencimento por aluno. Você acompanha pago, pendente e atrasado numa tela só — a cobrança em si (Pix, dinheiro, cartão) você recebe do seu jeito, o sistema só organiza.',
    },
    {
      num: '02',
      title: 'App e sistema web, os mesmos dados',
      body: 'O que o professor lança no app (presença, graduação) aparece no sistema web na hora, e vice-versa. Sem exportar, sem sincronizar manualmente.',
    },
    {
      num: '03',
      title: 'Engajamento que vicia',
      body: 'Ranking, badges, conquistas por faixa, desafios mensais. Os próprios alunos puxam quem falta. A turma se autorregula.',
    },
    {
      num: '04',
      title: 'Feito por quem treina',
      body: 'Time fundador é faixa preta. Cada feature foi pensada num tatame, não numa reunião. Você sente isso em cada tela.',
    },
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

  readonly blackBeltFeatures = [
    'Alunos ilimitados',
    'Turmas ilimitadas',
    'App do aluno (iOS e Android)',
    'Mensalidades geradas automaticamente',
    'Ranking gamificado por faixa',
    'Dashboard financeiro completo',
    'Contratos digitais com assinatura',
    'Relatório financeiro e de presença',
    'Grade de horários completa',
    'Gestão de faixas e graduações',
    'Controle de inadimplência em tempo real',
    'Suporte humano em português, 7 dias',
  ];

  ngOnInit(): void {
    this.document.body.style.setProperty('background', '#0a0a0a');
    this.document.body.style.setProperty('color', '#fafaf7');
  }

  ngAfterViewInit(): void {
    if (!this.isBrowser) return;
    this.intervals.push(
      setInterval(() => this.tick.update((t) => t + 1), 1800),
      setInterval(() => {
        this.rankingRows.update((rows) => {
          const next = rows.map((r) => ({ ...r, pts: r.pts + Math.floor(Math.random() * 8) }));
          next.sort((a, b) => b.pts - a.pts);
          return [...next];
        });
      }, 1600),
    );

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
