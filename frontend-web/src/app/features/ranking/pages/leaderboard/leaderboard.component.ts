import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { RankingService } from '../../../../core/services/ranking.service';
import { AlunoService } from '../../../../core/services/aluno.service';
import { AuthService } from '../../../../core/services/auth.service';
import { LeaderboardCustomDto, LancamentoPontoDto, RankingCustomDto } from '../../../../core/models/ranking.model';

@Component({
  selector: 'app-leaderboard',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterLink],
  templateUrl: './leaderboard.component.html',
})
export class LeaderboardComponent implements OnInit {
  rankings = signal<RankingCustomDto[]>([]);
  rankingSelecionado = signal<RankingCustomDto | null>(null);
  leaderboard = signal<LeaderboardCustomDto | null>(null);
  lancamentos = signal<LancamentoPontoDto[]>([]);
  alunos = signal<any[]>([]);

  carregando = signal(true);
  carregandoLb = signal(false);
  carregandoLanc = signal(false);
  erro = signal('');

  // Modais
  showModalCriar = signal(false);
  showModalPontuar = signal(false);
  showLancamentos = signal(false);
  salvando = signal(false);
  erroModal = signal('');

  formCriar = this.fb.group({
    nome: ['', Validators.required],
    descricao: [''],
    incluirPresencas: [true],
    incluirPontosManuais: [true],
    pesoPresencas: [1, [Validators.required, Validators.min(1)]],
    pesoManuais: [1, [Validators.required, Validators.min(1)]],
    visivelParaAluno: [true],
    dataInicio: [''],
    dataFim: [''],
  });

  formPontuar = this.fb.group({
    alunoId: ['', Validators.required],
    pontos: [1, [Validators.required, Validators.min(1)]],
    descricao: [''],
  });

  editandoId = signal<string | null>(null);

  constructor(
    private rankingService: RankingService,
    private alunoService: AlunoService,
    readonly authService: AuthService,
    private fb: FormBuilder,
  ) {}

  ngOnInit(): void {
    this.carregarRankings();
    this.carregarAlunos();
  }

  get isAdmin(): boolean { return this.authService.currentUser()?.perfil === 'Admin'; }
  get isProfessor(): boolean {
    const p = this.authService.currentUser()?.perfil;
    return p === 'Professor' || p === 'Admin';
  }

  carregarRankings(): void {
    this.carregando.set(true);
    this.rankingService.listarRankingsCustom(this.isAdmin).subscribe({
      next: list => {
        this.rankings.set(list);
        if (list.length > 0 && !this.rankingSelecionado()) {
          this.selecionarRanking(list[0]);
        }
        this.carregando.set(false);
      },
      error: () => { this.erro.set('Erro ao carregar rankings.'); this.carregando.set(false); },
    });
  }

  selecionarRanking(r: RankingCustomDto): void {
    this.rankingSelecionado.set(r);
    this.leaderboard.set(null);
    this.showLancamentos.set(false);
    this.carregarLeaderboard(r.id);
  }

  carregarLeaderboard(id: string): void {
    this.carregandoLb.set(true);
    this.rankingService.getLeaderboardCustom(id).subscribe({
      next: lb => { this.leaderboard.set(lb); this.carregandoLb.set(false); },
      error: () => this.carregandoLb.set(false),
    });
  }

  carregarLancamentos(): void {
    const r = this.rankingSelecionado();
    if (!r) return;
    this.carregandoLanc.set(true);
    this.rankingService.listarLancamentos(r.id).subscribe({
      next: list => { this.lancamentos.set(list); this.carregandoLanc.set(false); },
      error: () => this.carregandoLanc.set(false),
    });
  }

  toggleLancamentos(): void {
    this.showLancamentos.update(v => !v);
    if (this.showLancamentos() && this.lancamentos().length === 0) {
      this.carregarLancamentos();
    }
  }

  carregarAlunos(): void {
    this.alunoService.getAll({ ativo: true, page: 1, pageSize: 500 }).subscribe({
      next: r => this.alunos.set((r.dados as any)?.itens ?? r.dados ?? []),
      error: () => {},
    });
  }

  // ─── Modal Criar/Editar ───────────────────────────────────────────────────

