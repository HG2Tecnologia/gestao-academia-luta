import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { FirebaseAuthService } from '../../../core/services/firebase-auth.service';

/**
 * Espelho de `troca_senha_obrigatoria_screen.dart`: quem entra com senha
 * temporária só segue depois de definir a própria senha.
 */
@Component({
  selector: 'app-troca-senha',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <main class="pagina">
      <form class="form-card cartao" (ngSubmit)="concluir()">
        <h1>Defina sua senha definitiva</h1>
        <p>Sua academia gerou uma senha temporária para você. Antes de continuar, defina uma senha definitiva que só você conhece.</p>

        @if (erro()) { <div class="alert-error">{{ erro() }}</div> }

        <div class="form-group">
          <label class="form-label" for="nova">Nova senha</label>
          <input id="nova" name="nova" type="password" class="form-input" autocomplete="new-password" [(ngModel)]="nova" />
        </div>
        <div class="form-group">
          <label class="form-label" for="confirmar">Confirme a nova senha</label>
          <input id="confirmar" name="confirmar" type="password" class="form-input" autocomplete="new-password" [(ngModel)]="confirmar" />
        </div>

        <button type="submit" class="btn-primary" [disabled]="salvando()">
          {{ salvando() ? 'Salvando...' : 'Salvar e continuar' }}
        </button>
        <button type="button" class="btn-secondary" (click)="sair()" [disabled]="salvando()">Sair</button>
      </form>
    </main>
  `,
  styles: [`
    .pagina { min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 24px; background: var(--app-bg); }
    .cartao { width: 100%; max-width: 420px; }
    h1 { font-size: 1.25rem; margin: 0; color: var(--app-text-1); }
    p { font-size: 0.875rem; margin: 0; color: var(--app-text-2); }
  `],
})
export class TrocaSenhaComponent {
  private readonly authService = inject(FirebaseAuthService);
  private readonly router = inject(Router);

  nova = '';
  confirmar = '';
  readonly salvando = signal(false);
  readonly erro = signal('');

  async concluir(): Promise<void> {
    if (!this.nova || !this.confirmar) { this.erro.set('Campo obrigatório.'); return; }
    if (this.nova.length < 6) { this.erro.set('Mínimo de 6 caracteres.'); return; }
    if (this.nova !== this.confirmar) { this.erro.set('As senhas não coincidem.'); return; }
    this.salvando.set(true);
    this.erro.set('');
    try {
      await this.authService.concluirTrocaDeSenha(this.nova);
      await this.router.navigate(['/app/dashboard']);
    } catch (err: any) {
      this.erro.set(
        err?.code === 'auth/requires-recent-login'
          ? 'Por segurança, saia e entre de novo com a senha temporária antes de trocá-la.'
          : err?.code
            ? `Erro ao definir a nova senha (${err.code}).`
            : 'Erro inesperado. Tente novamente.',
      );
    } finally {
      this.salvando.set(false);
    }
  }

  sair(): void {
    this.authService.logout();
  }
}
