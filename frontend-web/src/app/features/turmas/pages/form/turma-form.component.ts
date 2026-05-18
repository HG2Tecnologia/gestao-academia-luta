import { Component, inject, signal, OnInit, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { TurmaService } from '../../../../core/services/turma.service';
import { ModalidadeService, ModalidadeDto } from '../../../../core/services/modalidade.service';
import { UsuarioService } from '../../../../core/services/usuario.service';
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
  private readonly usuarioService = inject(UsuarioService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  readonly turmaId = signal<string | null>(null);
  readonly carregando = signal(false);
  readonly erro = signal('');
  readonly modoEdicao = signal(false);

  readonly modalidades = signal<ModalidadeDto[]>([]);
  readonly professores = signal<UsuarioResumoDto[]>([]);
  readonly buscaProfessor = signal('');

  readonly professoresFiltrados = computed(() => {
    const q = this.buscaProfessor().toLowerCase();
    return q ? this.professores().filter((p) => p.nome.toLowerCase().includes(q)) : this.professores();
  });

  readonly form = this.fb.group({
    nome: ['', [Validators.required, Validators.minLength(3)]],
    modalidadeId: ['', Validators.required],
    professorId: ['', Validators.required],
    nivel: [''],
    capacidadeMaxima: [20, [Validators.required, Validators.min(1)]],
    ativo: [true],
  });

  ngOnInit(): void {
    this.modalidadeService.getAll().subscribe({ next: (r) => this.modalidades.set(r.dados ?? []) });
    this.usuarioService.getProfessores().subscribe({ next: (r) => this.professores.set(r.dados ?? []) });
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
          this.form.patchValue({
            nome: res.dados.nome,
            modalidadeId: res.dados.modalidadeId,
            professorId: res.dados.professorId,
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
          professorId: dados.professorId!,
          nivel: dados.nivel ?? undefined,
          capacidadeMaxima: dados.capacidadeMaxima!,
          ativo: dados.ativo!,
        })
      : this.turmaService.create({
          nome: dados.nome!,
          modalidadeId: dados.modalidadeId!,
          professorId: dados.professorId!,
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
      error: (err) => {
        this.erro.set(err.error?.mensagem ?? err.error?.title ?? 'Erro ao salvar turma.');
        this.carregando.set(false);
      },
    });
  }
}
