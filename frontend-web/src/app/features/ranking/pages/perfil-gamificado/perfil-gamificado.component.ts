import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { RankingService } from '../../../../core/services/ranking.service';
import { PerfilGamificadoDto, ConquistaDto, NIVEL_CONFIG } from '../../../../core/models/ranking.model';
import { NivelBadgeComponent } from '../../../../shared/components/nivel-badge/nivel-badge.component';
import { XpProgressComponent } from '../../../../shared/components/xp-progress/xp-progress.component';

@Component({
  selector: 'app-perfil-gamificado',
  standalone: true,
  imports: [CommonModule, RouterLink, NivelBadgeComponent, XpProgressComponent],
  templateUrl: './perfil-gamificado.component.html',
})
export class PerfilGamificadoComponent implements OnInit {
  perfil = signal<PerfilGamificadoDto | null>(null);
  carregando = signal(true);
  erro = signal('');
  conquistaSelecionada = signal<ConquistaDto | null>(null);
  animacaoNovaConquista = signal<ConquistaDto | null>(null);

  constructor(private route: ActivatedRoute, private rankingService: RankingService) {}

  ngOnInit(): void {
    const alunoId = this.route.snapshot.paramMap.get('alunoId') ?? '';
    this.rankingService.getPerfilGamificado(alunoId).subscribe({
      next: p => {
        this.perfil.set(p);
        this.carregando.set(false);
        this.verificarNovasConquistas(p.conquistasDesbloqueadas);
      },
      error: () => { this.erro.set('Erro ao carregar perfil.'); this.carregando.set(false); }
    });
  }

  private verificarNovasConquistas(conquistas: import('../../../../core/models/ranking.model').ConquistaDto[]): void {
    const hoje = new Date().toISOString().slice(0, 10);
    const nova = conquistas
      .filter(c => c.desbloqueadaEm?.startsWith(hoje))
      .sort((a, b) => (b.desbloqueadaEm ?? '').localeCompare(a.desbloqueadaEm ?? ''))[0];
    if (!nova) return;
    this.animacaoNovaConquista.set(nova);
    setTimeout(() => this.animacaoNovaConquista.set(null), 3500);
  }

  nivelCor(nivel: string): string { return NIVEL_CONFIG[nivel]?.cor ?? '#B8860B'; }
  avatarInicial(nome: string): string { return (nome ?? 'U').charAt(0).toUpperCase(); }

  tipoIcone(tipo: string): string {
    const map: Record<string, string> = {
      Presenca: '✅', SequenciaPresenca: '🔥', Graduacao: '🎖️',
      PrimeiroCheckinMes: '⭐', ConquistaDesbloqueada: '🏅'
    };
    return map[tipo] ?? '⚡';
  }

  fecharModal(): void { this.conquistaSelecionada.set(null); }
}
