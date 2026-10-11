import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { collection, doc, getDoc, getDocs, addDoc, updateDoc, deleteDoc, query, where, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import {
  GraduacaoDto,
  FaixaDto,
  CreateFaixaRequest,
  RegistrarGraduacaoRequest,
  AlunoAptoDto,
} from '../models/graduacao.model';

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/**
 * Espelho de `academias/{id}/faixas` e `academias/{id}/graduacoes` em
 * `mobile/lib/core/firestore_service.dart`. `faixas` mistura convenções
 * (campo próprio `modalidadeId` em camelCase, mas `tem_graus`/`max_graus`
 * em snake_case) — mantido assim de propósito pra bater com o que o
 * mobile já grava, não "arruma" a inconsistência aqui.
 *
 * A atualização da faixa atual do aluno (`faixasAtuais` no doc dele)
 * acontece automaticamente via Cloud Function (`onGraduacaoCriada`,
 * trigger em `graduacoes/{id}`) — não precisa replicar essa lógica
 * aqui, só criar o doc de graduação do jeito certo.
 */
@Injectable({ providedIn: 'root' })
export class GraduacaoService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  // ── Faixas ──────────────────────────────────────────────────────

  private async carregarFaixas(modalidadeId?: string): Promise<FaixaDto[]> {
    const academiaId = this.academiaId;
    const [faixasSnap, modalidadesSnap] = await Promise.all([
      getDocs(
        modalidadeId
          ? query(collection(db, 'academias', academiaId, 'faixas'), where('modalidadeId', '==', modalidadeId))
          : collection(db, 'academias', academiaId, 'faixas'),
      ),
      getDocs(collection(db, 'academias', academiaId, 'modalidades')),
    ]);
    const nomeModalidadePorId = new Map<string, string>();
    modalidadesSnap.forEach((d) => nomeModalidadePorId.set(d.id, d.data()['nome'] ?? ''));

    const lista = faixasSnap.docs.map((d) => {
      const f = d.data();
      const dto: FaixaDto = {
        id: d.id,
        modalidadeId: f['modalidadeId'] ?? '',
        nomeModalidade: nomeModalidadePorId.get(f['modalidadeId']) ?? '',
        nome: f['nome'] ?? '',
        cor: f['cor'] ?? '#FFFFFF',
        corBarra: f['cor_barra'] ?? f['cor'] ?? '#000000',
        temGraus: f['tem_graus'] === true,
        maxGraus: f['max_graus'] ?? 0,
        ordem: f['ordem'] ?? 0,
        requisitosMesesMinimos: f['requisitosMesesMinimos'] ?? 0,
        requisitosPresencasMinimas: f['requisitosPresencasMinimas'] ?? 0,
        descricao: f['descricao'] ?? undefined,
      };
      return dto;
    });
    lista.sort((a, b) => a.modalidadeId.localeCompare(b.modalidadeId) || a.ordem - b.ordem);
    return lista;
  }

  getAllFaixas(): Observable<BaseResponse<FaixaDto[]>> {
    return from(this.carregarFaixas()).pipe(map((lista) => ok(lista)));
  }

  getFaixasByModalidade(modalidadeId: string): Observable<BaseResponse<FaixaDto[]>> {
    return from(this.carregarFaixas(modalidadeId)).pipe(map((lista) => ok(lista)));
  }

  criarFaixa(data: CreateFaixaRequest): Observable<BaseResponse<FaixaDto>> {
    const academiaId = this.academiaId;
    const payload = {
      modalidadeId: data.modalidadeId,
      nome: data.nome,
      cor: data.cor,
      ordem: data.ordem,
      tem_graus: data.temGraus,
      max_graus: data.maxGraus,
      requisitosMesesMinimos: data.requisitosMesesMinimos,
      requisitosPresencasMinimas: data.requisitosPresencasMinimas,
      descricao: data.descricao ?? null,
      criado_em: serverTimestamp(),
    };
    return from(addDoc(collection(db, 'academias', academiaId, 'faixas'), payload)).pipe(
      map((ref) => ok<FaixaDto>({ id: ref.id, nomeModalidade: '', ...data })),
    );
  }

  atualizarFaixa(id: string, data: CreateFaixaRequest): Observable<BaseResponse<FaixaDto>> {
    const academiaId = this.academiaId;
    const payload = {
      modalidadeId: data.modalidadeId,
      nome: data.nome,
      cor: data.cor,
      ordem: data.ordem,
      tem_graus: data.temGraus,
      max_graus: data.maxGraus,
      requisitosMesesMinimos: data.requisitosMesesMinimos,
      requisitosPresencasMinimas: data.requisitosPresencasMinimas,
      descricao: data.descricao ?? null,
      atualizado_em: serverTimestamp(),
    };
    return from(updateDoc(doc(db, 'academias', academiaId, 'faixas', id), payload)).pipe(
      map(() => ok<FaixaDto>({ id, nomeModalidade: '', ...data })),
    );
  }

  deletarFaixa(id: string): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    return from(deleteDoc(doc(db, 'academias', academiaId, 'faixas', id))).pipe(map(() => ok(undefined)));
  }

  reordenarFaixas(_modalidadeId: string, ids: string[]): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    return from(
      Promise.all(ids.map((id, i) => updateDoc(doc(db, 'academias', academiaId, 'faixas', id), { ordem: i + 1 }))),
    ).pipe(map(() => ok(undefined)));
  }

  // ── Graduações ──────────────────────────────────────────────────

  getHistoricoAluno(alunoId: string): Observable<BaseResponse<GraduacaoDto[]>> {
    return from(this.carregarHistorico(alunoId)).pipe(map((lista) => ok(lista)));
  }

  private async carregarHistorico(alunoId?: string): Promise<GraduacaoDto[]> {
    const academiaId = this.academiaId;
    const graduacoesRef = collection(db, 'academias', academiaId, 'graduacoes');
    const [graduacoesSnap, faixas, modalidadesSnap, usuariosSnap, funcionariosSnap] = await Promise.all([
      getDocs(alunoId ? query(graduacoesRef, where('aluno_id', '==', alunoId)) : graduacoesRef),
      this.carregarFaixas(),
      getDocs(collection(db, 'academias', academiaId, 'modalidades')),
      getDocs(collection(db, 'academias', academiaId, 'usuarios')),
      getDocs(collection(db, 'academias', academiaId, 'funcionarios')),
    ]);
    const faixaPorId = new Map(faixas.map((f) => [f.id, f]));
    const modalidadeNomePorId = new Map<string, string>();
    modalidadesSnap.forEach((d) => modalidadeNomePorId.set(d.id, d.data()['nome'] ?? ''));
    const nomePorAluno = new Map<string, string>();
    usuariosSnap.forEach((d) => nomePorAluno.set(d.id, d.data()['nome'] ?? ''));
    const nomePorProfessor = new Map<string, string>();
    funcionariosSnap.forEach((d) => nomePorProfessor.set(d.id, d.data()['nome'] ?? ''));

    const lista = graduacoesSnap.docs.map((d) => {
      const g = d.data();
      const faixaId = g['faixa_id'] ?? '';
      const faixa = faixaPorId.get(faixaId);
      const modalidadeId = g['modalidade_id'] ?? faixa?.modalidadeId ?? '';
      const dto: GraduacaoDto = {
        id: d.id,
        alunoId: g['aluno_id'] ?? '',
        nomeAluno: nomePorAluno.get(g['aluno_id']) ?? '',
        faixaId,
        nomeFaixa: faixa?.nome ?? '',
        corFaixa: faixa?.cor ?? '#FFFFFF',
        corBarraFaixa: faixa?.corBarra ?? '#000000',
        faixaTemGraus: faixa?.temGraus ?? false,
        faixaMaxGraus: faixa?.maxGraus ?? 0,
        grau: g['grau'] ?? 0,
        modalidadeId,
        nomeModalidade: modalidadeNomePorId.get(modalidadeId) ?? '',
        dataExame: g['data_exame'] ?? '',
        aprovado: g['aprovado'] === true,
        professorId: g['professor_id'] ?? '',
        nomeProfessor: nomePorProfessor.get(g['professor_id']) ?? '',
        observacoes: g['observacoes'] ?? undefined,
        certificadoUrl: g['certificado_url'] ?? undefined,
        faixaOrdem: faixa?.ordem ?? 0,
      };
      return dto;
    });
    lista.sort((a, b) => b.dataExame.localeCompare(a.dataExame));
    return lista;
  }

  registrar(data: RegistrarGraduacaoRequest): Observable<BaseResponse<GraduacaoDto>> {
    const academiaId = this.academiaId;
    return from(this.registrarEDevolver(academiaId, data)).pipe(map((dto) => ok(dto)));
  }

  private async registrarEDevolver(academiaId: string, data: RegistrarGraduacaoRequest): Promise<GraduacaoDto> {
    const faixaSnap = await getDoc(doc(db, 'academias', academiaId, 'faixas', data.faixaId));
    const faixa = faixaSnap.data();
    const payload = {
      aluno_id: data.alunoId,
      faixa_id: data.faixaId,
      data_exame: data.dataExame,
      professor_id: data.professorId,
      aprovado: data.aprovado,
      grau: data.grau,
      observacoes: data.observacoes ?? '',
      modalidade_id: faixa?.['modalidadeId'] ?? null,
      academia_id: academiaId,
    };
    const ref = await addDoc(collection(db, 'academias', academiaId, 'graduacoes'), {
      ...payload,
      criado_em: serverTimestamp(),
    });
    return {
      id: ref.id,
      alunoId: data.alunoId,
      nomeAluno: '',
      faixaId: data.faixaId,
      nomeFaixa: faixa?.['nome'] ?? '',
      corFaixa: faixa?.['cor'] ?? '#FFFFFF',
      corBarraFaixa: faixa?.['cor_barra'] ?? '#000000',
      faixaTemGraus: faixa?.['tem_graus'] === true,
      faixaMaxGraus: faixa?.['max_graus'] ?? 0,
      grau: data.grau,
      modalidadeId: faixa?.['modalidadeId'] ?? '',
      nomeModalidade: '',
      dataExame: data.dataExame,
      aprovado: data.aprovado,
      professorId: data.professorId,
      nomeProfessor: '',
      observacoes: data.observacoes,
      faixaOrdem: faixa?.['ordem'] ?? 0,
    };
  }

  /** Espelho de `getAptosGraduacao` no mobile: lógica simplificada (todos os alunos ativos) — a UI decide quem de fato está apto. */
  getAptos(_faixaId: string): Observable<BaseResponse<AlunoAptoDto[]>> {
    const academiaId = this.academiaId;
    return from(getDocs(query(collection(db, 'academias', academiaId, 'usuarios'), where('ativo', '==', true)))).pipe(
      map((snap) => {
        const lista: AlunoAptoDto[] = snap.docs.map((d) => {
          const a = d.data();
          return {
            alunoId: d.id,
            nomeAluno: a['nome'] ?? '',
            emailAluno: a['email'] ?? '',
            mesesMatriculado: 0,
            totalPresencas: 0,
            mesesNecessarios: 0,
            presencasNecessarias: 0,
          };
        });
        return ok(lista);
      }),
    );
  }
}
