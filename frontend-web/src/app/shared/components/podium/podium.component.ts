import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LeaderboardItemDto, NIVEL_CONFIG } from '../../../core/models/ranking.model';
import { NivelBadgeComponent } from '../nivel-badge/nivel-badge.component';

@Component({
  selector: 'app-podium',
  standalone: true,
  imports: [CommonModule, NivelBadgeComponent],
  template: `
    <div class="podium" *ngIf="top3.length">
      <!-- 2º lugar -->
      <div class="podium-slot silver" *ngIf="top3[1]">
        <div class="podium-avatar" [style.border-color]="cor(top3[1].nivel)">{{ inicial(top3[1].nomeAluno) }}</div>
        <div class="podium-name">{{ top3[1].nomeAluno }}</div>
        <app-nivel-badge [nivel]="top3[1].nivel" />
        <div class="podium-xp">{{ top3[1].xpPeriodo }} XP</div>
        <div class="podium-base silver-base"><span class="podium-medal">🥈</span> 2º</div>
      </div>
      <!-- 1º lugar -->
      <div class="podium-slot gold" *ngIf="top3[0]">
        <div class="podium-avatar gold-ring" [style.border-color]="cor(top3[0].nivel)">{{ inicial(top3[0].nomeAluno) }}</div>
        <div class="podium-name">{{ top3[0].nomeAluno }}</div>
        <app-nivel-badge [nivel]="top3[0].nivel" />
        <div class="podium-xp">{{ top3[0].xpPeriodo }} XP</div>
        <div class="podium-base gold-base"><span class="podium-medal">🥇</span> 1º</div>
      </div>
      <!-- 3º lugar -->
      <div class="podium-slot bronze" *ngIf="top3[2]">
        <div class="podium-avatar" [style.border-color]="cor(top3[2].nivel)">{{ inicial(top3[2].nomeAluno) }}</div>
        <div class="podium-name">{{ top3[2].nomeAluno }}</div>
        <app-nivel-badge [nivel]="top3[2].nivel" />
        <div class="podium-xp">{{ top3[2].xpPeriodo }} XP</div>
        <div class="podium-base bronze-base"><span class="podium-medal">🥉</span> 3º</div>
      </div>
    </div>
  `,
  styles: [`
    .podium { display: flex; align-items: flex-end; justify-content: center; gap: 12px; margin-bottom: 24px; }
    .podium-slot { display: flex; flex-direction: column; align-items: center; gap: 4px; animation: scale-in 0.4s ease; }
    @keyframes scale-in { from { transform: scale(0); opacity: 0; } to { transform: scale(1); opacity: 1; } }
    .podium-avatar { width: 52px; height: 52px; border-radius: 50%; background: #e0e7ff; color: #4f46e5; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 1.1rem; border: 3px solid; }
    .gold .podium-avatar { width: 64px; height: 64px; font-size: 1.3rem; }
    .podium-name { font-size: 0.75rem; font-weight: 600; color: var(--app-text-1); text-align: center; max-width: 80px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .podium-xp { font-size: 0.7rem; color: var(--app-text-3); }
    .podium-base { display: flex; align-items: center; gap: 4px; padding: 6px 12px; border-radius: 8px 8px 0 0; font-size: 0.75rem; font-weight: 700; margin-top: 4px; }
    .gold-base { background: #fef3c7; color: #92400e; padding: 10px 16px; }
    .silver-base { background: #f1f5f9; color: #475569; }
    .bronze-base { background: #fff7ed; color: #92400e; }
    .podium-medal { font-size: 1rem; }
  `]
})
export class PodiumComponent {
  @Input() top3: LeaderboardItemDto[] = [];
  inicial(nome: string): string { return (nome ?? 'U').charAt(0).toUpperCase(); }
  cor(nivel: string): string { return NIVEL_CONFIG[nivel]?.cor ?? '#B8860B'; }
}
