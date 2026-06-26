import { Component, Input, OnChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NIVEL_CONFIG } from '../../../core/models/ranking.model';

@Component({
  selector: 'app-xp-progress',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="xp-wrap">
      <div class="xp-labels">
        <span class="xp-atual">{{ xpAtual }} XP</span>
        <span class="xp-meta" *ngIf="xpParaProximoNivel > 0">+{{ xpParaProximoNivel }} para {{ proximoNivel }}</span>
        <span class="xp-meta" *ngIf="xpParaProximoNivel === 0">Nível máximo!</span>
      </div>
      <div class="xp-bar-bg">
        <div class="xp-bar-fill" [style.width.%]="pct" [style.background]="cor"></div>
      </div>
    </div>
  `,
  styles: [`
    .xp-wrap { display: flex; flex-direction: column; gap: 6px; }
    .xp-labels { display: flex; justify-content: space-between; font-size: 0.75rem; }
    .xp-atual { font-weight: 700; color: var(--app-text-1); }
    .xp-meta { color: var(--app-text-3); }
    .xp-bar-bg { height: 8px; background: var(--app-border); border-radius: 99px; overflow: hidden; }
    .xp-bar-fill { height: 100%; border-radius: 99px; transition: width 1s ease; }
  `]
})
export class XpProgressComponent implements OnChanges {
  @Input() xpAtual = 0;
  @Input() xpParaProximoNivel = 0;
  @Input() nivel = 'Iniciante';

  pct = 0;
  cor = '#B8860B';

  readonly LIMITES: Record<string, [number, number]> = {
    Iniciante: [0, 200],
    Guerreiro: [200, 500],
    Veterano:  [500, 1000],
    Elite:     [1000, 2000],
    Mestre:    [2000, 2000],
  };

  readonly PROXIMO: Record<string, string> = {
    Iniciante: 'Guerreiro',
    Guerreiro: 'Veterano',
    Veterano:  'Elite',
    Elite:     'Mestre',
    Mestre:    '',
  };

  get proximoNivel(): string { return this.PROXIMO[this.nivel] ?? ''; }

  ngOnChanges(): void {
    const [min, max] = this.LIMITES[this.nivel] ?? [0, 200];
    this.pct = max > min ? Math.min(100, ((this.xpAtual - min) / (max - min)) * 100) : 100;
    this.cor = NIVEL_CONFIG[this.nivel]?.cor ?? '#B8860B';
  }
}
