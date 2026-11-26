import { Component, inject, signal, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { FuncionarioService } from '../../../../core/services/funcionario.service';
import { FuncionarioListaDto } from '../../../../core/models/funcionario.model';
import { AcessoService } from '../../../../core/services/acesso.service';
import { FirebaseAuthService } from '../../../../core/services/firebase-auth.service';
import { temPermissao } from '../../../../core/models/stored-user.model';

@Component({
  selector: 'app-funcionarios-lista',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './funcionarios-lista.component.html',
})
export class FuncionariosListaComponent implements OnInit, OnDestroy {
  private readonly funcionarioService = inject(FuncionarioService);
  private readonly acessoService = inject(AcessoService);
  private readonly usuarioAtual = inject(FirebaseAuthService).currentUser();
  /** Admin, ou quem tem a permissão — mesma regra da tela de Equipe do app. */
  readonly podeRedefinirSenha = temPermissao(this.usuarioAtual, 'acesso_redefinir_senha');

  readonly funcionarios = signal<FuncionarioListaDto[]>([]);
  readonly carregando = signal(true);
  readonly erro = signal('');
  readonly filtroNome = signal('');
  readonly filtroPerfil = signal('');
  readonly dropdownAbertoId = signal<string | null>(null);
  readonly dropdownPos = signal({ top: 0, right: 0 });

  private readonly search$ = new Subject<string>();
  private readonly destroy$ = new Subject<void>();

  ngOnInit(): void {
    this.search$.pipe(debounceTime(400), distinctUntilChanged(), takeUntil(this.destroy$))
      .subscribe(() => this.carregar());
    this.carregar();
  }

  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); }

  onNomeChange(nome: string): void { this.filtroNome.set(nome); this.search$.next(nome); }

  onPerfilChange(perfil: string): void { this.filtroPerfil.set(perfil); this.carregar(); }

  carregar(): void {
    this.carregando.set(true);
    this.funcionarioService.getAll({
      nome: this.filtroNome() || undefined,
      perfil: this.filtroPerfil() || undefined,
    }).subscribe({
      next: (res) => { this.funcionarios.set(res.dados ?? []); this.carregando.set(false); },
      error: () => { this.erro.set('Erro ao carregar funcionários.'); this.carregando.set(false); },
    });
  }

  toggleDropdown(id: string, event: MouseEvent): void {
    const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
    this.dropdownPos.set({ top: rect.bottom + 4, right: window.innerWidth - rect.right });
    this.dropdownAbertoId.update((atual) => atual === id ? null : id);
  }

  fecharDropdown(): void { this.dropdownAbertoId.set(null); }

  toggleAtivo(f: FuncionarioListaDto): void {
    this.fecharDropdown();
    this.funcionarioService.definirAtivo(f.id, !f.ativo)
      .subscribe({ next: () => this.carregar(), error: () => this.erro.set('Erro ao alterar status.') });
  }

  ehOProprio(f: FuncionarioListaDto): boolean { return f.id === this.usuarioAtual?.id; }

  verSenha(f: FuncionarioListaDto): void {
    this.fecharDropdown();
    this.acessoService.mostrarSenha(f.nome, f.senhaTemporaria!);
  }

  async redefinirSenha(f: FuncionarioListaDto): Promise<void> {
    this.fecharDropdown();
    if (await this.acessoService.redefinir('funcionarios', f.id, f.nome)) this.carregar();
  }

  async gerarAcesso(f: FuncionarioListaDto): Promise<void> {
    this.fecharDropdown();
    const ok = await this.acessoService.gerarEMostrar({
      colecao: 'funcionarios', usuarioId: f.id, nome: f.nome, motivo: 'provisao_edicao',
    });
    if (ok) this.carregar();
  }

  wppLink(telefone: string): string {
    return `https://wa.me/55${telefone.replace(/\D/g, '')}`;
  }

  avatarInicial(nome: string): string { return (nome ?? 'F').charAt(0).toUpperCase(); }

  perfilCor(perfil: string): string {
    const map: Record<string, string> = { Admin: '#9A7009', Professor: '#B8860B', Secretaria: '#22c55e' };
    return map[perfil] ?? '#94a3b8';
  }
}
