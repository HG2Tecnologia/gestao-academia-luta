import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { AcademiaService } from '../../../../core/services/academia.service';
import { AuthService } from '../../../../core/services/auth.service';
import { UsuarioService, MeuPerfilDto } from '../../../../core/services/usuario.service';
import { AcademiaDto } from '../../../../core/models/academia.model';

@Component({
  selector: 'app-configuracoes-geral',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule],
  templateUrl: './configuracoes-geral.component.html',
})
export class ConfiguracoesGeralComponent implements OnInit {
  private readonly academiaService = inject(AcademiaService);
  private readonly authService = inject(AuthService);
  private readonly usuarioService = inject(UsuarioService);
  private readonly fb = inject(FormBuilder);

  readonly academia = signal<AcademiaDto | null>(null);
  readonly carregando = signal(true);
  readonly salvando = signal(false);
  readonly salvoOk = signal(false);
  readonly erro = signal('');

  readonly modalSenhaAberto = signal(false);
  readonly salvandoSenha = signal(false);
  readonly erroSenha = signal('');
  readonly senhaOk = signal(false);

  // Meu Perfil
  readonly meuPerfil = signal<MeuPerfilDto | null>(null);
  readonly salvandoPerfil = signal(false);
  readonly perfilOk = signal(false);
  readonly erroPerfil = signal('');

  readonly formInfo = this.fb.group({
    nome: ['', Validators.required],
    email: ['', [Validators.required, Validators.email]],
    telefone: [''],
  });

  readonly formPerfil = this.fb.group({
    nome: ['', Validators.required],
    telefone: [''],
  });

  readonly formSenha = this.fb.group({
    senhaAtual: ['', Validators.required],
    novaSenha: ['', [Validators.required, Validators.minLength(6)]],
    confirmarSenha: ['', Validators.required],
  });

  ngOnInit(): void {
    this.academiaService.getCurrent().subscribe({
      next: (res) => {
        if (res.dados) {
          this.academia.set(res.dados);
          this.formInfo.patchValue({
            nome: res.dados.nome,
            email: res.dados.email,
            telefone: res.dados.telefone ?? '',
          });
        }
        this.carregando.set(false);
      },
      error: () => { this.erro.set('Erro ao carregar dados da academia.'); this.carregando.set(false); },
    });

    this.usuarioService.getMeuPerfil().subscribe({
      next: (res) => {
        if (res.dados) {
          this.meuPerfil.set(res.dados);
          this.formPerfil.patchValue({ nome: res.dados.nome, telefone: res.dados.telefone ?? '' });
        }
      },
    });
  }

  salvarPerfil(): void {
    if (this.formPerfil.invalid) { this.formPerfil.markAllAsTouched(); return; }
    this.salvandoPerfil.set(true);
    this.perfilOk.set(false);
    this.erroPerfil.set('');
    const v = this.formPerfil.value;
    this.usuarioService.atualizarMeuPerfil({ nome: v.nome!, telefone: v.telefone || undefined }).subscribe({
      next: (res) => {
        this.salvandoPerfil.set(false);
        if (res.sucesso) { this.meuPerfil.set(res.dados ?? null); this.perfilOk.set(true); }
        else { this.erroPerfil.set(res.mensagem ?? 'Erro ao salvar.'); }
      },
      error: (err) => { this.salvandoPerfil.set(false); this.erroPerfil.set(err.error?.mensagem ?? 'Erro ao salvar.'); },
    });
  }

  salvarInfo(): void {
    if (this.formInfo.invalid) { this.formInfo.markAllAsTouched(); return; }
    this.salvando.set(true);
    this.salvoOk.set(false);
    this.erro.set('');
    const v = this.formInfo.value;
    this.academiaService.update({
      nome: v.nome!,
      email: v.email!,
      telefone: v.telefone || undefined,
    }).subscribe({
      next: (res) => {
        if (res.sucesso) { this.academia.set(res.dados ?? null); this.salvoOk.set(true); }
        else { this.erro.set(res.mensagem ?? 'Erro ao salvar.'); }
        this.salvando.set(false);
      },
      error: (err) => { this.erro.set(err.error?.mensagem ?? 'Erro ao salvar.'); this.salvando.set(false); },
    });
  }

  abrirModalSenha(): void { this.formSenha.reset(); this.erroSenha.set(''); this.senhaOk.set(false); this.modalSenhaAberto.set(true); }
  fecharModalSenha(): void { this.modalSenhaAberto.set(false); }

  salvarSenha(): void {
    if (this.formSenha.invalid) { this.formSenha.markAllAsTouched(); return; }
    const v = this.formSenha.value;
    if (v.novaSenha !== v.confirmarSenha) { this.erroSenha.set('As senhas não coincidem.'); return; }
    this.salvandoSenha.set(true);
    this.erroSenha.set('');
    this.authService.alterarSenha(v.senhaAtual!, v.novaSenha!).subscribe({
      next: (res) => {
        this.salvandoSenha.set(false);
        if (res.sucesso) { this.senhaOk.set(true); setTimeout(() => this.fecharModalSenha(), 1800); }
        else { this.erroSenha.set(res.mensagem ?? 'Erro ao alterar senha.'); }
      },
      error: (err) => {
        this.salvandoSenha.set(false);
        this.erroSenha.set(err.error?.mensagem ?? 'Erro ao alterar senha.');
      },
    });
  }

  iniciais(nome: string): string { return nome.split(' ').slice(0, 2).map(p => p[0]).join('').toUpperCase(); }
}
