import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { collection, doc, getDocs, addDoc, updateDoc, deleteDoc, query, where, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import { HorarioDto, GradeHorariosDto, CreateHorarioRequest } from '../models/horario.model';

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/** Mesma convenção de `dia_semana` do mobile: 0 = Domingo ... 6 = Sábado. */
const DIAS_SEMANA = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

/** Espelho de `academias/{id}/horarios` em `mobile/lib/core/firestore_service.dart`. */
@Injectable({ providedIn: 'root' })
export class HorarioService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  private async carregarComJoins(filtroTurmaId?: string): Promise<HorarioDto[]> {
    const academiaId = this.academiaId;
    const horariosRef = collection(db, 'academias', academiaId, 'horarios');
    const [horariosSnap, turmasSnap, modalidadesSnap, funcionariosSnap, matriculasSnap] = await Promise.all([
      getDocs(filtroTurmaId ? query(horariosRef, where('turma_id', '==', filtroTurmaId)) : horariosRef),
      getDocs(collection(db, 'academias', academiaId, 'turmas')),
      getDocs(collection(db, 'academias', academiaId, 'modalidades')),
      getDocs(collection(db, 'academias', academiaId, 'funcionarios')),
      getDocs(query(collection(db, 'academias', academiaId, 'matriculas'), where('ativo', '==', true))),
    ]);

    const turmaPorId = new Map<string, any>();
    turmasSnap.forEach((d) => turmaPorId.set(d.id, d.data()));
    const modalidadeNomePorId = new Map<string, string>();
    modalidadesSnap.forEach((d) => modalidadeNomePorId.set(d.id, d.data()['nome'] ?? ''));
    const professorNomePorId = new Map<string, string>();
    funcionariosSnap.forEach((d) => professorNomePorId.set(d.id, d.data()['nome'] ?? ''));
    const alunosPorTurma = new Map<string, number>();
    matriculasSnap.forEach((d) => {
      const turmaId = String(d.data()['turma_id'] ?? '');
      alunosPorTurma.set(turmaId, (alunosPorTurma.get(turmaId) ?? 0) + 1);
    });

    return horariosSnap.docs.map((d) => {
      const h = d.data();
      const turmaId = String(h['turma_id'] ?? '');
      const turma = turmaPorId.get(turmaId) ?? {};
      const dia = Number(h['dia_semana'] ?? 0);
      const dto: HorarioDto = {
        id: d.id,
        turmaId,
        nomeTurma: turma['nome'] ?? '',
        nomeModalidade: turma['modalidadeNome'] ?? modalidadeNomePorId.get(turma['modalidadeId']) ?? '',
        nomeProfessor: turma['professorNome'] ?? professorNomePorId.get(turma['professorId']) ?? '',
        diaSemana: dia,
        diaSemanaLabel: DIAS_SEMANA[dia] ?? '',
        horaInicio: h['hora_inicio'] ?? '',
        horaFim: h['hora_fim'] ?? '',
        sala: h['sala'] ?? undefined,
        totalAlunos: alunosPorTurma.get(turmaId) ?? 0,
        capacidadeMaxima: turma['capacidadeMaxima'] ?? 0,
      };
      return dto;
    });
  }

  getGrade(): Observable<BaseResponse<GradeHorariosDto>> {
    return from(this.carregarComJoins()).pipe(
      map((todos) => {
        const grade: Record<string, HorarioDto[]> = {};
        for (const dia of DIAS_SEMANA) grade[dia] = [];
        for (const h of todos) {
          (grade[h.diaSemanaLabel] ??= []).push(h);
        }
        for (const dia of Object.keys(grade)) {
          grade[dia].sort((a, b) => a.horaInicio.localeCompare(b.horaInicio));
        }
        return ok<GradeHorariosDto>({ grade });
      }),
    );
  }

  getByTurma(turmaId: string): Observable<BaseResponse<HorarioDto[]>> {
    return from(this.carregarComJoins(turmaId)).pipe(map((lista) => ok(lista)));
  }

  create(data: CreateHorarioRequest): Observable<BaseResponse<HorarioDto>> {
    const academiaId = this.academiaId;
    const payload = {
      turma_id: data.turmaId,
      dia_semana: data.diaSemana,
      hora_inicio: data.horaInicio,
      hora_fim: data.horaFim,
      sala: data.sala || null,
      criado_em: serverTimestamp(),
    };
    return from(addDoc(collection(db, 'academias', academiaId, 'horarios'), payload)).pipe(
      map((ref) =>
        ok<HorarioDto>({
          id: ref.id,
          turmaId: data.turmaId,
          nomeTurma: '',
          nomeModalidade: '',
          nomeProfessor: '',
          diaSemana: data.diaSemana,
          diaSemanaLabel: DIAS_SEMANA[data.diaSemana] ?? '',
          horaInicio: data.horaInicio,
          horaFim: data.horaFim,
          sala: data.sala,
          totalAlunos: 0,
          capacidadeMaxima: 0,
        }),
      ),
    );
  }

  update(id: string, data: CreateHorarioRequest): Observable<BaseResponse<HorarioDto>> {
    const academiaId = this.academiaId;
    const payload = {
      turma_id: data.turmaId,
      dia_semana: data.diaSemana,
      hora_inicio: data.horaInicio,
      hora_fim: data.horaFim,
      sala: data.sala || null,
      atualizado_em: serverTimestamp(),
    };
    return from(updateDoc(doc(db, 'academias', academiaId, 'horarios', id), payload)).pipe(
      map(() =>
        ok<HorarioDto>({
          id,
          turmaId: data.turmaId,
          nomeTurma: '',
          nomeModalidade: '',
          nomeProfessor: '',
          diaSemana: data.diaSemana,
          diaSemanaLabel: DIAS_SEMANA[data.diaSemana] ?? '',
          horaInicio: data.horaInicio,
          horaFim: data.horaFim,
          sala: data.sala,
          totalAlunos: 0,
          capacidadeMaxima: 0,
        }),
      ),
    );
  }

  delete(id: string): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    return from(deleteDoc(doc(db, 'academias', academiaId, 'horarios', id))).pipe(map(() => ok(undefined)));
  }
}
