import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { forkJoin } from 'rxjs';
import { HorarioService } from '../../../../core/services/horario.service';
import { TurmaService } from '../../../../core/services/turma.service';
import { HorarioDto, GradeHorariosDto } from '../../../../core/models/horario.model';
import { TurmaDto } from '../../../../core/models/turma.model';

@Component({
  selector: 'app-grade-horarios',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './grade-horarios.component.html',
  styleUrls: ['./grade-horarios.component.css'],
})
export class GradeHorariosComponent implements OnInit {
  private readonly horarioService = inject(HorarioService);
  private readonly turmaService = inject(TurmaService);
  private readonly fb = inject(FormBuilder);

  readonly grade = signal<GradeHorariosDto | null>(null);
  readonly turmas = signal<TurmaDto[]>([]);
  readonly carregando = signal(true);
  readonly erro = signal('');
  readonly horarioSelecionado = signal<HorarioDto | null>(null);
  readonly modalAberto = signal(false);
  readonly salvando = signal(false);
  readonly erroForm = signal('');
  readonly diasSelecionados = signal<number[]>([]);

  readonly diasOrdem = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

  readonly diasOpcoes = [
    { label: 'Seg', value: 1 },
    { label: 'Ter', value: 2 },
    { label: 'Qua', value: 3 },
    { label: 'Qui', value: 4 },
    { label: 'Sex', value: 5 },
    { label: 'Sáb', value: 6 },
    { label: 'Dom', value: 0 },
  ];

  readonly modoEdicao = signal(false);
  readonly salvandoEdicao = signal(false);
  readonly erroEdicao = signal('');

  readonly formEdicao = this.fb.group({
    turmaId: ['', Validators.required],
    horaInicio: ['', Validators.required],
    horaFim: ['', Validators.required],
    sala: [''],
  });

  readonly form = this.fb.group({
    turmaId: ['', Validators.required],
    horaInicio: ['', Validators.required],
    horaFim: ['', Validators.required],
    sala: [''],
  });

  ngOnInit(): void {
    this.carregar();
    this.turmaService.getAll({ ativo: true }).subscribe({ next: (r) => this.turmas.set(r.dados ?? []) });
  }

  carregar(): void {
    this.carregando.set(true);
    this.horarioService.getGrade().subscribe({
      next: (res) => { this.grade.set(res.dados ?? null); this.carregando.set(false); },
      error: () => { this.erro.set('Erro ao carregar grade.'); this.carregando.set(false); },
    });
  }

  getDia(dia: string): HorarioDto[] {
    return this.grade()?.grade[dia] ?? [];
  }

  corModalidade(nome: string): string {
    let hash = 0;
    for (const c of nome) hash = (hash * 31 + c.charCodeAt(0)) & 0xffffffff;
    const hue = Math.abs(hash) % 360;
    return `hsl(${hue}, 55%, 55%)`;
  }

  abrirModal(): void {
    this.form.reset();
    this.diasSelecionados.set([]);
    this.erroForm.set('');
    this.modalAberto.set(true);
  }

  fecharModal(): void {
    this.modalAberto.set(false);
    this.horarioSelecionado.set(null);
  }

  selecionar(h: HorarioDto): void {
    this.horarioSelecionado.set(h);
    this.modoEdicao.set(false);
    this.erroEdicao.set('');
  }

  abrirEdicao(): void {
    const h = this.horarioSelecionado();
    if (!h) return;
    this.formEdicao.patchValue({
      turmaId: h.turmaId,
      horaInicio: h.horaInicio,
      horaFim: h.horaFim,
      sala: h.sala ?? '',
    });
    this.erroEdicao.set('');
    this.modoEdicao.set(true);
  }

  cancelarEdicao(): void { this.modoEdicao.set(false); this.erroEdicao.set(''); }

  salvarEdicao(): void {
    const h = this.horarioSelecionado();
    if (!h || this.formEdicao.invalid) { this.formEdicao.markAllAsTouched(); return; }
    this.salvandoEdicao.set(true);
    this.erroEdicao.set('');
    const v = this.formEdicao.value;
    this.horarioService.update(h.id, {
      turmaId: v.turmaId!,
      diaSemana: h.diaSemana,
      horaInicio: v.horaInicio!,
      horaFim: v.horaFim!,
      sala: v.sala || undefined,
    }).subscribe({
      next: () => { this.salvandoEdicao.set(false); this.modoEdicao.set(false); this.fecharModal(); this.carregar(); },
      error: (err) => { this.erroEdicao.set(err.error?.mensagem ?? 'Conflito de horário detectado.'); this.salvandoEdicao.set(false); },
    });
  }

  isDiaSelecionado(dia: number): boolean { return this.diasSelecionados().includes(dia); }

  toggleDia(dia: number): void {
    this.diasSelecionados.update(dias =>
      dias.includes(dia) ? dias.filter(d => d !== dia) : [...dias, dia]
    );
  }

  remover(id: string): void {
    if (!confirm('Remover este horário?')) return;
    this.horarioService.delete(id).subscribe({
      next: () => { this.fecharModal(); this.carregar(); },
      error: () => alert('Erro ao remover horário.'),
    });
  }

  salvar(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    if (this.diasSelecionados().length === 0) {
      this.erroForm.set('Selecione pelo menos um dia da semana.');
      return;
    }
    this.salvando.set(true);
    this.erroForm.set('');

    const v = this.form.value;
    const requests = this.diasSelecionados().map(dia =>
      this.horarioService.create({
        turmaId: v.turmaId!,
        diaSemana: dia,
        horaInicio: v.horaInicio!,
        horaFim: v.horaFim!,
        sala: v.sala ?? undefined,
      })
    );

    forkJoin(requests).subscribe({
      next: () => { this.fecharModal(); this.carregar(); this.salvando.set(false); },
      error: (err) => {
        this.erroForm.set(err.error?.mensagem ?? 'Conflito de horário detectado.');
        this.carregar();
        this.salvando.set(false);
      },
    });
  }
}
