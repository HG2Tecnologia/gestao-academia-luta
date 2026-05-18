import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormControl, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

function senhasIguaisValidator(confirmCtrl: FormControl): (ctrl: AbstractControl) => ValidationErrors | null {
  return (ctrl: AbstractControl) => {
    return ctrl.value === confirmCtrl.value ? null : { senhasDiferentes: true };
  };
}

@Component({
  selector: 'app-reset-password',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  template: `
    <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-900 via-primary-800 to-primary-700 px-4">
      <div class="w-full max-w-md">
        <div class="bg-white rounded-2xl shadow-2xl p-8">
          <h2 class="text-xl font-semibold text-surface-800 mb-2">Criar nova senha</h2>

          @if (!token()) {
            <div class="p-4 rounded-lg bg-red-50 border border-red-200 text-sm text-red-700">
              Link inválido. Solicite um novo link de recuperação.
            </div>
            <a routerLink="/forgot-password" class="mt-4 inline-block text-sm text-primary-600 hover:text-primary-700">
              Solicitar novo link
            </a>
          } @else if (concluido()) {
            <div class="p-4 rounded-lg bg-green-50 border border-green-200 text-sm text-green-700 mb-4">
              Senha redefinida com sucesso!
            </div>
            <a routerLink="/login" class="btn-primary w-full text-center block">Ir para o login</a>
          } @else {
            <p class="text-sm text-surface-500 mb-6">Digite sua nova senha abaixo.</p>

            @if (erro()) {
              <div class="p-3 rounded-lg bg-red-50 border border-red-200 text-sm text-red-700 mb-4">{{ erro() }}</div>
            }

            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-surface-700 mb-1.5">Nova senha</label>
                <input
                  type="password"
                  [formControl]="senhaCtrl"
                  placeholder="Mínimo 6 caracteres"
                  class="input-field"
                  autocomplete="new-password" />
              </div>
              <div>
                <label class="block text-sm font-medium text-surface-700 mb-1.5">Confirmar senha</label>
                <input
                  type="password"
                  [formControl]="confirmCtrl"
                  placeholder="Repita a senha"
                  class="input-field"
                  autocomplete="new-password" />
                @if (confirmCtrl.touched && confirmCtrl.errors?.['senhasDiferentes']) {
                  <p class="text-xs text-red-600 mt-1">As senhas não coincidem.</p>
                }
              </div>
              <button
                (click)="salvar()"
                [disabled]="senhaCtrl.invalid || confirmCtrl.invalid || salvando()"
                class="btn-primary w-full">
                {{ salvando() ? 'Salvando...' : 'Redefinir senha' }}
              </button>
            </div>
          }
        </div>
      </div>
    </div>
  `,
})
export class ResetPasswordComponent implements OnInit {
  private readonly authService = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  readonly token = signal('');
  readonly concluido = signal(false);
  readonly salvando = signal(false);
  readonly erro = signal('');

  readonly senhaCtrl = new FormControl('', [Validators.required, Validators.minLength(6)]);
  readonly confirmCtrl: FormControl;

  constructor() {
    this.confirmCtrl = new FormControl('', [Validators.required, senhasIguaisValidator(this.senhaCtrl as FormControl)]);
    this.senhaCtrl.valueChanges.subscribe(() => this.confirmCtrl.updateValueAndValidity());
  }

  ngOnInit(): void {
    const t = this.route.snapshot.queryParamMap.get('token') ?? '';
    this.token.set(t);
  }

  salvar(): void {
    if (this.senhaCtrl.invalid || this.confirmCtrl.invalid) return;
    this.salvando.set(true);
    this.erro.set('');

    this.authService.resetPassword(this.token(), this.senhaCtrl.value!).subscribe({
      next: (res) => {
        this.salvando.set(false);
        if (res.sucesso) {
          this.concluido.set(true);
        } else {
          this.erro.set(res.mensagem ?? 'Erro ao redefinir senha.');
        }
      },
      error: (err) => {
        this.salvando.set(false);
        this.erro.set(err.error?.mensagem ?? 'Link inválido ou expirado. Solicite um novo link.');
      },
    });
  }
}
