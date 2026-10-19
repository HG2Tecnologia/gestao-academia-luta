import { Component, inject } from '@angular/core';
import { DialogService } from '../../../core/services/dialog.service';

@Component({
  selector: 'app-dialog',
  standalone: true,
  template: `
    @if (dialogService.state(); as s) {
      <div class="dialog-backdrop" (click)="dialogService.resolveWith(false)"></div>
      <div class="dialog-box" role="alertdialog" aria-modal="true">
        @if (s.titulo) { <h3 class="dialog-title">{{ s.titulo }}</h3> }
        <p class="dialog-message">{{ s.mensagem }}</p>
        <div class="dialog-actions">
          @if (s.textoCancelar) {
            <button class="btn-secondary" (click)="dialogService.resolveWith(false)">{{ s.textoCancelar }}</button>
          }
          <button [class]="s.perigoso ? 'btn-danger' : 'btn-primary'" (click)="dialogService.resolveWith(true)">
            {{ s.textoConfirmar }}
          </button>
        </div>
      </div>
    }
  `,
  styles: [`
    .dialog-backdrop {
      position: fixed; inset: 0; background: rgba(0,0,0,0.45); z-index: 200;
    }
    .dialog-box {
      position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);
      background: var(--app-surface); border-radius: 14px; padding: 24px 28px;
      z-index: 201; box-shadow: 0 12px 40px rgba(0,0,0,0.2);
      display: flex; flex-direction: column; gap: 14px;
      min-width: 300px; max-width: 420px;
    }
    .dialog-title { margin: 0; font-size: 1.05rem; font-weight: 700; color: var(--app-text-1); }
    .dialog-message { margin: 0; font-size: 0.9rem; color: var(--app-text-2); line-height: 1.5; white-space: pre-line; }
    .dialog-actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 4px; }
  `],
})
export class DialogComponent {
  readonly dialogService = inject(DialogService);
}
