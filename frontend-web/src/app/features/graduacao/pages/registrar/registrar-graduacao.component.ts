import { Component, inject, signal, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators, FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, switchMap, of } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { GraduacaoService } from '../../../../core/services/graduacao.service';
import { ModalidadeService, ModalidadeDto } from '../../../../core/services/modalidade.service';
import { UsuarioService } from '../../../../core/services/usuario.service';
import { AlunoService } from '../../../../core/services/aluno.service';
import { FaixaDto } from '../../../../core/models/graduacao.model';
import { AlunoListaDto } from '../../../../core/models/aluno.model';
import { UsuarioResumoDto } from '../../../../core/models/usuario.model';
import { BadgeFaixaComponent } from '../../../../shared/components/badge-faixa/badge-faixa.component';

@Component({
  selector: 'app-registrar-graduacao',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterLink, BadgeFaixaComponent],
  templateUrl: './registrar-graduacao.component.html',
})
export class RegistrarGraduacaoComponent implements OnDestroy {
  private readonly graduacaoService = inject(GraduacaoService);
  private readonly modalidadeService = inject(ModalidadeService);
  private readonly usuarioService = inject(UsuarioService);
  private readonly alunoService = inject(AlunoService);
  private readonly fb = inject(FormBuilder);
  private readonly router = inject(Router);

  readonly modalidades = signal<ModalidadeDto[]>([]);
  readonly professores = signal<UsuarioResumoDto[]>([]);
  readonly faixas = signal<FaixaDto[]>([]);
  readonly faixaSelecionada = signal<FaixaDto | null>(null);
  readonly salvando = signal(false);
  readonly erro = signal('');

  // Autocomplete aluno
  readonly nomeBusca = signal('');
  readonly sugestoes = signal<AlunoListaDto[]>([]);
  readonly alunoSelecionado = signal<AlunoListaDto | null>(null);
  readonly mostrarSugestoes = signal(false);
  readonly buscandoAluno = signal(false);

  private readonly busca$ = new Subject<string>();
  private readonly destroy$ = new Subject<void>();

  readonly form = this.fb.group({
    alunoId: ['', Validators.required],
    modalidadeId: ['', Validators.required],
    faixaId: ['', Validators.required],
    grau: [0],
    dataExame: ['', Validators.required],
    professorId: ['', Validators.required],
    aprovado: [true],
    observacoes: [''],
  });

  get grausDisponiveis(): number[] {
    const f = this.faixaSelecionada();
    if (!f?.temGraus) return [];
    return Array.from({ length: f.maxGraus + 1 }, (_, i) => i);
  }

  constructor() {
    this.modalidadeService.getAll().subscribe({ next: r => this.modalidades.set(r.dados ?? []) });
    this.usuarioService.getProfessores().subscribe({ next: r => this.professores.set(r.dados ?? []) });

    this.busca$.pipe(
      debounceTime(400),
      distinctUntilChanged(),
      switchMap(nome => {
        if (nome.length < 2) { this.sugestoes.set([]); this.mostrarSugestoes.set(false); return of(null); }
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

  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); }

  onNomeInput(nome: string): void {
    this.nomeBusca.set(nome);
    this.alunoSelecionado.set(null);
    this.form.patchValue({ alunoId: '' });
    this.busca$.next(nome);
  }

  selecionarAluno(aluno: AlunoListaDto): void {
    this.alunoSelecionado.set(aluno);
    this.nomeBusca.set(aluno.nome);
    this.mostrarSugestoes.set(false);
    this.form.patchValue({ alunoId: aluno.id });
  }

  fecharSugestoes(): void {
    setTimeout(() => this.mostrarSugestoes.set(false), 200);
  }

  carregarFaixas(): void {
    const modalidadeId = this.form.get('modalidadeId')?.value;
    if (!modalidadeId) return;
    this.faixas.set([]);
    this.faixaSelecionada.set(null);
    this.form.patchValue({ faixaId: '' });
    this.graduacaoService.getFaixasByModalidade(modalidadeId).subscribe({
      next: (res) => this.faixas.set(res.dados ?? []),
    });
  }

  onFaixaChange(): void {
    const faixaId = this.form.get('faixaId')?.value;
    const faixa = this.faixas().find((f) => f.id === faixaId) ?? null;
    this.faixaSelecionada.set(faixa);
    this.form.patchValue({ grau: 0 });
  }

  submit(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    this.salvando.set(true);
    this.erro.set('');
    const v = this.form.value;
    this.graduacaoService.registrar({
      alunoId: v.alunoId!,
      faixaId: v.faixaId!,
      grau: +v.grau!,
      dataExame: v.dataExame!,
      professorId: v.professorId!,
      aprovado: v.aprovado!,
      observacoes: v.observacoes ?? undefined,
    }).subscribe({
      next: (res) => {
        if (res.sucesso) this.router.navigate(['/app/graduacao']);
        else { this.erro.set(res.mensagem ?? 'Erro'); this.salvando.set(false); }
      },
      error: (err) => { this.erro.set(err.error?.mensagem ?? 'Erro'); this.salvando.set(false); },
    });
  }
}
