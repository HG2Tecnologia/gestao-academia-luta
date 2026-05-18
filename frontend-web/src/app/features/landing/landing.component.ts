import {
  AfterViewInit,
  Component,
  computed,
  ElementRef,
  inject,
  OnDestroy,
  OnInit,
  signal,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { DecimalPipe } from '@angular/common';

@Component({
  selector: 'app-landing',
  standalone: true,
  imports: [RouterLink, DecimalPipe],
  templateUrl: './landing.component.html',
  styleUrls: ['./landing.component.css'],
})
export class LandingComponent implements OnInit, AfterViewInit, OnDestroy {
  private readonly el = inject(ElementRef);
  private readonly intervals: ReturnType<typeof setInterval>[] = [];
  private observer: IntersectionObserver | null = null;

  readonly tick = signal(0);
  readonly testimonialIdx = signal(0);
  readonly pricingAnual = signal(false);
  readonly menuAberto = signal(false);
  readonly roiStudents = signal(120);
  readonly roiFee = signal(220);
  readonly roiDefaultRate = signal(14);
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
    { label: 'Receita do mês', val: 'R$ 38.4k', delta: '+18%' },
    { label: 'Inadimplência', val: '3.2%', delta: '−41%' },
  ]);

  readonly pricingPreco = computed(() => (this.pricingAnual() ? 119 : 149));
  readonly pricingWas = computed(() => (this.pricingAnual() ? 149 : 199));

  readonly roiResult = computed(() => {
    const students = this.roiStudents();
    const fee = this.roiFee();
    const rate = this.roiDefaultRate();
    const monthlyRevenue = students * fee;
    const lostNow = monthlyRevenue * (rate / 100);
    const recovered = lostNow * 0.7;
    const newStudents = Math.round(students * 0.12);
    const growth = newStudents * fee;
    return { recovered, growth, total: recovered + growth, newStudents };
  });

  readonly testimonialAtivo = computed(() => this.depoimentos[this.testimonialIdx()]);

  readonly depoimentos = [
    {
      quote:
        'Cortei a inadimplência de 14% pra menos de 4% em dois meses. O sistema cobra sozinho, eu só dou aula.',
      name: 'Marcelo Tanaka',
      role: 'Faixa Preta · Academia Tatame Norte, São Paulo',
      avatar: 'MT',
    },
    {
      quote:
        'O ranking gamificado virou febre. Os alunos competem pra não faltar. Frequência subiu 38% no primeiro mês.',
      name: 'Ana Beatriz Lopes',
      role: 'Coach · Iron Fist Boxe, Belo Horizonte',
      avatar: 'AB',
    },
    {
      quote:
        'Eu gerenciava 80 alunos numa planilha. Hoje tenho 240 e sobra tempo. Foi a melhor decisão que tomei pro negócio.',
      name: 'Rodrigo Vieira',
      role: 'Dono · Vieira Muay Thai, Curitiba',
      avatar: 'RV',
    },
    {
      quote:
        'Em 6 meses dobrei a base de alunos sem contratar ninguém. O Tatame faz o trabalho de uma secretária por R$ 149.',
      name: 'Camila Reis',
      role: 'Sócia · Reis Jiu-Jitsu, Recife',
      avatar: 'CR',
    },
  ];

  readonly problemas = [
    {
      num: '01',
      title: 'Inadimplência fora de controle',
      body: 'Você não sabe quem pagou, quem deve, e gasta a semana cobrando no WhatsApp.',
      strike: '14% de inadimplência média',
    },
    {
      num: '02',
      title: 'Aluno some e ninguém percebe',
      body: 'Frequência cai por 3 semanas, ninguém liga, ele cancela. Churn invisível.',
      strike: '1 em cada 4 alunos some por ano',
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
      body: 'Quanto entrou esse mês? Quanto vai entrar? Qual aluno dá lucro? Ninguém sabe.',
      strike: 'Decisões no escuro',
    },
  ];

  readonly transforms = [
    ['Planilha de Excel quebrando', 'Dashboard ao vivo no celular'],
    ['Cobrar aluno por WhatsApp', 'Pix automático + lembrete'],
    ['Aluno some sem você ver', 'Alerta de churn em 7 dias'],
    ['Decidir no achômetro', 'Relatórios em tempo real'],
    ['Aluno desmotivado', 'Ranking gamificado por faixa'],
  ];

  readonly diferenciais = [
    {
      num: '01',
      title: 'Automação que cobra sozinha',
      body: 'Pix, cartão, lembrete por WhatsApp, segunda via, comprovante. O fluxo financeiro inteiro roda sozinho. Você revisa em 5 minutos por semana.',
    },
    {
      num: '02',
      title: 'Inteligência que prevê o churn',
      body: 'Quando um aluno falta 3 semanas, o sistema te avisa antes dele cancelar. Você liga, ele volta. Retenção sobe sem esforço.',
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
      body: 'Mande sua planilha. Importamos pra você sem custo. Em 4 horas tá tudo lá.',
    },
    {
      num: 'Passo 03',
      title: 'Configure cobrança',
      body: 'Conecta sua conta Pix ou banco. Define dia de vencimento. Pronto, automatizou.',
    },
    {
      num: 'Passo 04',
      title: 'Convide seus alunos',
      body: 'Manda o link, eles baixam o app, veem o ranking e nunca mais te ligam pedindo recibo.',
    },
  ];

  readonly beneficios = [
    { num: '+38%', label: 'Frequência média de alunos no tatame' },
    { num: '−72%', label: 'Inadimplência depois do 2º mês' },
    { num: '+27%', label: 'Crescimento de base de alunos em 6 meses' },
    { num: '12h', label: 'Economizadas por semana em tarefas operacionais' },
  ];

  readonly disciplinas = [
    'JIU-JITSU', 'MUAY THAI', 'BOXE', 'MMA',
    'KARATÊ', 'TAEKWONDO', 'WRESTLING', 'KICKBOXING', 'JUDÔ', 'CAPOEIRA',
  ];
  readonly disciplinasMarquee = [...this.disciplinas, ...this.disciplinas];

  readonly priceFeatures = [
    'Alunos ilimitados',
    'Cobrança automática (Pix + cartão)',
    'Ranking gamificado',
    'Controle de presença por QR',
    'Dashboard financeiro completo',
    'App para alunos (iOS + Android)',
    'WhatsApp automático',
    'Múltiplas unidades',
    'Relatórios personalizados',
    'Suporte humano em até 2h',
    'Importação grátis de planilhas',
    '30 dias grátis. Cancele quando quiser',
  ];

  ngOnInit(): void {
    document.body.style.setProperty('background', '#0a0a0a');
    document.body.style.setProperty('color', '#fafaf7');
  }

  ngAfterViewInit(): void {
    this.intervals.push(
      setInterval(() => this.tick.update((t) => t + 1), 1800),
      setInterval(() => {
        this.rankingRows.update((rows) => {
          const next = rows.map((r) => ({ ...r, pts: r.pts + Math.floor(Math.random() * 8) }));
          next.sort((a, b) => b.pts - a.pts);
          return [...next];
        });
      }, 1600),
      setInterval(() => {
        this.testimonialIdx.update((i) => (i + 1) % this.depoimentos.length);
      }, 7000),
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
    document.body.style.removeProperty('background');
    document.body.style.removeProperty('color');
  }

  fmtBrl(n: number): string {
    return 'R$ ' + Math.round(n).toLocaleString('pt-BR');
  }

  setRoiStudents(e: Event): void {
    this.roiStudents.set(+(e.target as HTMLInputElement).value);
  }

  setRoiFee(e: Event): void {
    this.roiFee.set(+(e.target as HTMLInputElement).value);
  }

  setRoiDefault(e: Event): void {
    this.roiDefaultRate.set(+(e.target as HTMLInputElement).value);
  }

  prevTestimonial(): void {
    this.testimonialIdx.update((i) => (i - 1 + this.depoimentos.length) % this.depoimentos.length);
  }

  nextTestimonial(): void {
    this.testimonialIdx.update((i) => (i + 1) % this.depoimentos.length);
  }
}
