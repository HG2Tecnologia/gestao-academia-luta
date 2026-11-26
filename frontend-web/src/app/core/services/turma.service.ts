import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  addDoc,
  setDoc,
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
import { veSomenteTurmasProprias } from '../models/stored-user.model';

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
        planoPadraoId: t['planoPadraoId'] ?? undefined,
        ativo: t['ativo'] === true,
      });
    });
    const user = this.authService.currentUser();
    return veSomenteTurmasProprias(user) ? turmas.filter((t) => t.professorId === user!.id) : turmas;
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
    if (!base && veSomenteTurmasProprias(this.authService.currentUser())) {
      throw new Error('Turma de outro professor.');
    }
    const t = snap.data() ?? {};

    const horarios: HorarioResumoDto[] = horariosSnap.docs.map((d) => {
      const h = d.data();
      const dia = Number(h['dia_semana'] ?? 0);
      return {
        id: d.id,
        diaSemana: dia,
        diaSemanaLabel: DIAS_SEMANA[dia] ?? '',
        horaInicio: String(h['hora_inicio'] ?? '').slice(0, 5),
        horaFim: String(h['hora_fim'] ?? '').slice(0, 5),
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
      planoPadraoId: base?.planoPadraoId,
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
      planoPadraoId: data.planoPadraoId || null,
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
      planoPadraoId: data.planoPadraoId || null,
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
    const matricularEVincular = async () => {
      const ref = await addDoc(collection(db, 'academias', academiaId, 'matriculas'), payload);
      await this.vincularPlanoPadrao(academiaId, alunoId, turmaId);
      return ref;
    };
    return from(matricularEVincular()).pipe(
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
   * Espelho de `vincularPlanoPadraoDaTurma` no app: aluno sem plano herda o
   * plano padrão da turma. A matrícula já foi criada — falha aqui não a desfaz.
   */
  private async vincularPlanoPadrao(academiaId: string, alunoId: string, turmaId: string): Promise<void> {
    try {
      const turma = (await getDoc(doc(db, 'academias', academiaId, 'turmas', turmaId))).data();
      const planoId = String(turma?.['planoPadraoId'] ?? '');
      if (!planoId) return;
      const modalidadeId = String(turma?.['modalidadeId'] ?? '');
      const academia = (await getDoc(doc(db, 'academias', academiaId))).data();

      if (academia?.['cobranca_por_modalidade_ativa'] === true) {
        if (!modalidadeId) return;
        const vinculos = collection(db, 'academias', academiaId, 'planos_modalidade');
        const existentes = await getDocs(query(
          vinculos,
          where('aluno_id', '==', alunoId),
          where('modalidade_id', '==', modalidadeId),
          where('ativo', '==', true),
        ));
        if (!existentes.empty) return;
        const novo = doc(vinculos);
        await setDoc(novo, {
          id: novo.id,
          aluno_id: alunoId,
          modalidade_id: modalidadeId,
          plano_id: planoId,
          dia_vencimento: Math.min(28, new Date().getDate()),
          ativo: true,
          criado_em: serverTimestamp(),
        });
      } else {
        const alunoRef = doc(db, 'academias', academiaId, 'usuarios', alunoId);
        if ((await getDoc(alunoRef)).data()?.['plano_id']) return;
        await updateDoc(alunoRef, { plano_id: planoId, atualizado_em: serverTimestamp() });
      }
    } catch (erro) {
      console.warn('[TurmaService] plano padrão não vinculado:', erro);
    }
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
