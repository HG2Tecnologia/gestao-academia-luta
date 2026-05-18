import { Component, OnDestroy, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { RankingService } from '../../../../core/services/ranking.service';
import { TurmaService } from '../../../../core/services/turma.service';
import { AuthService } from '../../../../core/services/auth.service';
import { SignalrService } from '../../../../core/services/signalr.service';
import { LeaderboardDto, LeaderboardItemDto, NIVEL_CONFIG } from '../../../../core/models/ranking.model';
import { NivelBadgeComponent } from '../../../../shared/components/nivel-badge/nivel-badge.component';
import { PodiumComponent } from '../../../../shared/components/podium/podium.component';

@Component({
  selector: 'app-leaderboard',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, NivelBadgeComponent, PodiumComponent],
  templateUrl: './leaderboard.component.html',
})
export class LeaderboardComponent implements OnInit, OnDestroy {
  periodo = signal<'mensal' | 'historico'>('mensal');
  turmaId = signal<string>('');
  leaderboard = signal<LeaderboardDto | null>(null);
  turmas = signal<any[]>([]);
  carregando = signal(true);
  erro = signal('');

  constructor(
    private rankingService: RankingService,
    private turmaService: TurmaService,
    readonly authService: AuthService,
    private signalr: SignalrService,
  ) {}

  ngOnInit(): void {
    this.turmaService.getAll({ ativo: true }).subscribe(r => this.turmas.set(r.dados ?? []));
    this.carregar();
    this.conectarSignalR();
  }

  ngOnDestroy(): void {
    this.signalr.stopConnection();
  }

  private conectarSignalR(): void {
    const user = this.authService.currentUser();
    if (!user) return;
    const token = localStorage.getItem('af_access_token') ?? '';
    const academiaId = user.academia_id ?? '';
    if (!academiaId) return;

    this.signalr.startConnection(academiaId, token)
      .then(() => {
        this.signalr.onRankingAtualizado(item => {
          const lb = this.leaderboard();
          if (!lb) return;
          const items = lb.items.map(i => i.alunoId === item.alunoId ? { ...i, ...item } : i);
          this.leaderboard.set({ ...lb, items });
        });
      })
      .catch(() => {
        // SignalR failure is non-blocking — data loading continues regardless
      });
  }

  carregar(): void {
    this.carregando.set(true);
    this.erro.set('');

    const obs = this.turmaId()
      ? this.rankingService.getLeaderboardTurma(this.turmaId(), this.periodo())
      : this.rankingService.getLeaderboardAcademia(this.periodo());

    obs.subscribe({
      next: lb => {
        this.leaderboard.set(lb);
        this.carregando.set(false);
      },
      error: (err) => {
        const status = err?.status ?? 0;
        if (status === 0) {
          this.erro.set('Não foi possível conectar ao servidor.');
        } else {
          this.erro.set(`Erro ao carregar ranking (${status}).`);
        }
        this.carregando.set(false);
      },
    });
  }

  get top3(): LeaderboardItemDto[] { return this.leaderboard()?.items.slice(0, 3) ?? []; }
  get restante(): LeaderboardItemDto[] { return this.leaderboard()?.items.slice(3) ?? []; }

  alternarPeriodo(p: 'mensal' | 'historico'): void { this.periodo.set(p); this.carregar(); }
  alternarTurma(id: string): void { this.turmaId.set(id); this.carregar(); }

  avatarInicial(nome: string): string { return (nome ?? 'U').charAt(0).toUpperCase(); }
  nivelCor(nivel: string): string { return NIVEL_CONFIG[nivel]?.cor ?? '#6366f1'; }

  get usuarioLogado() { return this.authService.currentUser(); }
}
