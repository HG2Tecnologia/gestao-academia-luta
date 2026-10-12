import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { httpsCallable } from 'firebase/functions';
import { collection, doc, getDoc, getDocs, addDoc, updateDoc, query, where, orderBy, serverTimestamp } from 'firebase/firestore';
import { db, functions } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import {
  ContratoDto,
  ContratoDetalheDto,
  ContratoPublicoDto,
  CreateContratoRequest,
  AssinarContratoRequest,
} from '../models/contrato.model';

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

const STATUS_LABEL: Record<number, string> = { 1: 'Pendente', 2: 'Assinado', 3: 'Cancelado' };

/**
 * `academias/{id}/contratos` existe no Firestore do mobile, mas é
 * código morto lá (nenhuma tela Dart cria/lê/assina) — feature
 * exclusiva do CRM web, pensada pra ser assinada via link público
 * (o CRM não tem login de aluno). Convenção de `status` usada aqui
 * (1=Pendente/2=Assinado/3=Cancelado) segue a que já estava
 * codificada nas telas Angular (badges, filtros), não o único
 * comentário isolado do mobile ("1=Assinado" numa função nunca
 * chamada).
 *
 * A assinatura em si (sem login, só com o token da URL) nunca pode
 * passar pelas regras normais do Firestore — por isso usa as Cloud
 * Functions `contratoPublicoObter`/`contratoPublicoAssinar`
 * (`functions/contrato-functions.js`), que validam o token
 * server-side com o Admin SDK. Todo o resto (CRUD autenticado pela
 * equipe) é Firestore direto, como o resto do CRM.
 */
