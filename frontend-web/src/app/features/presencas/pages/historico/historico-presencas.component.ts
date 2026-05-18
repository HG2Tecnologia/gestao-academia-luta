import { Component, inject, signal, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged, switchMap, of } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { PresencaService } from '../../../../core/services/presenca.service';
import { AlunoService } from '../../../../core/services/aluno.service';
import { PresencaDto } from '../../../../core/models/presenca.model';
import { AlunoListaDto } from '../../../../core/models/aluno.model';

@Component({
  selector: 'app-historico-presencas',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './historico-presencas.component.html',
})
export class HistoricoPresencasComponent implements OnDestroy {
  private readonly presencaService = inject(PresencaService);
  private readonly alunoService = inject(AlunoService);

  readonly nomeBusca = signal('');
  readonly sugestoes = signal<AlunoListaDto[]>([]);
  readonly alunoSelecionado = signal<AlunoListaDto | null>(null);
  readonly mostrarSugestoes = signal(false);
  readonly buscandoAluno = signal(false);

  readonly de = signal(new Date(Date.now() - 30 * 86400000).toISOString().split('T')[0]);
  readonly ate = signal(new Date().toISOString().split('T')[0]);
  readonly presencas = signal<PresencaDto[]>([]);
  readonly carregando = signal(false);
  readonly erro = signal('');

  private readonly busca$ = new Subject<string>();
  private readonly destroy$ = new Subject<void>();

  constructor() {
    this.busca$.pipe(
      debounceTime(400),
      distinctUntilChanged(),
      switchMap(nome => {
        if (nome.length < 2) {
          this.sugestoes.set([]);
          this.mostrarSugestoes.set(false);
          return of(null);
        }
        this.buscandoAluno.set(true);
        return this.alunoService.buscarPorNome(nome);
      }),
      takeUntil(this.destroy$),
    ).subscribe({
      next: (res) => {
        if (res) {
          this.sugestoes.set(res.dados?.itens ?? []);
          this.mostrarSugestoes.set(true);
        }
        this.buscandoAluno.set(false);
      },
      error: () => this.buscandoAluno.set(false),
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onNomeInput(nome: string): void {
    this.nomeBusca.set(nome);
    this.alunoSelecionado.set(null);
    this.presencas.set([]);
    this.busca$.next(nome);
  }

  selecionarAluno(aluno: AlunoListaDto): void {
    this.alunoSelecionado.set(aluno);
    this.nomeBusca.set(aluno.nome);
    this.mostrarSugestoes.set(false);
    this.sugestoes.set([]);
    this.buscar();
  }

  fecharSugestoes(): void {
    setTimeout(() => this.mostrarSugestoes.set(false), 200);
  }

  buscar(): void {
    const aluno = this.alunoSelecionado();
    if (!aluno) return;
    this.carregando.set(true);
    this.erro.set('');
    this.presencaService.getHistorico(aluno.id, this.de(), this.ate()).subscribe({
      next: (res) => {
        this.presencas.set(res.dados ?? []);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set('Erro ao buscar histórico.');
        this.carregando.set(false);
      },
    });
  }
}
