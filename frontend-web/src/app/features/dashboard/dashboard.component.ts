import { Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FirebaseAuthService } from '../../core/services/firebase-auth.service';
import { DashboardService, DashboardResumoDto, FrequenciaDiariaDto } from '../../core/services/dashboard.service';
import { AlunoService } from '../../core/services/aluno.service';
import { AniversarianteDto } from '../../core/models/aluno.model';
import { ModalidadeService } from '../../core/services/modalidade.service';
import { PlanoService } from '../../core/services/plano.service';
import { FinanceiroService } from '../../core/services/financeiro.service';
import { ResumoFinanceiroDto, PagamentoDto } from '../../core/models/financeiro.model';
import { dataLocalISO } from '../../core/utils/date.util';

type FiltroPag = 'hoje' | 'semana' | 'mes';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css'],
})
export class DashboardComponent implements OnInit {
  readonly authService = inject(FirebaseAuthService);
  private readonly dashboardService = inject(DashboardService);
  private readonly alunoService = inject(AlunoService);
  private readonly modalidadeService = inject(ModalidadeService);
  private readonly planoService = inject(PlanoService);
  private readonly financeiroService = inject(FinanceiroService);

  readonly resumo = signal<DashboardResumoDto | null>(null);
  readonly resumoFin = signal<ResumoFinanceiroDto | null>(null);
  readonly pagamentosMes = signal<PagamentoDto[]>([]);
  readonly aniversariantes = signal<AniversarianteDto[]>([]);
  readonly frequencia = signal<FrequenciaDiariaDto[]>([]);
  readonly carregando = signal(true);
  readonly erro = signal('');
  readonly filtroPag = signal<FiltroPag>('hoje');

  readonly temModalidades = signal(false);
  readonly temPlanos = signal(false);

  readonly hoje = new Date();

  get primeiroNome(): string {
    return this.authService.currentUser()?.nome?.split(' ')[0] ?? 'usuário';
  }
  private readonly anoAtual = this.hoje.getFullYear();
  private readonly mesAtualNum = this.hoje.getMonth() + 1;

  readonly pagamentosFiltrados = computed(() => {
    const pags = this.pagamentosMes().filter(p => p.status === 'Pendente' || p.status === 'Atrasado');
    const filtro = this.filtroPag();
    const hojeStr = dataLocalISO(this.hoje);
    if (filtro === 'hoje') {
      return pags.filter(p => p.dataVencimento === hojeStr);
    }
    if (filtro === 'semana') {
      const fim = new Date(this.hoje);
      fim.setDate(fim.getDate() + 7);
      const fimStr = dataLocalISO(fim);
      return pags.filter(p => p.dataVencimento && p.dataVencimento <= fimStr && p.dataVencimento >= hojeStr);
    }
    return pags;
  });

  readonly totalFiltrado = computed(() =>
    this.pagamentosFiltrados().reduce((s, p) => s + p.valor, 0)
  );

  readonly freqMax = computed(() => Math.max(...this.frequencia().map(f => f.total), 1));

  readonly freqBars = computed(() =>
    this.frequencia().map(f => ({
      data: f.data,
      total: f.total,
      pct: Math.max(4, Math.round((f.total / this.freqMax()) * 100)),
      label: f.data.slice(8, 10) + '/' + f.data.slice(5, 7),
    }))
  );

  readonly passos = computed(() => [
    {
      id: 'modalidade',
      titulo: 'Crie uma modalidade',
      descricao: 'Ex: Jiu-Jitsu, Muay Thai, Boxe. As turmas dependem das modalidades.',
      link: '/app/modalidades',
      linkLabel: 'Criar modalidade',
      feito: this.temModalidades(),
    },
    {
      id: 'plano',
      titulo: 'Crie um plano de mensalidade',
      descricao: 'Defina os valores e periodicidade dos planos que seus alunos podem contratar.',
      link: '/app/planos',
      linkLabel: 'Criar plano',
      feito: this.temPlanos(),
    },
    {
      id: 'turma',
      titulo: 'Monte uma turma',
      descricao: 'Agrupe alunos por modalidade, nível e horário.',
      link: '/app/turmas/novo',
      linkLabel: 'Criar turma',
      feito: (this.resumo()?.turmasAtivas ?? 0) > 0,
    },
    {
      id: 'aluno',
      titulo: 'Cadastre seu primeiro aluno',
      descricao: 'Agora que a estrutura está pronta, comece a matricular!',
      link: '/app/alunos/novo',
      linkLabel: 'Cadastrar aluno',
      feito: (this.resumo()?.totalAlunos ?? 0) > 0,
    },
  ]);

  readonly setupCompleto = computed(() => this.passos().every(p => p.feito));
  readonly passosFeitos = computed(() => this.passos().filter(p => p.feito).length);

  readonly mesNomes = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
  readonly mesAtual = new Date().getMonth();

  ngOnInit(): void {
    this.carregar();
    this.alunoService.getAniversariantes().subscribe({
      next: (res) => this.aniversariantes.set(res.dados ?? []),
    });
    this.modalidadeService.getAll().subscribe({
      next: (res) => this.temModalidades.set((res.dados?.length ?? 0) > 0),
    });
    this.planoService.listar().subscribe({
      next: (res) => this.temPlanos.set((res.dados?.length ?? 0) > 0),
    });
    this.financeiroService.getResumo(this.anoAtual, this.mesAtualNum).subscribe({
      next: (res) => this.resumoFin.set(res.dados ?? null),
    });
    this.financeiroService.listar({ ano: this.anoAtual, mes: this.mesAtualNum, pageSize: 200 }).subscribe({
      next: (res) => this.pagamentosMes.set(res.dados ?? []),
    });
    this.dashboardService.getFrequencia(14).subscribe({
      next: (res) => this.frequencia.set(res.dados ?? []),
    });
  }

  carregar(): void {
    this.carregando.set(true);
    this.erro.set('');
    this.dashboardService.getResumo().subscribe({
      next: (res) => { this.resumo.set(res.dados ?? null); this.carregando.set(false); },
      error: () => { this.erro.set('Erro ao carregar dados.'); this.carregando.set(false); },
    });
  }

  formatarMoeda(v: number): string {
    return v.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }

  formatarData(d?: string): string {
    if (!d) return '—';
    const [y, m, day] = d.split('-');
    return `${day}/${m}/${y}`;
  }
}
