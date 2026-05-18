import { Component, inject, signal, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { FuncionarioService } from '../../../../core/services/funcionario.service';
import { FuncionarioListaDto } from '../../../../core/models/funcionario.model';

@Component({
  selector: 'app-funcionarios-lista',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './funcionarios-lista.component.html',
})
export class FuncionariosListaComponent implements OnInit, OnDestroy {
  private readonly funcionarioService = inject(FuncionarioService);

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
    // telefone vazio: backend preserva o valor existente quando em branco
    this.funcionarioService.update(f.id, {
      nome: f.nome, email: f.email || undefined, telefone: '',
      cargo: f.cargo, perfil: f.perfil, ativo: !f.ativo,
    }).subscribe({ next: () => this.carregar(), error: () => this.erro.set('Erro ao alterar status.') });
  }

  wppLink(telefone: string): string {
    return `https://wa.me/55${telefone.replace(/\D/g, '')}`;
  }

  avatarInicial(nome: string): string { return (nome ?? 'F').charAt(0).toUpperCase(); }

  perfilCor(perfil: string): string {
    const map: Record<string, string> = { Admin: '#a855f7', Professor: '#3b82f6', Recepcionista: '#22c55e' };
    return map[perfil] ?? '#94a3b8';
  }
}
