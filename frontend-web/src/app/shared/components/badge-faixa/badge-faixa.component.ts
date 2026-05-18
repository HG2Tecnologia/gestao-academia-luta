import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-badge-faixa',
  standalone: true,
  imports: [CommonModule],
  template: `
    <span
      class="badge-faixa"
      [style.background-color]="cor"
      [style.width.px]="tamanhos[tamanho]"
      [style.height.px]="tamanhos[tamanho]"
      [title]="nome"
    ></span>
  `,
  styles: [`
    .badge-faixa {
      display: inline-block;
      border-radius: 2px;
      border: 2px solid rgba(255,255,255,0.6);
      flex-shrink: 0;
    }
  `],
})
export class BadgeFaixaComponent {
  @Input() cor = '#FFFFFF';
  @Input() nome = '';
  @Input() tamanho: 'sm' | 'md' | 'lg' = 'md';

  readonly tamanhos = { sm: 14, md: 20, lg: 28 };
}
