import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormControl, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  template: `
    <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-900 via-primary-800 to-primary-700 px-4">
      <div class="w-full max-w-md">
        <div class="bg-white rounded-2xl shadow-2xl p-8">
          <h2 class="text-xl font-semibold text-surface-800 mb-2">Recuperar senha</h2>
          <p class="text-sm text-surface-500 mb-6">
            Informe seu e-mail e enviaremos um link para redefinir sua senha.
          </p>

          @if (enviado()) {
            <div class="p-4 rounded-lg bg-green-50 border border-green-200 text-sm text-green-700">
              Se este e-mail estiver cadastrado, você receberá as instruções em breve. Verifique sua caixa de entrada.
            </div>
          } @else {
            <div class="space-y-4">
              @if (erro()) {
                <div class="p-3 rounded-lg bg-red-50 border border-red-200 text-sm text-red-700">{{ erro() }}</div>
              }
              <div>
                <label class="block text-sm font-medium text-surface-700 mb-1.5">E-mail</label>
                <input
                  type="email"
                  [formControl]="emailCtrl"
                  placeholder="seu@email.com"
                  class="input-field"
                  autocomplete="email" />
              </div>
              <button
                (click)="enviar()"
                [disabled]="emailCtrl.invalid || enviando()"
                class="btn-primary w-full">
                {{ enviando() ? 'Enviando...' : 'Enviar instruções' }}
              </button>
            </div>
          }

          <a routerLink="/login" class="mt-6 flex items-center gap-1.5 text-sm text-primary-600 hover:text-primary-700">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            Voltar ao login
          </a>
        </div>
      </div>
    </div>
  `,
})
export class ForgotPasswordComponent {
  private readonly authService = inject(AuthService);

  readonly emailCtrl = new FormControl('', [Validators.required, Validators.email]);
  readonly enviado = signal(false);
  readonly enviando = signal(false);
  readonly erro = signal('');

  enviar(): void {
    if (this.emailCtrl.invalid) return;
    this.enviando.set(true);
    this.erro.set('');

    this.authService.forgotPassword(this.emailCtrl.value!).subscribe({
      next: () => {
        this.enviando.set(false);
        this.enviado.set(true);
      },
      error: () => {
        this.enviando.set(false);
        this.erro.set('Ocorreu um erro. Tente novamente.');
      },
    });
  }
}
