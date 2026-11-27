import { Component, inject, signal, OnInit, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { TurmaService } from '../../../../core/services/turma.service';
import { ModalidadeService, ModalidadeDto } from '../../../../core/services/modalidade.service';
import { FuncionarioService } from '../../../../core/services/funcionario.service';
import { PlanoLimiteService } from '../../../../core/services/plano-limite.service';
import { PlanoService } from '../../../../core/services/plano.service';
import { PlanoDto } from '../../../../core/models/plano.model';
import { UsuarioResumoDto } from '../../../../core/models/usuario.model';

@Component({
  selector: 'app-turma-form',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterLink],
  templateUrl: './turma-form.component.html',
})
export class TurmaFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly turmaService = inject(TurmaService);
  private readonly modalidadeService = inject(ModalidadeService);
  private readonly funcionarioService = inject(FuncionarioService);
  private readonly planoLimiteService = inject(PlanoLimiteService);
  private readonly planoService = inject(PlanoService);
  readonly planos = signal<PlanoDto[]>([]);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  readonly turmaId = signal<string | null>(null);
  readonly carregando = signal(false);
  readonly erro = signal('');
  readonly modoEdicao = signal(false);
  /** Se a turma em edição já estava ativa — só reativar conta no limite do plano. */
  private estavaAtiva = false;

  readonly modalidades = signal<ModalidadeDto[]>([]);
  readonly professores = signal<UsuarioResumoDto[]>([]);
  readonly buscaProfessor = signal('');

  readonly professoresFiltrados = computed(() => {
    const q = this.buscaProfessor().toLowerCase();
    return q ? this.professores().filter((p) => p.nome.toLowerCase().includes(q)) : this.professores();
  });

  readonly form = this.fb.group({
    nome: ['', Validators.required],
    modalidadeId: ['', Validators.required],
    professorId: [''],
    planoPadraoId: [''],
    nivel: [''],
    capacidadeMaxima: [30, [Validators.required, Validators.min(1)]],
    ativo: [true],
  });

  ngOnInit(): void {
    this.planoService.listar().subscribe({ next: (r) => this.planos.set((r.dados ?? []).filter((x) => x.ativo)) });
    this.modalidadeService.getAll().subscribe({ next: (r) => this.modalidades.set(r.dados ?? []) });
    this.funcionarioService.getProfessores().subscribe({ next: (r) => this.professores.set(r.dados ?? []) });
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.turmaId.set(id);
      this.modoEdicao.set(true);
      this.carregarTurma(id);
    }
  }

  private carregarTurma(id: string): void {
    this.carregando.set(true);
    this.turmaService.getById(id).subscribe({
      next: (res) => {
        if (res.dados) {
          this.estavaAtiva = res.dados.ativo;
          this.form.patchValue({
            nome: res.dados.nome,
            modalidadeId: res.dados.modalidadeId,
            professorId: res.dados.professorId,
            planoPadraoId: res.dados.planoPadraoId ?? '',
            nivel: res.dados.nivel ?? '',
            capacidadeMaxima: res.dados.capacidadeMaxima,
            ativo: res.dados.ativo,
          });
        }
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set('Erro ao carregar turma.');
        this.carregando.set(false);
      },
    });
  }

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const dados = this.form.value;
    this.carregando.set(true);
    this.erro.set('');

    const id = this.turmaId();
    const request$ = id
      ? this.turmaService.update(id, {
          nome: dados.nome!,
          modalidadeId: dados.modalidadeId!,
          professorId: dados.professorId ?? '',
          planoPadraoId: dados.planoPadraoId || undefined,
          nivel: dados.nivel ?? undefined,
          capacidadeMaxima: dados.capacidadeMaxima!,
          ativo: dados.ativo!,
        })
      : this.turmaService.create({
          nome: dados.nome!,
          modalidadeId: dados.modalidadeId!,
          professorId: dados.professorId ?? '',
          planoPadraoId: dados.planoPadraoId || undefined,
          nivel: dados.nivel ?? undefined,
          capacidadeMaxima: dados.capacidadeMaxima!,
        });

    request$.subscribe({
      next: (res) => {
        if (res.sucesso && res.dados) {
          this.router.navigate(['/app/turmas', res.dados.id]);
        } else {
          this.erro.set(res.mensagem ?? 'Erro ao salvar turma.');
          this.carregando.set(false);
        }
      },
      error: async (err) => {
        const ocupaVaga = !id || (dados.ativo === true && !this.estavaAtiva);
        const limite = ocupaVaga ? await this.planoLimiteService.mensagemSeAtingido(err, 'turma') : null;
        this.erro.set(limite ?? err.error?.mensagem ?? err.error?.title ?? 'Erro ao salvar turma.');
        this.carregando.set(false);
      },
    });
  }
}