  abrirCriar(): void {
    this.editandoId.set(null);
    this.formCriar.reset({
      nome: '', descricao: '', incluirPresencas: true, incluirPontosManuais: true,
      pesoPresencas: 1, pesoManuais: 1, visivelParaAluno: true, dataInicio: '', dataFim: '',
    });
    this.erroModal.set('');
    this.showModalCriar.set(true);
  }

  abrirEditar(r: RankingCustomDto): void {
    this.editandoId.set(r.id);
    this.formCriar.patchValue({
      nome: r.nome,
      descricao: r.descricao ?? '',
      incluirPresencas: r.incluirPresencas,
      incluirPontosManuais: r.incluirPontosManuais,
      pesoPresencas: r.pesoPresencas,
      pesoManuais: r.pesoManuais,
      visivelParaAluno: r.visivelParaAluno,
      dataInicio: r.dataInicio ?? '',
      dataFim: r.dataFim ?? '',
    });
    this.erroModal.set('');
    this.showModalCriar.set(true);
  }

  salvarRanking(): void {
    if (this.formCriar.invalid) return;
    this.salvando.set(true);
    this.erroModal.set('');
    const v = this.formCriar.value;
    const payload = {
      nome: v.nome!, descricao: v.descricao || undefined,
      incluirPresencas: v.incluirPresencas!, incluirPontosManuais: v.incluirPontosManuais!,
      pesoPresencas: v.pesoPresencas!, pesoManuais: v.pesoManuais!,
      visivelParaAluno: v.visivelParaAluno!,
      dataInicio: v.dataInicio || undefined, dataFim: v.dataFim || undefined,
      ativo: true,
    };

    const editId = this.editandoId();
    const obs = editId
      ? this.rankingService.atualizarRankingCustom(editId, payload)
      : this.rankingService.criarRankingCustom(payload);

    obs.subscribe({
      next: () => { this.salvando.set(false); this.showModalCriar.set(false); this.carregarRankings(); },
      error: (e) => { this.salvando.set(false); this.erroModal.set(e?.error?.mensagem ?? 'Erro ao salvar'); },
    });
  }

  desativarRanking(r: RankingCustomDto): void {
    if (!confirm(`Desativar o ranking "${r.nome}"?`)) return;
    this.rankingService.desativarRankingCustom(r.id).subscribe({
      next: () => this.carregarRankings(),
      error: () => {},
    });
  }

  // ─── Modal Pontuar ────────────────────────────────────────────────────────

  abrirPontuar(): void {
    this.formPontuar.reset({ alunoId: '', pontos: 1, descricao: '' });
    this.erroModal.set('');
    this.showModalPontuar.set(true);
  }

  salvarPontos(): void {
    if (this.formPontuar.invalid) return;
    const r = this.rankingSelecionado();
    if (!r) return;
    this.salvando.set(true);
    this.erroModal.set('');
    const v = this.formPontuar.value;
    this.rankingService.lancarPontos(r.id, {
      alunoId: v.alunoId!,
      pontos: v.pontos!,
      descricao: v.descricao || undefined,
    }).subscribe({
      next: () => {
        this.salvando.set(false);
        this.showModalPontuar.set(false);
        this.carregarLeaderboard(r.id);
        this.lancamentos.set([]);
      },
      error: (e) => { this.salvando.set(false); this.erroModal.set(e?.error?.mensagem ?? 'Erro ao lançar'); },
    });
  }

  removerLancamento(id: string): void {
    if (!confirm('Remover este lançamento?')) return;
    this.rankingService.removerLancamento(id).subscribe({
      next: () => {
        this.lancamentos.update(list => list.filter(l => l.id !== id));
        const r = this.rankingSelecionado();
        if (r) this.carregarLeaderboard(r.id);
      },
      error: () => {},
    });
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  medalha(pos: number): string {
    if (pos === 1) return '🥇';
    if (pos === 2) return '🥈';
    if (pos === 3) return '🥉';
    return `#${pos}`;
  }

  fmtData(d?: string): string {
    if (!d) return '';
    return new Date(d + 'T00:00:00').toLocaleDateString('pt-BR');
  }

  tagPeriodo(r: RankingCustomDto): string {
    if (!r.dataInicio && !r.dataFim) return '';
    const i = r.dataInicio ? this.fmtData(r.dataInicio) : '...';
    const f = r.dataFim ? this.fmtData(r.dataFim) : '...';
    return `${i} → ${f}`;
  }
}
