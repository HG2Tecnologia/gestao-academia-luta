import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  serverTimestamp,
} from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import {
  TurmaDto,
  TurmaDetalheDto,
  CreateTurmaRequest,
  UpdateTurmaRequest,
  MatriculaDto,
  HorarioResumoDto,
} from '../models/turma.model';

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

const DIAS_SEMANA = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

/**
 * Espelho de `mobile/lib/core/firestore_service.dart` pra turmas — mesmas
 * coleções (`turmas`, `matriculas`, `horarios`), mesmos campos (`turmas`
 * usa `modalidadeId`/`professorId`/`capacidadeMaxima` em camelCase,
 * diferente do resto do schema que é snake_case — não "corrige" aqui pra
 * não divergir do que o mobile já grava).
 */
@Injectable({ providedIn: 'root' })
export class TurmaService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  private async carregarTodas(): Promise<TurmaDto[]> {
    const academiaId = this.academiaId;
    const [turmasSnap, modalidadesSnap, funcionariosSnap] = await Promise.all([
      getDocs(collection(db, 'academias', academiaId, 'turmas')),
      getDocs(collection(db, 'academias', academiaId, 'modalidades')),
      getDocs(collection(db, 'academias', academiaId, 'funcionarios')),
    ]);
    const modalidadeNomePorId = new Map<string, string>();
    modalidadesSnap.forEach((d) => modalidadeNomePorId.set(d.id, d.data()['nome'] ?? ''));
    const professorNomePorId = new Map<string, string>();
    funcionariosSnap.forEach((d) => professorNomePorId.set(d.id, d.data()['nome'] ?? ''));

