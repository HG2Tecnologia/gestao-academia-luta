import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormControl, FormGroup, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { FirebaseAuthService, LoginSemAcessoStaffError } from '../../../core/services/firebase-auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css'],
})
export class LoginComponent {
  private readonly authService = inject(FirebaseAuthService);
  private readonly router = inject(Router);

  readonly carregando = signal(false);
  readonly erro = signal<string | null>(null);
  readonly mostrarSenha = signal(false);

  readonly form = new FormGroup({
    identificador: new FormControl('', {
      nonNullable: true,
      validators: [Validators.required, Validators.minLength(3)],
    }),
    senha: new FormControl('', {
      nonNullable: true,
      validators: [Validators.required, Validators.minLength(6)],
    }),
  });

  async entrar(): Promise<void> {
    if (this.form.invalid || this.carregando()) return;

    this.carregando.set(true);
    this.erro.set(null);

    const { identificador, senha } = this.form.getRawValue();

    try {
      const user = await this.authService.login(identificador, senha);

      if (user.mustChangePassword) {
        this.router.navigate(['/troca-senha-obrigatoria']);
        return;
      }

      this.router.navigate(['/app/dashboard']);
    } catch (err) {
      this.erro.set(this.mensagemDeErro(err));
    } finally {
      this.carregando.set(false);
    }
  }

  private mensagemDeErro(err: unknown): string {
    if (err instanceof LoginSemAcessoStaffError) {
      return 'Essa conta não tem acesso de equipe (Admin/Secretaria/Professor). O CRM não é usado por alunos.';
    }
    const code = (err as { code?: string } | null)?.code;
    switch (code) {
      case 'auth/invalid-credential':
      case 'auth/wrong-password':
      case 'auth/user-not-found':
        return 'E-mail/telefone ou senha incorretos.';
      case 'auth/too-many-requests':
        return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
      case 'auth/network-request-failed':
        return 'Sem conexão. Verifique sua internet e tente de novo.';
      default:
        return (err as { message?: string } | null)?.message ?? 'Não foi possível entrar. Tente novamente.';
    }
  }

  get identificadorInvalido(): boolean {
    const ctrl = this.form.get('identificador');
    return !!(ctrl?.invalid && ctrl.touched);
  }

  get senhaInvalida(): boolean {
    const ctrl = this.form.get('senha');
    return !!(ctrl?.invalid && ctrl.touched);
  }

  readonly year = new Date().getFullYear();
}
