import { Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { TurmaService } from '../../../../core/services/turma.service';
import { AlunoService } from '../../../../core/services/aluno.service';
import { HorarioService } from '../../../../core/services/horario.service';
import { TurmaDetalheDto, MatriculaDto } from '../../../../core/models/turma.model';
import { AlunoListaDto } from '../../../../core/models/aluno.model';
import { HorarioResumoDto } from '../../../../core/models/turma.model';

type Aba = 'alunos' | 'horarios' | 'presencas';

@Component({
  selector: 'app-turma-detalhe',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './turma-detalhe.component.html',
})
export class TurmaDetalheComponent implements OnInit {
  private readonly turmaService = inject(TurmaService);
  private readonly alunoService = inject(AlunoService);
  private readonly horarioService = inject(HorarioService);
  private readonly route = inject(ActivatedRoute);

  readonly turma = signal<TurmaDetalheDto | null>(null);
  readonly carregando = signal(true);
  readonly erro = signal('');
  readonly abaAtiva = signal<Aba>('alunos');
  readonly operando = signal(false);
  readonly erroMatricula = signal('');

  // Seleção de aluno para matricular
  readonly todosAlunos = signal<AlunoListaDto[]>([]);
  readonly filtroAluno = signal('');
  readonly dropdownAberto = signal(false);
  readonly alunoSelecionado = signal<AlunoListaDto | null>(null);

  // Modal de confirmação para desmatricular
  readonly alunoParaRemover = signal<MatriculaDto | null>(null);
  readonly removendo = signal(false);

  // Modal de confirmação para remover horário
  readonly horarioParaRemover = signal<HorarioResumoDto | null>(null);
  readonly removendoHorario = signal(false);

  readonly alunosFiltrados = computed(() => {
    const filtro = this.filtroAluno().toLowerCase().trim();
    const matriculadosIds = new Set((this.turma()?.alunos ?? []).map(a => a.alunoId));
    const disponiveis = this.todosAlunos().filter(a => !matriculadosIds.has(a.id));
    return filtro.length === 0 ? disponiveis : disponiveis.filter(a => a.nome.toLowerCase().includes(filtro));
  });

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id')!;
    this.carregar(id);
    this.alunoService.getAll({ ativo: true, pageSize: 500 }).subscribe({
      next: (res) => this.todosAlunos.set(res.dados?.itens ?? []),
    });
  }

  carregar(id: string): void {
    this.carregando.set(true);
    this.turmaService.getById(id).subscribe({
      next: (res) => { this.turma.set(res.dados ?? null); this.carregando.set(false); },
      error: () => { this.erro.set('Erro ao carregar turma.'); this.carregando.set(false); },
    });
  }

  abrirDropdown(): void { this.dropdownAberto.set(true); }

  fecharDropdown(): void { setTimeout(() => this.dropdownAberto.set(false), 200); }

  onFiltroChange(v: string): void {
    this.filtroAluno.set(v);
    this.alunoSelecionado.set(null);
    this.dropdownAberto.set(true);
  }

  selecionarAluno(aluno: AlunoListaDto): void {
    this.alunoSelecionado.set(aluno);
    this.filtroAluno.set(aluno.nome);
    this.dropdownAberto.set(false);
  }

  matricular(): void {
    const aluno = this.alunoSelecionado();
    const turma = this.turma();
    if (!aluno || !turma) return;

    this.erroMatricula.set('');
    this.operando.set(true);
    this.turmaService.matricular(turma.id, aluno.id).subscribe({
      next: () => {
        this.alunoSelecionado.set(null);
        this.filtroAluno.set('');
        this.operando.set(false);
        this.carregar(turma.id);
      },
      error: (err) => {
        this.erroMatricula.set(err.error?.mensagem ?? 'Erro ao matricular aluno.');
        this.operando.set(false);
      },
    });
  }

  abrirModalRemover(aluno: MatriculaDto): void { this.alunoParaRemover.set(aluno); }

  fecharModalRemover(): void { this.alunoParaRemover.set(null); }

  confirmarRemover(): void {
    const aluno = this.alunoParaRemover();
    const turma = this.turma();
    if (!aluno || !turma) return;

    this.removendo.set(true);
    this.turmaService.desmatricular(turma.id, aluno.alunoId).subscribe({
      next: () => { this.removendo.set(false); this.fecharModalRemover(); this.carregar(turma.id); },
      error: () => { this.removendo.set(false); this.fecharModalRemover(); this.erro.set('Erro ao remover aluno.'); },
    });
  }

  abrirModalRemoverHorario(h: HorarioResumoDto): void { this.horarioParaRemover.set(h); }

  fecharModalRemoverHorario(): void { this.horarioParaRemover.set(null); }

  confirmarRemoverHorario(): void {
    const h = this.horarioParaRemover();
    const turma = this.turma();
    if (!h || !turma) return;

    this.removendoHorario.set(true);
    this.horarioService.delete(h.id).subscribe({
      next: () => { this.removendoHorario.set(false); this.fecharModalRemoverHorario(); this.carregar(turma.id); },
      error: () => { this.removendoHorario.set(false); this.fecharModalRemoverHorario(); this.erro.set('Erro ao remover horário.'); },
    });
  }

  formatarHora(h: string): string { return h ? h.substring(0, 5) : ''; }
}
