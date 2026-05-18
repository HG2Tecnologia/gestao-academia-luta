import { Component, inject, signal, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink, NavigationEnd } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, filter } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { AlunoService } from '../../../../core/services/aluno.service';
import { AlunoListaDto } from '../../../../core/models/aluno.model';

@Component({
  selector: 'app-alunos-lista',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './alunos-lista.component.html',
})
export class AlunosListaComponent implements OnInit, OnDestroy {
  private readonly alunoService = inject(AlunoService);
  private readonly router = inject(Router);

  readonly alunos = signal<AlunoListaDto[]>([]);
  readonly total = signal(0);
  readonly pagina = signal(1);
  readonly totalPaginas = signal(1);
  readonly carregando = signal(true);
  readonly erro = signal('');
  readonly filtroNome = signal('');
  readonly filtroAtivo = signal<boolean | undefined>(undefined);

  // Modal de confirmação
  readonly modalConfirmacao = signal(false);
  readonly alunoParaToggle = signal<AlunoListaDto | null>(null);
  readonly toggleAtivando = signal(false);

  // Dropdown de ações por linha
  readonly dropdownAbertoId = signal<string | null>(null);
  readonly dropdownPos = signal({ top: 0, right: 0 });

  private readonly search$ = new Subject<string>();
  private readonly destroy$ = new Subject<void>();

  ngOnInit(): void {
    this.search$.pipe(
      debounceTime(400),
      distinctUntilChanged(),
      takeUntil(this.destroy$),
    ).subscribe(() => { this.pagina.set(1); this.carregar(); });

    // Reload list every time user navigates back to this route (handles bfcache and back button)
    this.router.events.pipe(
      filter(e => e instanceof NavigationEnd && /^\/app\/alunos\/?$/.test(e.urlAfterRedirects ?? e.url)),
      takeUntil(this.destroy$),
    ).subscribe(() => this.carregar());

    this.carregar();
  }

  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); }

  onNomeChange(nome: string): void {
    this.filtroNome.set(nome);
    this.search$.next(nome);
  }

  onAtivoChange(val: string): void {
    this.filtroAtivo.set(val === '' ? undefined : val === 'true');
    this.pagina.set(1);
    this.carregar();
  }

  carregar(): void {
    this.carregando.set(true);
    this.alunoService.getAll({
      nome: this.filtroNome() || undefined,
      ativo: this.filtroAtivo(),
      page: this.pagina(),
      pageSize: 20,
    }).subscribe({
      next: (res) => {
        const dados = res.dados;
        this.alunos.set(dados?.itens ?? []);
        this.total.set(dados?.totalItens ?? 0);
        this.totalPaginas.set(dados?.totalPaginas ?? 1);
        this.carregando.set(false);
      },
      error: () => { this.erro.set('Erro ao carregar alunos.'); this.carregando.set(false); },
    });
  }

  abrirToggle(aluno: AlunoListaDto): void {
    this.alunoParaToggle.set(aluno);
    this.modalConfirmacao.set(true);
    this.dropdownAbertoId.set(null);
  }

  fecharModal(): void {
    this.modalConfirmacao.set(false);
    this.alunoParaToggle.set(null);
  }

  confirmarToggle(): void {
    const aluno = this.alunoParaToggle();
    if (!aluno) return;
    this.toggleAtivando.set(true);
    this.alunoService.toggleAtivo(aluno.id, !aluno.ativo).subscribe({
      next: () => { this.toggleAtivando.set(false); this.fecharModal(); this.carregar(); },
      error: () => { this.toggleAtivando.set(false); this.fecharModal(); this.erro.set('Erro ao alterar status do aluno.'); },
    });
  }

  toggleDropdown(id: string, event: MouseEvent): void {
    const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
    this.dropdownPos.set({ top: rect.bottom + 4, right: window.innerWidth - rect.right });
    this.dropdownAbertoId.update((atual) => atual === id ? null : id);
  }

  fecharDropdown(): void { this.dropdownAbertoId.set(null); }

  irPagina(p: number): void {
    if (p < 1 || p > this.totalPaginas()) return;
    this.pagina.set(p);
    this.carregar();
  }

  wppLink(telefone: string): string {
    return `https://wa.me/55${telefone.replace(/\D/g, '')}`;
  }

  avatarInicial(nome: string): string { return (nome ?? 'A').charAt(0).toUpperCase(); }

  faixaCor(cor?: string): string { return cor ?? '#94a3b8'; }

  aniversario(dataNascimento: string): string {
    const [, m, d] = dataNascimento.split('-');
    return `${d}/${m}`;
  }
}
