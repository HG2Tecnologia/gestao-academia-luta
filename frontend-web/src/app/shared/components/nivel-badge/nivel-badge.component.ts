import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NIVEL_CONFIG } from '../../../core/models/ranking.model';

@Component({
  selector: 'app-nivel-badge',
  standalone: true,
  imports: [CommonModule],
  template: `
    <span class="nivel-badge" [style.background]="bg + '22'" [style.color]="bg" [style.border]="'1px solid ' + bg + '55'">
      <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l2.4 7.4H22l-6.2 4.5 2.4 7.4L12 17l-6.2 4.3 2.4-7.4L2 9.4h7.6z"/></svg>
      {{ label }}
    </span>
  `,
  styles: [`
    .nivel-badge {
      display: inline-flex; align-items: center; gap: 4px;
      padding: 2px 8px; border-radius: 99px; font-size: 0.7rem; font-weight: 600;
    }
  `]
})
export class NivelBadgeComponent {
  @Input() nivel = 'Iniciante';

  get bg(): string { return NIVEL_CONFIG[this.nivel]?.cor ?? '#94a3b8'; }
  get label(): string { return NIVEL_CONFIG[this.nivel]?.label ?? this.nivel; }
}
