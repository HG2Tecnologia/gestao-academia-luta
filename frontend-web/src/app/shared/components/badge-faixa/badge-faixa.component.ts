import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-badge-faixa',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="belt" [class]="'belt--' + tamanho" [title]="labelCompleto">
      <div class="belt__main" [style.background-color]="cor"></div>
      <div class="belt__tip" [style.background-color]="corBarra" *ngIf="temGraus">
        <div class="belt__stripe" *ngFor="let s of grausArr"></div>
        <div class="belt__stripe belt__stripe--empty" *ngFor="let s of vaziosArr"></div>
      </div>
    </div>
  `,
  styles: [`
    .belt {
      display: inline-flex;
      align-items: stretch;
      border-radius: 2px;
      border: 1.5px solid rgba(255,255,255,0.35);
      overflow: hidden;
      flex-shrink: 0;
    }
    .belt--sm  { height: 10px; }
    .belt--md  { height: 14px; }
    .belt--lg  { height: 20px; }
    .belt__main {
      flex: 1 1 auto;
      min-width: 28px;
    }
    .belt--sm  .belt__main { min-width: 24px; }
    .belt--lg  .belt__main { min-width: 40px; }
    .belt__tip {
      display: flex;
      align-items: center;
      gap: 2px;
      padding: 0 3px;
      flex-shrink: 0;
    }
    .belt__stripe {
      width: 2px;
      height: 70%;
      background: rgba(255,255,255,0.9);
      border-radius: 1px;
    }
    .belt__stripe--empty {
      background: transparent;
      border: 1px solid rgba(255,255,255,0.25);
    }
  `],
})
export class BadgeFaixaComponent {
  @Input() cor = '#FFFFFF';
  @Input() corBarra = '#000000';
  @Input() nome = '';
  @Input() grau = 0;
  @Input() maxGraus = 4;
  @Input() temGraus = false;
  @Input() tamanho: 'sm' | 'md' | 'lg' = 'md';

  get grausArr(): number[] { return Array(this.grau).fill(0); }
  get vaziosArr(): number[] { return Array(Math.max(0, this.maxGraus - this.grau)).fill(0); }
  get labelCompleto(): string {
    if (!this.temGraus || this.grau === 0) return this.nome;
    return `${this.nome} — ${this.grau}º grau`;
  }
}
