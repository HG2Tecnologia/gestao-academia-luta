import { Injectable, inject } from '@angular/core';
import { Observable, forkJoin, from, map } from 'rxjs';
import { collection, getDocs, query, where } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { AlunoService } from './aluno.service';
import { TurmaService } from './turma.service';
import { HorarioService } from './horario.service';
import { BaseResponse } from '../models/auth.model';
import { dataLocalISO } from '../utils/date.util';

export interface DashboardResumoDto {
  totalAlunos: number;
  turmasAtivas: number;
  presencasHoje: number;
  /**
   * Antes chamado `alunosInadimplentes`, mas o card da tela sempre
   * rotulou isso como "Sem turma" (desde antes da migração, com o
   * backend C#) — o nome do campo nunca bateu com o que era exibido.
   * Renomeado pra bater com o que o card de fato mostra: alunos
   * ativos sem nenhuma turma matriculada.
   */
  alunosSemTurma: number;
  proximasAulas: ProximaAulaDto[];
}

export interface FrequenciaDiariaDto {
  data: string;
  total: number;
}

export interface ProximaAulaDto {
  horarioId: string;
  turma: string;
  modalidade: string;
  horaInicio: string;
  horaFim: string;
  sala?: string;
  totalAlunos: number;
  capacidadeMaxima: number;
}

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

const DIAS_SEMANA = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

/**
 * Não existe um "dashboard" no mobile — essa tela é só uma composição
 * de dados que já vêm de outros services (Aluno, Turma, Horário) +
 * duas contagens simples direto em `presencas`. Reaproveita os
 * services já portados em vez de duplicar os joins.
 */
@Injectable({ providedIn: 'root' })
export class DashboardService {
  private readonly authService = inject(FirebaseAuthService);
  private readonly alunoService = inject(AlunoService);
  private readonly turmaService = inject(TurmaService);
  private readonly horarioService = inject(HorarioService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  getResumo(): Observable<BaseResponse<DashboardResumoDto>> {
    const academiaId = this.academiaId;
    const hojeStr = dataLocalISO();

    return forkJoin({
      alunos: this.alunoService.getAll({ ativo: true, pageSize: 10000 }),
      turmas: this.turmaService.getAll({ ativo: true }),
      horarios: this.horarioService.getGrade(),
      presencasHoje: from(getDocs(query(collection(db, 'academias', academiaId, 'presencas'), where('data', '==', hojeStr)))),
    }).pipe(
      map(({ alunos, turmas, horarios, presencasHoje }) => {
        const itensAlunos = alunos.dados?.itens ?? [];
        const alunosSemTurma = itensAlunos.filter((a) => a.turmas.length === 0).length;

        const hoje = new Date();
        const diaLabel = DIAS_SEMANA[hoje.getDay()];
        const agoraHHmm = `${String(hoje.getHours()).padStart(2, '0')}:${String(hoje.getMinutes()).padStart(2, '0')}`;
        const doDia = (horarios.dados?.grade[diaLabel] ?? []).filter((h) => h.horaInicio >= agoraHHmm);
        const proximasAulas: ProximaAulaDto[] = doDia.slice(0, 5).map((h) => ({
          horarioId: h.id,
          turma: h.nomeTurma,
          modalidade: h.nomeModalidade,
          horaInicio: h.horaInicio,
          horaFim: h.horaFim,
          sala: h.sala,
          totalAlunos: h.totalAlunos,
          capacidadeMaxima: h.capacidadeMaxima,
        }));

        return ok<DashboardResumoDto>({
          totalAlunos: itensAlunos.length,
          turmasAtivas: turmas.dados?.length ?? 0,
          presencasHoje: presencasHoje.size,
          alunosSemTurma,
          proximasAulas,
        });
      }),
    );
  }

  getFrequencia(dias = 14): Observable<BaseResponse<FrequenciaDiariaDto[]>> {
    const academiaId = this.academiaId;
    return from(this.carregarFrequencia(academiaId, dias)).pipe(map((lista) => ok(lista)));
  }

  private async carregarFrequencia(academiaId: string, dias: number): Promise<FrequenciaDiariaDto[]> {
    const hoje = new Date();
    const datas: string[] = [];
    for (let i = dias - 1; i >= 0; i--) {
      const d = new Date(hoje);
      d.setDate(d.getDate() - i);
      datas.push(dataLocalISO(d));
    }
    const inicio = datas[0];

    const snap = await getDocs(query(collection(db, 'academias', academiaId, 'presencas'), where('data', '>=', inicio)));
    const contagemPorDia = new Map<string, number>();
    snap.forEach((d) => {
      const data = String(d.data()['data'] ?? '');
      contagemPorDia.set(data, (contagemPorDia.get(data) ?? 0) + 1);
    });

    return datas.map((data) => ({ data, total: contagemPorDia.get(data) ?? 0 }));
  }
}
