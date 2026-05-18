import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  ReactiveFormsModule,
  FormControl,
  FormGroup,
  Validators,
  AbstractControl,
  ValidationErrors,
} from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

function senhasIguaisValidator(group: AbstractControl): ValidationErrors | null {
  const senha = group.get('senha')?.value;
  const confirmar = group.get('confirmarSenha')?.value;
  return senha === confirmar ? null : { senhasDiferentes: true };
}

@Component({
  selector: 'app-cadastro',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './cadastro.component.html',
  styleUrls: ['./cadastro.component.css'],
})
export class CadastroComponent {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);

  readonly carregando = signal(false);
  readonly erro = signal<string | null>(null);
  readonly etapa = signal<1 | 2>(1);
  readonly mostrarSenha = signal(false);
  readonly mostrarConfirmarSenha = signal(false);
  readonly year = new Date().getFullYear();

  readonly beneficios = [
    '14 dias grátis, sem cartão de crédito',
    'Gestão completa de alunos e turmas',
    'Controle de mensalidades e cobranças',
    'Ranking e progressão de belts',
    'Suporte em português 7 dias por semana',
  ];

  readonly form = new FormGroup(
    {
      nome: new FormControl('', {
        nonNullable: true,
        validators: [Validators.required, Validators.minLength(3)],
      }),
      email: new FormControl('', {
        nonNullable: true,
        validators: [Validators.required, Validators.email],
      }),
      senha: new FormControl('', {
        nonNullable: true,
        validators: [Validators.required, Validators.minLength(8)],
      }),
      confirmarSenha: new FormControl('', {
        nonNullable: true,
        validators: [Validators.required],
      }),
      nomeAcademia: new FormControl('', {
        nonNullable: true,
        validators: [Validators.required, Validators.minLength(3)],
      }),
      subdominio: new FormControl('', {
        nonNullable: true,
        validators: [
          Validators.required,
          Validators.minLength(3),
          Validators.pattern(/^[a-z0-9-]+$/),
        ],
      }),
      telefone: new FormControl('', { nonNullable: true }),
    },
    { validators: senhasIguaisValidator }
  );

  avancar(): void {
    const campos = ['nome', 'email', 'senha', 'confirmarSenha'];
    campos.forEach((c) => this.form.get(c)?.markAsTouched());

    const etapa1Valida =
      !this.form.get('nome')?.invalid &&
      !this.form.get('email')?.invalid &&
      !this.form.get('senha')?.invalid &&
      !this.form.get('confirmarSenha')?.invalid &&
      !this.form.hasError('senhasDiferentes');

    if (etapa1Valida) this.etapa.set(2);
  }

  cadastrar(): void {
    if (this.form.invalid || this.carregando()) return;

    this.carregando.set(true);
    this.erro.set(null);

    const { nome, email, senha, nomeAcademia, subdominio, telefone } = this.form.getRawValue();

    this.authService
      .register({ nome, email, senha, nomeAcademia, subdominio, telefone: telefone || undefined })
      .subscribe({
        next: (res) => {
          if (res.sucesso) {
            this.router.navigate(['/app/dashboard']);
          } else {
            this.erro.set(res.mensagem ?? 'Erro ao criar conta. Tente novamente.');
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

  onTelefoneInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    let digits = input.value.replace(/\D/g, '').slice(0, 11);
    let formatted = '';
    if (digits.length > 0) formatted = '(' + digits.slice(0, 2);
    if (digits.length > 2) formatted += ') ' + digits.slice(2, digits.length > 10 ? 7 : 6);
    if (digits.length > 6 && digits.length <= 10) formatted += '-' + digits.slice(6, 10);
    if (digits.length > 10) formatted += '-' + digits.slice(7, 11);
    input.value = formatted;
    this.form.get('telefone')?.setValue(formatted, { emitEvent: false });
  }

  gerarSubdominio(): void {
    const nome = this.form.get('nomeAcademia')?.value ?? '';
    const slug = nome
      .toLowerCase()
      .normalize('NFD')
      .replace(/[̀-ͯ]/g, '')
      .replace(/[^a-z0-9\s-]/g, '')
      .trim()
      .replace(/\s+/g, '-');
    this.form.get('subdominio')?.setValue(slug);
  }

  campo(name: string): boolean {
    const ctrl = this.form.get(name);
    return !!(ctrl?.invalid && ctrl.touched);
  }

  get senhasDiferentes(): boolean {
    return this.form.hasError('senhasDiferentes') && !!this.form.get('confirmarSenha')?.touched;
  }
}
