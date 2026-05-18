import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormControl, FormGroup, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css'],
})
export class LoginComponent {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);

  readonly carregando = signal(false);
  readonly erro = signal<string | null>(null);
  readonly mostrarSenha = signal(false);

  readonly form = new FormGroup({
    email: new FormControl('', {
      nonNullable: true,
      validators: [Validators.required, Validators.email],
    }),
    senha: new FormControl('', {
      nonNullable: true,
      validators: [Validators.required, Validators.minLength(6)],
    }),
  });

  entrar(): void {
    if (this.form.invalid || this.carregando()) return;

    this.carregando.set(true);
    this.erro.set(null);

    const { email, senha } = this.form.getRawValue();

    this.authService.login({ email, senha }).subscribe({
      next: (res) => {
        if (res.sucesso) {
          this.router.navigate(['/app/dashboard']);
        } else {
          this.erro.set(res.mensagem ?? 'Credenciais inválidas.');
          this.carregando.set(false);
        }
      },
      error: (err) => {
        const msg = err?.error?.mensagem;
        this.erro.set(msg ?? 'Não foi possível conectar ao servidor. Tente novamente.');
        this.carregando.set(false);
      },
    });
  }

  get emailInvalido(): boolean {
    const ctrl = this.form.get('email');
    return !!(ctrl?.invalid && ctrl.touched);
  }

  get senhaInvalida(): boolean {
    const ctrl = this.form.get('senha');
    return !!(ctrl?.invalid && ctrl.touched);
  }

  readonly year = new Date().getFullYear();
}