    const turmas: TurmaDto[] = [];
    turmasSnap.forEach((d) => {
      const t = d.data();
      if (t['deleted_at']) return;
      const modalidadeId = t['modalidadeId'] ?? '';
      const professorId = t['professorId'] ?? '';
      turmas.push({
        id: d.id,
        nome: t['nome'] ?? '',
        modalidadeId,
        modalidadeNome: t['modalidadeNome'] ?? modalidadeNomePorId.get(modalidadeId) ?? '',
        professorId,
        professorNome: t['professorNome'] ?? professorNomePorId.get(professorId) ?? '',
        nivel: t['nivel'] ?? undefined,
        capacidadeMaxima: t['capacidadeMaxima'] ?? 0,
        ativo: t['ativo'] === true,
      });
    });
    return turmas;
  }

  getAll(filtros?: { modalidadeId?: string; ativo?: boolean }): Observable<BaseResponse<TurmaDto[]>> {
    return from(this.carregarTodas()).pipe(
      map((todas) => {
        let lista = todas;
        if (filtros?.modalidadeId) lista = lista.filter((t) => t.modalidadeId === filtros.modalidadeId);
        if (filtros?.ativo !== undefined) lista = lista.filter((t) => t.ativo === filtros.ativo);
        lista.sort((a, b) => a.nome.localeCompare(b.nome, 'pt-BR'));
        return ok(lista);
      }),
    );
  }

  getById(id: string): Observable<BaseResponse<TurmaDetalheDto>> {
    return from(this.carregarDetalhe(id));
  }

  private async carregarDetalhe(id: string): Promise<BaseResponse<TurmaDetalheDto>> {
    const academiaId = this.academiaId;
    const [snap, matriculasSnap, horariosSnap, todas] = await Promise.all([
      getDoc(doc(db, 'academias', academiaId, 'turmas', id)),
      getDocs(query(collection(db, 'academias', academiaId, 'matriculas'), where('turma_id', '==', id), where('ativo', '==', true))),
      getDocs(query(collection(db, 'academias', academiaId, 'horarios'), where('turma_id', '==', id))),
      this.carregarTodas(),
    ]);
    const base = todas.find((t) => t.id === id);
    const t = snap.data() ?? {};

    const horarios: HorarioResumoDto[] = horariosSnap.docs.map((d) => {
      const h = d.data();
      const dia = Number(h['dia_semana'] ?? 0);
      return {
        id: d.id,
        diaSemana: dia,
        diaSemanaLabel: DIAS_SEMANA[dia] ?? '',
        horaInicio: h['hora_inicio'] ?? '',
        horaFim: h['hora_fim'] ?? '',
        sala: h['sala'] ?? undefined,
      };
    });

    const nomeTurma = base?.nome ?? t['nome'] ?? '';
    const alunos: MatriculaDto[] = await Promise.all(
      matriculasSnap.docs.map(async (m) => {
        const data = m.data();
        const alunoId = String(data['aluno_id'] ?? '');
        const alunoSnap = await getDoc(doc(db, 'academias', academiaId, 'usuarios', alunoId));
        const aluno = alunoSnap.data() ?? {};
        return {
          id: m.id,
          alunoId,
          nomeAluno: aluno['nome'] ?? '',
          emailAluno: aluno['email'] ?? '',
          turmaId: id,
          nomeTurma,
          dataInicio: data['data_matricula'] ?? '',
          dataFim: undefined,
          ativo: data['ativo'] === true,
        };
      }),
    );

    const dto: TurmaDetalheDto = {
      id: snap.id,
      nome: nomeTurma,
      modalidadeId: base?.modalidadeId ?? '',
      modalidadeNome: base?.modalidadeNome ?? '',
      professorId: base?.professorId ?? '',
      professorNome: base?.professorNome ?? '',
      nivel: base?.nivel,
      capacidadeMaxima: base?.capacidadeMaxima ?? 0,
      ativo: base?.ativo ?? false,
      totalAlunos: alunos.length,
      alunos,
      horarios,
    };
    return ok(dto);
  }

  /** Resolve nome/e-mail dos alunos matriculados — mesmos dados já embutidos em `getById`, exposto à parte pra quem só precisa da lista. */
  getAlunos(turmaId: string): Observable<BaseResponse<MatriculaDto[]>> {
    return from(this.carregarDetalhe(turmaId)).pipe(map((res) => ok(res.dados?.alunos ?? [])));
  }

  create(data: CreateTurmaRequest): Observable<BaseResponse<TurmaDto>> {
    const academiaId = this.academiaId;
    const payload = {
      nome: data.nome,
      modalidadeId: data.modalidadeId,
      professorId: data.professorId || null,
      nivel: data.nivel ?? null,
      capacidadeMaxima: data.capacidadeMaxima,
      ativo: true,
      criado_em: serverTimestamp(),
    };
    return from(addDoc(collection(db, 'academias', academiaId, 'turmas'), payload)).pipe(
      map((ref) =>
        ok<TurmaDto>({
          id: ref.id,
          nome: data.nome,
          modalidadeId: data.modalidadeId,
          modalidadeNome: '',
          professorId: data.professorId,
          professorNome: '',
          nivel: data.nivel,
          capacidadeMaxima: data.capacidadeMaxima,
          ativo: true,
        }),
      ),
    );
  }

  update(id: string, data: UpdateTurmaRequest): Observable<BaseResponse<TurmaDto>> {
    const academiaId = this.academiaId;
    const payload = {
      nome: data.nome,
      modalidadeId: data.modalidadeId,
      professorId: data.professorId || null,
      nivel: data.nivel ?? null,
      capacidadeMaxima: data.capacidadeMaxima,
      ativo: data.ativo,
      atualizado_em: serverTimestamp(),
    };
    return from(updateDoc(doc(db, 'academias', academiaId, 'turmas', id), payload)).pipe(
      map(() =>
        ok<TurmaDto>({
          id,
          nome: data.nome,
          modalidadeId: data.modalidadeId,
          modalidadeNome: '',
          professorId: data.professorId,
          professorNome: '',
          nivel: data.nivel,
          capacidadeMaxima: data.capacidadeMaxima,
          ativo: data.ativo,
        }),
      ),
    );
  }

  /** Soft delete — mesmo padrão do mobile (nunca apaga o doc, só marca inativo). */
  delete(id: string): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    return from(updateDoc(doc(db, 'academias', academiaId, 'turmas', id), { ativo: false, atualizado_em: serverTimestamp() })).pipe(
      map(() => ok(undefined)),
    );
  }

  matricular(turmaId: string, alunoId: string): Observable<BaseResponse<MatriculaDto>> {
    const academiaId = this.academiaId;
    const payload = {
      aluno_id: alunoId,
      turma_id: turmaId,
      data_matricula: new Date().toISOString(),
      ativo: true,
      origem: 'crm_web',
    };
    return from(addDoc(collection(db, 'academias', academiaId, 'matriculas'), payload)).pipe(
      map((ref) =>
        ok<MatriculaDto>({
          id: ref.id,
          alunoId,
          nomeAluno: '',
          emailAluno: '',
          turmaId,
          nomeTurma: '',
          dataInicio: payload.data_matricula,
          ativo: true,
        }),
      ),
    );
  }

  /**
   * Recebe `alunoId` (o componente passa `aluno.alunoId`, não o id da
   * matrícula) — acha a matrícula ativa correspondente e apaga. Hard
   * delete, igual o mobile faz pra desmatricular (diferente do soft-delete
   * usado em turmas/alunos).
   */
  desmatricular(turmaId: string, alunoId: string): Observable<BaseResponse<void>> {
    return from(this.apagarMatricula(turmaId, alunoId)).pipe(map(() => ok(undefined)));
  }

  private async apagarMatricula(turmaId: string, alunoId: string): Promise<void> {
    const academiaId = this.academiaId;
    const snap = await getDocs(
      query(
        collection(db, 'academias', academiaId, 'matriculas'),
        where('turma_id', '==', turmaId),
        where('aluno_id', '==', alunoId),
        where('ativo', '==', true),
      ),
    );
    await Promise.all(snap.docs.map((d) => deleteDoc(d.ref)));
  }
}
