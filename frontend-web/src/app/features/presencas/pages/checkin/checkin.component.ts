import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TurmaService } from '../../../../core/services/turma.service';
import { HorarioService } from '../../../../core/services/horario.service';
import { PresencaService } from '../../../../core/services/presenca.service';
import { MatriculaDto, TurmaDto } from '../../../../core/models/turma.model';
import { HorarioDto } from '../../../../core/models/horario.model';
import { PresencaDto } from '../../../../core/models/presenca.model';
import { QrScannerComponent } from '../../../../shared/components/qr-scanner/qr-scanner.component';

@Component({
  selector: 'app-checkin',
  standalone: true,
  imports: [CommonModule, FormsModule, QrScannerComponent],
  templateUrl: './checkin.component.html',
})
export class CheckinComponent implements OnInit {
  private readonly turmaService = inject(TurmaService);
  private readonly horarioService = inject(HorarioService);
  private readonly presencaService = inject(PresencaService);

  readonly turmas = signal<TurmaDto[]>([]);
  readonly horarios = signal<HorarioDto[]>([]);
  readonly alunos = signal<MatriculaDto[]>([]);
  readonly presentes = signal<Set<string>>(new Set());
  private jaPresentes = new Set<string>();

  readonly turmaId = signal('');
  readonly horarioId = signal('');
  readonly data = signal(new Date().toISOString().split('T')[0]);

  readonly carregandoTurmas = signal(false);
  readonly carregandoHorarios = signal(false);
  readonly carregandoAlunos = signal(false);
  readonly salvando = signal(false);
  readonly modoQr = signal(false);
  readonly feedbackQr = signal('');
  readonly erro = signal('');
  readonly modalSucesso = signal(false);

  ngOnInit(): void {
    this.carregandoTurmas.set(true);
    this.turmaService.getAll({ ativo: true }).subscribe({
      next: (res) => { this.turmas.set(res.dados ?? []); this.carregandoTurmas.set(false); },
      error: () => this.carregandoTurmas.set(false),
    });
  }

  onTurmaChange(): void {
    this.horarioId.set('');
    this.horarios.set([]);
    this.alunos.set([]);
    this.presentes.set(new Set());
    const id = this.turmaId();
    if (!id) return;
    this.carregandoHorarios.set(true);
    this.horarioService.getByTurma(id).subscribe({
      next: (res) => { this.horarios.set(res.dados ?? []); this.carregandoHorarios.set(false); },
      error: () => this.carregandoHorarios.set(false),
    });
  }

  onHorarioChange(): void {
    this.alunos.set([]);
    this.presentes.set(new Set());
    this.carregarAlunos();
  }

  carregarAlunos(): void {
    const turmaId = this.turmaId();
    const horarioId = this.horarioId();
    if (!turmaId || !horarioId) return;

    this.carregandoAlunos.set(true);
    this.erro.set('');

    Promise.all([
      this.turmaService.getAlunos(turmaId).toPromise(),
      this.presencaService.getPresencasAula(horarioId, this.data()).toPromise(),
    ]).then(([alunosRes, presencasRes]) => {
      this.alunos.set(alunosRes?.dados ?? []);
      const ids = new Set((presencasRes?.dados ?? []).map((p: PresencaDto) => p.alunoId));
      this.jaPresentes = new Set(ids);
      this.presentes.set(new Set(ids));
      this.carregandoAlunos.set(false);
    }).catch(() => {
      this.erro.set('Erro ao carregar alunos da turma.');
      this.carregandoAlunos.set(false);
    });
  }

  togglePresente(alunoId: string): void {
    const set = new Set(this.presentes());
    if (set.has(alunoId)) set.delete(alunoId);
    else set.add(alunoId);
    this.presentes.set(set);
  }

  async salvar(): Promise<void> {
    if (!this.horarioId()) { this.erro.set('Selecione um horário.'); return; }
    this.salvando.set(true);

    const novos = Array.from(this.presentes()).filter(id => !this.jaPresentes.has(id));
    const reqs = novos.map((alunoId) =>
      this.presencaService.registrar({
        alunoId,
        horarioId: this.horarioId(),
        data: this.data(),
        metodoCheckin: 1,
      }).toPromise()
    );

    await Promise.allSettled(reqs);
    this.salvando.set(false);
    this.jaPresentes = new Set(this.presentes());
    this.modalSucesso.set(true);
  }

  onQrDetectado(token: string): void {
    this.modoQr.set(false);
    this.feedbackQr.set('Processando...');
    this.presencaService.registrarQrCode(token).subscribe({
      next: (res) => {
        this.feedbackQr.set(res.sucesso ? `✓ ${res.dados?.nomeAluno} registrado` : (res.mensagem ?? 'Erro'));
      },
      error: (err) => {
        this.feedbackQr.set(err.error?.mensagem ?? 'Token inválido');
        this.modoQr.set(true);
      },
    });
  }

  horarioLabel(h: HorarioDto): string {
    return `${h.diaSemanaLabel} ${h.horaInicio}–${h.horaFim}${h.sala ? ' · ' + h.sala : ''}`;
  }
}
