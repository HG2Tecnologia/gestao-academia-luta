import { Component, inject, signal, OnInit, OnDestroy, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { AlunoService } from '../../../../core/services/aluno.service';
import { TurmaService } from '../../../../core/services/turma.service';
import { GraduacaoService } from '../../../../core/services/graduacao.service';
import { ModalidadeService } from '../../../../core/services/modalidade.service';
import { AuthService } from '../../../../core/services/auth.service';
import { PlanoService } from '../../../../core/services/plano.service';
import { TurmaDto } from '../../../../core/models/turma.model';
import { FaixaDto } from '../../../../core/models/graduacao.model';
import { PlanoDto } from '../../../../core/models/plano.model';

interface ModalidadeResumo { id: string; nome: string; }

@Component({
  selector: 'app-aluno-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule, RouterLink],
  templateUrl: './aluno-form.component.html',
})
export class AlunoFormComponent implements OnInit, OnDestroy {
  private readonly alunoService = inject(AlunoService);
  private readonly turmaService = inject(TurmaService);
  private readonly graduacaoService = inject(GraduacaoService);
  private readonly modalidadeService = inject(ModalidadeService);
  private readonly authService = inject(AuthService);
  private readonly planoService = inject(PlanoService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly fb = inject(FormBuilder);
  private readonly destroy$ = new Subject<void>();

  readonly editandoId = signal<string | null>(null);
  readonly matricula = signal<string | null>(null);
  readonly salvando = signal(false);
  readonly carregando = signal(false);
  readonly erro = signal('');

  // Opcionais de cadastro
  readonly turmas = signal<TurmaDto[]>([]);
  readonly modalidades = signal<ModalidadeResumo[]>([]);
  readonly faixas = signal<FaixaDto[]>([]);
  readonly planosDisponiveis = signal<PlanoDto[]>([]);
  readonly turmaInicialId = signal('');
  readonly modalidadeInicialId = signal('');
  readonly faixaInicialId = signal('');
  readonly planoSelecionadoId = signal('');
  readonly diaVencimento = signal<number | null>(null);
  readonly dataNascimentoSignal = signal('');

  // Graduação no modo edição
  readonly modalidadeGradId = signal('');
  readonly faixaGradId = signal('');
  readonly faixasGrad = signal<FaixaDto[]>([]);
  readonly dataGrad = signal(new Date().toISOString().split('T')[0]);
  readonly registrandoGrad = signal(false);
  readonly gradSucesso = signal(false);
  readonly erroGrad = signal('');

  readonly form = this.fb.group({
    nome: ['', [Validators.required, Validators.minLength(3)]],
    email: ['', Validators.email],
    telefone: ['', Validators.required],
    dataNascimento: ['', Validators.required],
    contatoEmergenciaNome: [''],
    contatoEmergenciaTelefone: [''],
    tipoPlano: [''],
    ativo: [true],
  });

  readonly menorDeIdade = computed(() => this.calcularMenorDeIdade(this.dataNascimentoSignal()));

  ngOnInit(): void {
    this.form.get('dataNascimento')!.valueChanges.pipe(takeUntil(this.destroy$)).subscribe(val => {
      this.dataNascimentoSignal.set(val ?? '');
      this.atualizarValidadoresResponsavel(this.calcularMenorDeIdade(val ?? ''));
    });

    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.editandoId.set(id);
      this.carregando.set(true);
      this.alunoService.getById(id).subscribe({
        next: (res) => {
          if (res.dados) {
            const d = res.dados;
            this.matricula.set((d as any).matricula ?? null);
            this.form.patchValue({
              nome: d.nome, email: d.email ?? '', telefone: d.telefone ?? '',
              dataNascimento: d.dataNascimento ?? '',
              contatoEmergenciaNome: d.contatoEmergenciaNome ?? '',
              contatoEmergenciaTelefone: d.contatoEmergenciaTelefone ?? '',
              tipoPlano: (d as any).tipoPlano ?? '', ativo: d.ativo,
            });
            this.dataNascimentoSignal.set(d.dataNascimento ?? '');
            this.planoSelecionadoId.set((d as any).planoId ?? '');
            this.diaVencimento.set((d as any).diaVencimento ?? null);
          }
          this.carregando.set(false);
        },
        error: () => { this.erro.set('Erro ao carregar dados do aluno.'); this.carregando.set(false); },
      });
    }

    // Carregar planos e turmas sempre (para vincular no edit também)
    this.planoService.listar().subscribe({ next: (r) => this.planosDisponiveis.set((r.dados ?? []).filter(p => p.ativo)) });
    if (!this.editandoId()) {
      this.turmaService.getAll({ ativo: true }).subscribe({ next: (r) => this.turmas.set(r.dados ?? []) });
    }
    // Modalidades carregadas sempre (usadas em criar e para registrar graduação no editar)
    this.modalidadeService.getAll().subscribe({ next: (r) => this.modalidades.set(r.dados ?? []) });
  }

  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); }

  onTurmaChange(turmaId: string): void {
    this.turmaInicialId.set(turmaId);
    if (!turmaId) return;
    const turma = this.turmas().find(t => t.id === turmaId);
    if (turma?.modalidadeId) {
      this.onModalidadeChange(turma.modalidadeId);
    }
  }

  onModalidadeChange(modalidadeId: string): void {
    this.modalidadeInicialId.set(modalidadeId);
    this.faixaInicialId.set('');
    this.faixas.set([]);
    if (!modalidadeId) return;
    this.graduacaoService.getFaixasByModalidade(modalidadeId).subscribe({
      next: (r) => this.faixas.set(r.dados ?? []),
    });
  }

  onModalidadeGradChange(modalidadeId: string): void {
    this.modalidadeGradId.set(modalidadeId);
    this.faixaGradId.set('');
    this.faixasGrad.set([]);
    if (!modalidadeId) return;
    this.graduacaoService.getFaixasByModalidade(modalidadeId).subscribe({
      next: (r) => this.faixasGrad.set(r.dados ?? []),
    });
  }

  registrarGraduacao(): void {
    const alunoId = this.editandoId();
    const faixaId = this.faixaGradId();
    const professorId = this.authService.currentUser()?.sub;
    if (!alunoId || !faixaId || !professorId) { this.erroGrad.set('Selecione modalidade e faixa.'); return; }
    this.registrandoGrad.set(true);
    this.erroGrad.set('');
    this.gradSucesso.set(false);
    this.graduacaoService.registrar({ alunoId, faixaId, dataExame: this.dataGrad(), professorId, aprovado: true, grau: 0 }).subscribe({
      next: () => {
        this.registrandoGrad.set(false);
        this.gradSucesso.set(true);
        this.modalidadeGradId.set('');
        this.faixaGradId.set('');
        this.faixasGrad.set([]);
      },
      error: (err) => { this.erroGrad.set(err.error?.mensagem ?? 'Erro ao registrar graduação.'); this.registrandoGrad.set(false); },
    });
  }

  mascaraTelefone(event: Event): void {
    const input = event.target as HTMLInputElement;
    const nums = input.value.replace(/\D/g, '').slice(0, 11);
    let v = '';
    if (nums.length > 6) v = `(${nums.slice(0,2)}) ${nums.slice(2,7)}-${nums.slice(7)}`;
    else if (nums.length > 2) v = `(${nums.slice(0,2)}) ${nums.slice(2)}`;
    else if (nums.length > 0) v = `(${nums}`;
    input.value = v;
    this.form.get('telefone')?.setValue(v, { emitEvent: false });
  }

  mascaraEmergTel(event: Event): void {
    const input = event.target as HTMLInputElement;
    const nums = input.value.replace(/\D/g, '').slice(0, 11);
    let v = '';
    if (nums.length > 6) v = `(${nums.slice(0,2)}) ${nums.slice(2,7)}-${nums.slice(7)}`;
    else if (nums.length > 2) v = `(${nums.slice(0,2)}) ${nums.slice(2)}`;
    else if (nums.length > 0) v = `(${nums}`;
    input.value = v;
    this.form.get('contatoEmergenciaTelefone')?.setValue(v, { emitEvent: false });
  }

  salvar(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    this.salvando.set(true);
    this.erro.set('');
    const v = this.form.value;
    const id = this.editandoId();

    const base = {
      nome: v.nome!, email: v.email || undefined, telefone: v.telefone!,
      dataNascimento: v.dataNascimento || undefined,
      contatoEmergenciaNome: v.contatoEmergenciaNome || undefined,
      contatoEmergenciaTelefone: v.contatoEmergenciaTelefone || undefined,
      tipoPlano: v.tipoPlano || undefined,
      planoId: this.planoSelecionadoId() || undefined,
      diaVencimento: this.diaVencimento() ?? undefined,
    } as any;

    const req$ = id
      ? this.alunoService.update(id, { ...base, ativo: v.ativo! })
      : this.alunoService.create(base);

    req$.subscribe({
      next: (res) => {
        if (!res.sucesso) { this.erro.set(res.mensagem ?? 'Erro ao salvar.'); this.salvando.set(false); return; }
        if (id) { this.router.navigate(['/app/alunos']); return; }
        const alunoId = res.dados!.id;
        this.vincularOpcionais(alunoId);
      },
      error: (err) => { this.erro.set(err.error?.mensagem ?? 'Erro ao salvar.'); this.salvando.set(false); },
    });
  }

  private vincularOpcionais(alunoId: string): void {
    const turmaId = this.turmaInicialId();
    const faixaId = this.faixaInicialId();
    const professorId = this.authService.currentUser()?.sub;
    const hoje = new Date().toISOString().split('T')[0];

    const pendentes: Promise<any>[] = [];

    if (turmaId) {
      pendentes.push(this.turmaService.matricular(turmaId, alunoId).toPromise());
    }
    if (faixaId && professorId) {
      pendentes.push(this.graduacaoService.registrar({
        alunoId, faixaId,
        dataExame: hoje,
        professorId,
        aprovado: true,
        grau: 0,
      }).toPromise());
    }

    Promise.allSettled(pendentes).then(() => {
      this.router.navigate(['/app/alunos', alunoId]);
    });
  }

  private calcularMenorDeIdade(dataNasc: string | null | undefined): boolean {
    if (!dataNasc) return false;
    const nasc = new Date(dataNasc);
    const hoje = new Date();
    const aniv = new Date(hoje.getFullYear(), nasc.getMonth(), nasc.getDate());
    const idade = hoje.getFullYear() - nasc.getFullYear() - (hoje < aniv ? 1 : 0);
    return idade < 18;
  }

  private atualizarValidadoresResponsavel(menorDeIdade: boolean): void {
    const nome = this.form.get('contatoEmergenciaNome')!;
    const tel = this.form.get('contatoEmergenciaTelefone')!;
    if (menorDeIdade) {
      nome.setValidators(Validators.required);
      tel.setValidators(Validators.required);
    } else {
      nome.clearValidators();
      tel.clearValidators();
    }
    nome.updateValueAndValidity({ emitEvent: false });
    tel.updateValueAndValidity({ emitEvent: false });
  }
}