@Injectable({ providedIn: 'root' })
export class ContratoService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  listar(alunoId?: string): Observable<BaseResponse<ContratoDto[]>> {
    const academiaId = this.academiaId;
    return from(this.carregarLista(academiaId, alunoId)).pipe(map((lista) => ok(lista)));
  }

  private async carregarLista(academiaId: string, alunoId?: string): Promise<ContratoDto[]> {
    const ref = collection(db, 'academias', academiaId, 'contratos');
    const snap = await getDocs(alunoId ? query(ref, where('aluno_id', '==', alunoId), orderBy('criado_em', 'desc')) : query(ref, orderBy('criado_em', 'desc')));
    return snap.docs.map((d) => this.toDto(d.id, d.data()));
  }

  private toDto(id: string, c: Record<string, any>): ContratoDto {
    return {
      id,
      alunoId: c['aluno_id'] ?? '',
      nomeAluno: c['nome_aluno'] ?? '',
      matriculaId: c['matricula_id'] ?? undefined,
      modalidadeId: c['modalidade_id'] ?? undefined,
      nomeModalidade: c['nome_modalidade'] ?? undefined,
      status: c['status'] ?? 1,
      statusLabel: STATUS_LABEL[c['status'] ?? 1] ?? 'Pendente',
      dataAssinatura: c['data_assinatura']?.toDate?.()?.toISOString?.() ?? undefined,
      nomeAssinou: c['nome_assinou'] ?? undefined,
      criadoEm: c['criado_em']?.toDate?.()?.toISOString?.() ?? '',
      tokenPublico: c['token_publico'] ?? '',
    };
  }

  obter(id: string): Observable<BaseResponse<ContratoDetalheDto>> {
    const academiaId = this.academiaId;
    return from(getDoc(doc(db, 'academias', academiaId, 'contratos', id))).pipe(
      map((snap) => {
        const c = snap.data() ?? {};
        return ok<ContratoDetalheDto>({
          ...this.toDto(snap.id, c),
          conteudoHtml: c['conteudo_html'] ?? '',
          ipAssinatura: c['ip_assinatura'] ?? undefined,
        });
      }),
    );
  }

  criar(data: CreateContratoRequest): Observable<BaseResponse<ContratoDto>> {
    const academiaId = this.academiaId;
    return from(this.criarContrato(academiaId, data)).pipe(map((dto) => ok(dto)));
  }

  private async criarContrato(academiaId: string, data: CreateContratoRequest): Promise<ContratoDto> {
    const [alunoSnap, academiaSnap, modalidadeSnap, modeloSnap] = await Promise.all([
      getDoc(doc(db, 'academias', academiaId, 'usuarios', data.alunoId)),
      getDoc(doc(db, 'academias', academiaId)),
      data.modalidadeId ? getDoc(doc(db, 'academias', academiaId, 'modalidades', data.modalidadeId)) : Promise.resolve(null),
      data.modeloContratoId ? getDoc(doc(db, 'academias', academiaId, 'modelos_contrato', data.modeloContratoId)) : Promise.resolve(null),
    ]);
    const aluno = alunoSnap.data() ?? {};
    const academia = academiaSnap.data() ?? {};
    const modalidade = modalidadeSnap?.data();
    const modelo = modeloSnap?.data();

    let planoNome = aluno['plano_nome'] ?? '';
    let valor = '';
    if (aluno['plano_id']) {
      const planoSnap = await getDoc(doc(db, 'academias', academiaId, 'planos', aluno['plano_id']));
      const plano = planoSnap.data();
      if (plano) {
        planoNome = plano['nome'] ?? planoNome;
        valor = (plano['valorMensal'] ?? plano['valor_mensal'] ?? 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
      }
    }

    const hoje = new Date();
    const dataContrato = hoje.toLocaleDateString('pt-BR');
    const variaveis: Record<string, string> = {
      nomeAluno: aluno['nome'] ?? '',
      email: aluno['email'] ?? '',
      telefone: aluno['telefone'] ?? '',
      dataNascimento: aluno['data_nascimento'] ?? '',
      plano: planoNome,
      valor,
      modalidade: modalidade?.['nome'] ?? '',
      dataInicio: dataContrato,
      dataFim: '',
      academia: academia['nome'] ?? '',
      cnpj: academia['cnpj'] ?? '',
      dataContrato,
    };

    const templateBase = modelo?.['conteudoHtml'] ?? '<p>{{nomeAluno}} — contrato de {{plano}}</p>';
    const conteudoHtml = templateBase.replace(/\{\{(\w+)\}\}/g, (match: string, chave: string) => variaveis[chave] ?? match);

    const payload = {
      aluno_id: data.alunoId,
      nome_aluno: aluno['nome'] ?? '',
      matricula_id: data.matriculaId ?? null,
      modalidade_id: data.modalidadeId ?? null,
      nome_modalidade: modalidade?.['nome'] ?? null,
      conteudo_html: conteudoHtml,
      status: 1,
      token_publico: crypto.randomUUID(),
      criado_em: serverTimestamp(),
    };
    const ref = await addDoc(collection(db, 'academias', academiaId, 'contratos'), payload);
    return {
      id: ref.id,
      alunoId: data.alunoId,
      nomeAluno: payload.nome_aluno,
      matriculaId: data.matriculaId,
      modalidadeId: data.modalidadeId,
      nomeModalidade: modalidade?.['nome'],
      status: 1,
      statusLabel: 'Pendente',
      criadoEm: new Date().toISOString(),
      tokenPublico: payload.token_publico,
    };
  }

  assinar(id: string, data: AssinarContratoRequest): Observable<BaseResponse<ContratoDto>> {
    const academiaId = this.academiaId;
    const payload = { status: 2, nome_assinou: data.nomeCompleto, data_assinatura: serverTimestamp() };
    return from(updateDoc(doc(db, 'academias', academiaId, 'contratos', id), payload)).pipe(
      map(() => ok<ContratoDto>({ id, alunoId: '', nomeAluno: '', status: 2, statusLabel: 'Assinado', criadoEm: '', tokenPublico: '' })),
    );
  }

  cancelar(id: string): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    return from(updateDoc(doc(db, 'academias', academiaId, 'contratos', id), { status: 3 })).pipe(map(() => ok(undefined)));
  }

  // ── Assinatura pública (sem login — Cloud Functions) ────────────

  obterPublico(token: string): Observable<BaseResponse<ContratoPublicoDto>> {
    const contratoPublicoObter = httpsCallable(functions, 'contratoPublicoObter');
    return from(contratoPublicoObter({ token })).pipe(map((res) => res.data as BaseResponse<ContratoPublicoDto>));
  }

  assinarPublico(token: string, data: AssinarContratoRequest): Observable<BaseResponse<ContratoDto>> {
    const contratoPublicoAssinar = httpsCallable(functions, 'contratoPublicoAssinar');
    return from(contratoPublicoAssinar({ token, nomeCompleto: data.nomeCompleto })).pipe(map((res) => res.data as BaseResponse<ContratoDto>));
  }
}
