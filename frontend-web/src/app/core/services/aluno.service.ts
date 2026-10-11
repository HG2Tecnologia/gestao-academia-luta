import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  addDoc,
  updateDoc,
  query,
  where,
  serverTimestamp,
} from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { db, functions } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import { statusEfetivo } from '../utils/pagamento-status.util';
import {
  AlunoListaDto,
  AlunoDetalheDto,
  AniversarianteDto,
  CreateAlunoRequest,
  UpdateAlunoRequest,
  PagedResult,
} from '../models/aluno.model';

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/**
 * Espelho de `mobile/lib/core/firestore_service.dart` pra alunos — mesma
 * coleção (`academias/{id}/usuarios`), mesmos campos. Mantém o contrato
 * `Observable<BaseResponse<T>>` do service C# antigo só pra não precisar
 * reescrever todo componente que já consome `AlunoService` — por dentro é
 * 100% Firestore agora.
 */
@Injectable({ providedIn: 'root' })
export class AlunoService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  /**
   * Monta o `AlunoListaDto[]` com os mesmos joins que o mobile faz na
   * ficha do aluno (turmas via `matriculas`, situação financeira via
   * `pagamentos`) — buscados em bloco (3-4 queries no total, não por
   * aluno) pra não custar N+1 leituras numa lista com muitos alunos.
   */
  private async carregarListaCompleta(): Promise<AlunoListaDto[]> {
    const academiaId = this.academiaId;
    const academiaRef = collection(db, 'academias', academiaId, 'usuarios');
    const turmasRef = collection(db, 'academias', academiaId, 'turmas');
    const matriculasRef = collection(db, 'academias', academiaId, 'matriculas');
    const pagamentosRef = collection(db, 'academias', academiaId, 'pagamentos');

    const [usuariosSnap, turmasSnap, matriculasSnap, pagamentosSnap] = await Promise.all([
      getDocs(academiaRef),
      getDocs(turmasRef),
      getDocs(query(matriculasRef, where('ativo', '==', true))),
      getDocs(pagamentosRef),
    ]);

    const turmaNomePorId = new Map<string, string>();
    turmasSnap.forEach((d) => turmaNomePorId.set(d.id, d.data()['nome'] ?? ''));

    const turmasPorAluno = new Map<string, string[]>();
    matriculasSnap.forEach((d) => {
      const m = d.data();
      const alunoId = String(m['aluno_id'] ?? '');
      const turmaId = String(m['turma_id'] ?? '');
      const nome = turmaNomePorId.get(turmaId);
      if (!alunoId || !nome) return;
      if (!turmasPorAluno.has(alunoId)) turmasPorAluno.set(alunoId, []);
      turmasPorAluno.get(alunoId)!.push(nome);
    });

    const situacaoPorAluno = new Map<string, 'EmDia' | 'Pendente' | 'Inadimplente'>();
    pagamentosSnap.forEach((d) => {
      const p = d.data();
      const alunoId = String(p['aluno_id'] ?? '');
      if (!alunoId) return;
      const status = statusEfetivo(p['status'], p['data_vencimento']);
      if (status === 'Atrasado') {
        situacaoPorAluno.set(alunoId, 'Inadimplente');
      } else if (status === 'Pendente' && situacaoPorAluno.get(alunoId) !== 'Inadimplente') {
        situacaoPorAluno.set(alunoId, 'Pendente');
      }
    });

    const lista: AlunoListaDto[] = [];
    usuariosSnap.forEach((d) => {
      const a = d.data();
      const faixaId = a['faixaPrincipalModalidadeId'];
      const faixaAtual = faixaId ? a['faixasAtuais']?.[faixaId] : undefined;
      lista.push({
        id: d.id,
        nome: a['nome'] ?? '',
        email: a['email'] ?? undefined,
        telefone: a['telefone'] ?? undefined,
        dataNascimento: a['data_nascimento'] ?? undefined,
        faixaAtualNome: faixaAtual?.faixaNome,
        faixaAtualCor: faixaAtual?.faixaCor,
        turmas: turmasPorAluno.get(d.id) ?? [],
        planoNome: a['plano_nome'] ?? undefined,
        ativo: a['ativo'] === true,
        criadoEm: a['criado_em']?.toDate?.()?.toISOString?.() ?? '',
        situacaoFinanceira: situacaoPorAluno.get(d.id) ?? 'EmDia',
      });
    });
    return lista;
  }

  getAll(filtros?: {
    nome?: string;
    ativo?: boolean;
    page?: number;
    pageSize?: number;
  }): Observable<BaseResponse<PagedResult<AlunoListaDto>>> {
    return from(this.carregarListaCompleta()).pipe(
      map((todos) => {
        let filtrados = todos;
        if (filtros?.nome) {
          const q = filtros.nome.toLowerCase();
          filtrados = filtrados.filter((a) => a.nome.toLowerCase().includes(q));
        }
        if (filtros?.ativo !== undefined) {
          filtrados = filtrados.filter((a) => a.ativo === filtros.ativo);
        }
        filtrados.sort((a, b) => a.nome.localeCompare(b.nome, 'pt-BR'));

        const pageSize = filtros?.pageSize ?? (filtrados.length || 1);
        const pagina = filtros?.page ?? 1;
        const inicio = (pagina - 1) * pageSize;
        const itens = filtros?.pageSize ? filtrados.slice(inicio, inicio + pageSize) : filtrados;

        return ok<PagedResult<AlunoListaDto>>({
          itens,
          totalItens: filtrados.length,
          pagina,
          tamanhoPagina: pageSize,
          totalPaginas: Math.max(1, Math.ceil(filtrados.length / pageSize)),
        });
      }),
    );
  }

  buscarPorNome(nome: string): Observable<BaseResponse<PagedResult<AlunoListaDto>>> {
    return this.getAll({ nome, pageSize: 10 });
  }

  private async carregarTurmasDoAluno(academiaId: string, alunoId: string): Promise<string[]> {
    const matriculasSnap = await getDocs(
      query(
        collection(db, 'academias', academiaId, 'matriculas'),
        where('aluno_id', '==', alunoId),
        where('ativo', '==', true),
      ),
    );
    const turmaIds = matriculasSnap.docs.map((d) => String(d.data()['turma_id'] ?? '')).filter(Boolean);
    const nomes = await Promise.all(
      turmaIds.map(async (turmaId) => {
        const turmaSnap = await getDoc(doc(db, 'academias', academiaId, 'turmas', turmaId));
        return turmaSnap.data()?.['nome'] as string | undefined;
      }),
    );
    return nomes.filter((n): n is string => !!n);
  }

  getById(id: string): Observable<BaseResponse<AlunoDetalheDto>> {
    const academiaId = this.academiaId;
    return from(
      Promise.all([getDoc(doc(db, 'academias', academiaId, 'usuarios', id)), this.carregarTurmasDoAluno(academiaId, id)]),
    ).pipe(
      map(([snap, turmas]) => {
        const a = snap.data() ?? {};
        const faixaId = a['faixaPrincipalModalidadeId'];
        const faixaAtual = faixaId ? a['faixasAtuais']?.[faixaId] : undefined;
        const dto: AlunoDetalheDto = {
          id: snap.id,
          nome: a['nome'] ?? '',
          email: a['email'] ?? undefined,
          telefone: a['telefone'] ?? '',
          dataNascimento: a['data_nascimento'] ?? undefined,
          contatoEmergenciaNome: a['contato_emergencia_nome'] ?? undefined,
          contatoEmergenciaTelefone: a['contato_emergencia_telefone'] ?? undefined,
          tipoPlano: a['tipo_plano'] ?? undefined,
          planoId: a['plano_id'] ?? undefined,
          planoNome: a['plano_nome'] ?? undefined,
          diaVencimento: a['dia_vencimento'] ?? undefined,
          faixaAtualNome: faixaAtual?.faixaNome,
          faixaAtualCor: faixaAtual?.faixaCor,
          turmas,
          ativo: a['ativo'] === true,
          criadoEm: a['criado_em']?.toDate?.()?.toISOString?.() ?? '',
          xpTotal: a['xp_total'] ?? 0,
          nivel: String(a['nivel'] ?? 0),
        };
        return ok(dto);
      }),
    );
  }

  create(data: CreateAlunoRequest): Observable<BaseResponse<AlunoListaDto>> {
    const academiaId = this.academiaId;
    const ref = collection(db, 'academias', academiaId, 'usuarios');
    const payload = {
      nome: data.nome,
      email: data.email ?? null,
      telefone: data.telefone,
      telefone_digits: data.telefone?.replace(/\D/g, '') ?? '',
      data_nascimento: data.dataNascimento ?? null,
      contato_emergencia_nome: data.contatoEmergenciaNome ?? null,
      contato_emergencia_telefone: data.contatoEmergenciaTelefone ?? null,
      plano_id: data.planoId ?? null,
      dia_vencimento: data.diaVencimento ?? null,
      perfil: 3,
      perfil_nome: 'Aluno',
      ativo: true,
      xp_total: 0,
      nivel: 0,
      origem: 'crm_web',
      criado_em: serverTimestamp(),
    };
    return from(addDoc(ref, payload)).pipe(
      map((docRef) =>
        ok<AlunoListaDto>({
          id: docRef.id,
          nome: data.nome,
          email: data.email,
          telefone: data.telefone,
          dataNascimento: data.dataNascimento,
          turmas: [],
          planoNome: undefined,
          ativo: true,
          criadoEm: new Date().toISOString(),
        }),
      ),
    );
  }

  update(id: string, data: UpdateAlunoRequest): Observable<BaseResponse<AlunoListaDto>> {
    const academiaId = this.academiaId;
    const ref = doc(db, 'academias', academiaId, 'usuarios', id);
    const payload = {
      nome: data.nome,
      email: data.email ?? null,
      telefone: data.telefone,
      telefone_digits: data.telefone?.replace(/\D/g, '') ?? '',
      data_nascimento: data.dataNascimento ?? null,
      contato_emergencia_nome: data.contatoEmergenciaNome ?? null,
      contato_emergencia_telefone: data.contatoEmergenciaTelefone ?? null,
      plano_id: data.planoId ?? null,
      dia_vencimento: data.diaVencimento ?? null,
      ativo: data.ativo,
      atualizado_em: serverTimestamp(),
    };
    return from(updateDoc(ref, payload)).pipe(
      map(() =>
        ok<AlunoListaDto>({
          id,
          nome: data.nome,
          email: data.email,
          telefone: data.telefone,
          dataNascimento: data.dataNascimento,
          turmas: [],
          ativo: data.ativo,
          criadoEm: '',
        }),
      ),
    );
  }

  toggleAtivo(id: string, ativo: boolean): Observable<BaseResponse<AlunoListaDto>> {
    const academiaId = this.academiaId;
    const ref = doc(db, 'academias', academiaId, 'usuarios', id);
    return from(updateDoc(ref, { ativo, atualizado_em: serverTimestamp() })).pipe(
      map(() => ok<AlunoListaDto>({ id, nome: '', turmas: [], ativo, criadoEm: '' })),
    );
  }

  /**
   * Exclusão definitiva — reaproveita a MESMA Cloud Function `excluirAluno`
   * que o app mobile usa (apaga matrículas, pagamentos, presenças e
   * histórico em cascata, sem afetar irmãos que compartilham telefone/
   * e-mail). Nunca um `deleteDoc` cru aqui — deixaria tudo isso órfão.
   */
  delete(id: string): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    const excluirAluno = httpsCallable(functions, 'excluirAluno');
    return from(excluirAluno({ academiaId, alunoId: id })).pipe(map(() => ok(undefined)));
  }

  getAniversariantes(mes?: number): Observable<BaseResponse<AniversarianteDto[]>> {
    return from(this.carregarListaCompleta()).pipe(
      map((lista) => {
        const alvo = mes ?? new Date().getMonth() + 1;
        const aniversariantes: AniversarianteDto[] = [];
        for (const a of lista) {
          if (!a.dataNascimento) continue;
          const d = new Date(a.dataNascimento);
          if (isNaN(d.getTime()) || d.getUTCMonth() + 1 !== alvo) continue;
          aniversariantes.push({
            id: a.id,
            nome: a.nome,
            diaNascimento: d.getUTCDate(),
            mesNascimento: d.getUTCMonth() + 1,
          });
        }
        aniversariantes.sort((a, b) => a.diaNascimento - b.diaNascimento);
        return ok(aniversariantes);
      }),
    );
  }
}
