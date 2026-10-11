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
import { httpsCallable } from 'firebase/functions';
import { db, functions } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import { statusEfetivo } from '../utils/pagamento-status.util';
import {
  PagamentoDto,
  ResumoFinanceiroDto,
  RelatorioAnualDto,
  ReceitaMensalDto,
  FrequenciaMensalDto,
  AlunoInadimplenteDto,
  CreatePagamentoRequest,
  UpdatePagamentoRequest,
  TipoPagamento,
} from '../models/financeiro.model';

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/** `atualizar()` recebe o status no código numérico ANTIGO do C# (1=Pago,2=Pendente,3=Atrasado,4=Cancelado,5=Previsto) — o componente antigo nunca mudou. Traduz pro código real do Firestore (0=Pendente,1=Pago,3=Previsto,4=Desconsiderado; "Atrasado" não se grava, é sempre derivado). */
function statusAntigoParaFirestore(statusAntigo: number): number {
  switch (statusAntigo) {
    case 1:
      return 1; // Pago
    case 4:
      return 4; // Cancelado → Desconsiderado
    case 5:
      return 3; // Previsto
    default:
      return 0; // Pendente / Atrasado (derivado, nunca gravado)
  }
}

function mesReferencia(ano: number, mes: number): string {
  return `${ano}-${String(mes).padStart(2, '0')}`;
}

/**
 * Espelho de `academias/{id}/pagamentos` em `mobile/lib/core/firestore_service.dart`
 * — mesma coleção, mesmos campos, mesma regra de status (`pagamento-status.util.ts`).
 * Geração de cobranças mensais reaproveita a MESMA Cloud Function
 * (`ensureChargesForPeriod`) que o app mobile usa, em vez de reimplementar
 * a lógica de negócio (dia de vencimento, plano por modalidade, etc.) aqui.
 */
@Injectable({ providedIn: 'root' })
export class FinanceiroService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  private async carregarComJoins(filtros?: { alunoId?: string; ano?: number; mes?: number }): Promise<PagamentoDto[]> {
    const academiaId = this.academiaId;
    const pagamentosRef = collection(db, 'academias', academiaId, 'pagamentos');
    const clausulas = [];
    if (filtros?.alunoId) clausulas.push(where('aluno_id', '==', filtros.alunoId));
    const snap = await getDocs(clausulas.length ? query(pagamentosRef, ...clausulas) : pagamentosRef);

    const alunoIds = new Set<string>();
    snap.forEach((d) => {
      const alunoId = d.data()['aluno_id'];
      if (alunoId) alunoIds.add(alunoId);
    });
    const nomePorAluno = new Map<string, { nome: string; telefone?: string }>();
    await Promise.all(
      [...alunoIds].map(async (id) => {
        const alunoSnap = await getDoc(doc(db, 'academias', academiaId, 'usuarios', id));
        const a = alunoSnap.data();
        if (a) nomePorAluno.set(id, { nome: a['nome'] ?? '', telefone: a['telefone'] ?? undefined });
      }),
    );

    const mesAlvo = filtros?.ano && filtros?.mes ? mesReferencia(filtros.ano, filtros.mes) : null;

    const lista: PagamentoDto[] = [];
    snap.forEach((d) => {
      const p = d.data();
      const mesRef = (p['mes_referencia'] as string) ?? (p['data_vencimento'] as string)?.slice(0, 7);
      if (mesAlvo && mesRef !== mesAlvo) return;
      const alunoId = String(p['aluno_id'] ?? '');
      const aluno = nomePorAluno.get(alunoId);
      lista.push({
        id: d.id,
        alunoId,
        nomeAluno: aluno?.nome ?? '',
        telefoneAluno: aluno?.telefone,
        tipo: p['tipo'] ?? 'Mensalidade',
        status: statusEfetivo(p['status'], p['data_vencimento']),
        valor: (p['valor'] as number) ?? 0,
        descricao: p['plano_nome'] ?? undefined,
        dataVencimento: p['data_vencimento'] ?? undefined,
        dataPagamento: p['data_pagamento'] ?? undefined,
        formaPagamento: p['forma_pagamento'] ?? undefined,
        observacoes: p['observacoes'] ?? undefined,
        criadoEm: p['criado_em']?.toDate?.()?.toISOString?.() ?? '',
      });
    });
    lista.sort((a, b) => (b.dataVencimento ?? '').localeCompare(a.dataVencimento ?? ''));
    return lista;
  }

  listar(filtros?: {
    alunoId?: string;
    status?: string;
    ano?: number;
    mes?: number;
    page?: number;
    pageSize?: number;
  }): Observable<BaseResponse<PagamentoDto[]>> {
    return from(this.carregarComJoins(filtros)).pipe(
      map((lista) => {
        let filtrada = filtros?.status ? lista.filter((p) => p.status === filtros.status) : lista;
        if (filtros?.pageSize) filtrada = filtrada.slice(0, filtros.pageSize);
        return ok(filtrada);
      }),
    );
  }

  listarPorAluno(alunoId: string): Observable<BaseResponse<PagamentoDto[]>> {
    return from(this.carregarComJoins({ alunoId })).pipe(map((lista) => ok(lista)));
  }

  getResumo(ano?: number, mes?: number): Observable<BaseResponse<ResumoFinanceiroDto>> {
    const hoje = new Date();
    const anoAlvo = ano ?? hoje.getFullYear();
    const mesAlvo = mes ?? hoje.getMonth() + 1;
    return from(this.carregarComJoins({ ano: anoAlvo, mes: mesAlvo })).pipe(
      map((pagamentosMes) => {
        let totalRecebidoMes = 0;
        let totalPendenteMes = 0;
        let totalPrevistoMes = 0;
        const alunosComPendencia = new Set<string>();
        for (const p of pagamentosMes) {
          if (p.status === 'Pago') totalRecebidoMes += p.valor;
          else if (p.status === 'Pendente' || p.status === 'Atrasado') {
            totalPendenteMes += p.valor;
            alunosComPendencia.add(p.alunoId);
          } else if (p.status === 'Previsto') totalPrevistoMes += p.valor;
        }

        const inadimplentesMap = new Map<string, AlunoInadimplenteDto>();
        let totalAtrasado = 0;
        for (const p of pagamentosMes) {
          if (p.status !== 'Atrasado') continue;
          totalAtrasado += p.valor;
          const atual = inadimplentesMap.get(p.alunoId);
          const diasAtraso = p.dataVencimento
            ? Math.max(0, Math.floor((Date.now() - new Date(p.dataVencimento).getTime()) / 86400000))
            : 0;
          if (atual) {
            atual.totalDevido += p.valor;
            atual.diasAtraso = Math.max(atual.diasAtraso, diasAtraso);
            if (!atual.ultimoVencimento || (p.dataVencimento ?? '') > atual.ultimoVencimento) {
              atual.ultimoVencimento = p.dataVencimento;
            }
          } else {
            inadimplentesMap.set(p.alunoId, {
              alunoId: p.alunoId,
              nomeAluno: p.nomeAluno,
              totalDevido: p.valor,
              diasAtraso,
              ultimoVencimento: p.dataVencimento,
            });
          }
        }

        const alunosNoMes = new Set(pagamentosMes.map((p) => p.alunoId));
        const resumo: ResumoFinanceiroDto = {
          totalRecebidoMes,
          totalPendenteMes,
          totalPrevistoMes,
          totalAtrasado,
          totalAlunos: alunosNoMes.size,
          alunosInadimplentes: inadimplentesMap.size,
          alunosEmDia: alunosNoMes.size - alunosComPendencia.size,
          pagamentosRecentes: pagamentosMes.slice(0, 10),
          inadimplentes: [...inadimplentesMap.values()].sort((a, b) => b.diasAtraso - a.diasAtraso),
        };
        return ok(resumo);
      }),
    );
  }

  criar(dto: CreatePagamentoRequest): Observable<BaseResponse<PagamentoDto>> {
    const academiaId = this.academiaId;
    const tipoLabel = TipoPagamento[dto.tipo] ?? 'Mensalidade';
    const payload = {
      aluno_id: dto.alunoId,
      tipo: tipoLabel,
      valor: dto.valor,
      status: statusAntigoParaFirestore(dto.status),
      plano_nome: dto.descricao ?? null,
      data_vencimento: dto.dataVencimento ?? null,
      data_pagamento: dto.dataPagamento ?? null,
      forma_pagamento: dto.formaPagamento ?? null,
      observacoes: dto.observacoes ?? null,
      mes_referencia: dto.dataVencimento ? dto.dataVencimento.slice(0, 7) : null,
      origem: 'crm_web',
      criado_em: serverTimestamp(),
    };
    return from(addDoc(collection(db, 'academias', academiaId, 'pagamentos'), payload)).pipe(
      map((ref) =>
        ok<PagamentoDto>({
          id: ref.id,
          alunoId: dto.alunoId,
          nomeAluno: '',
          tipo: tipoLabel,
          status: statusEfetivo(payload.status, payload.data_vencimento),
          valor: dto.valor,
          descricao: dto.descricao,
          dataVencimento: dto.dataVencimento,
          dataPagamento: dto.dataPagamento,
          formaPagamento: dto.formaPagamento,
          observacoes: dto.observacoes,
          criadoEm: new Date().toISOString(),
        }),
      ),
    );
  }

  atualizar(id: string, dto: UpdatePagamentoRequest): Observable<BaseResponse<PagamentoDto>> {
    const academiaId = this.academiaId;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const payload: Record<string, any> = {
      status: statusAntigoParaFirestore(dto.status),
      atualizado_em: serverTimestamp(),
    };
    if (dto.valor !== undefined) payload['valor'] = dto.valor;
    if (dto.dataPagamento !== undefined) payload['data_pagamento'] = dto.dataPagamento;
    if (dto.formaPagamento !== undefined) payload['forma_pagamento'] = dto.formaPagamento;
    if (dto.observacoes !== undefined) payload['observacoes'] = dto.observacoes;
    return from(updateDoc(doc(db, 'academias', academiaId, 'pagamentos', id), payload)).pipe(
      map(() =>
        ok<PagamentoDto>({
          id,
          alunoId: '',
          nomeAluno: '',
          tipo: '',
          status: statusEfetivo(payload['status'], dto.dataPagamento),
          valor: dto.valor ?? 0,
          dataPagamento: dto.dataPagamento,
          formaPagamento: dto.formaPagamento,
          observacoes: dto.observacoes,
          criadoEm: '',
        }),
      ),
    );
  }

  deletar(id: string): Observable<BaseResponse<boolean>> {
    const academiaId = this.academiaId;
    return from(deleteDoc(doc(db, 'academias', academiaId, 'pagamentos', id))).pipe(map(() => ok(true)));
  }

  /** Reaproveita a Cloud Function `ensureChargesForPeriod` — mesma geração de cobrança usada pelo app mobile, idempotente (chamar de novo não duplica). */
  gerarCobrancasMensais(): Observable<BaseResponse<number>> {
    const academiaId = this.academiaId;
    const hoje = new Date();
    const period = mesReferencia(hoje.getFullYear(), hoje.getMonth() + 1);
    const ensureCharges = httpsCallable(functions, 'ensureChargesForPeriod');
    return from(ensureCharges({ academiaId, period })).pipe(
      map((res) => ok((res.data as { criadas?: number })?.criadas ?? 0)),
    );
  }

  getRelatorioAnual(ano?: number): Observable<BaseResponse<RelatorioAnualDto>> {
    const anoAlvo = ano ?? new Date().getFullYear();
    return from(this.carregarRelatorioAnual(anoAlvo)).pipe(map((dto) => ok(dto)));
  }

  private async carregarRelatorioAnual(ano: number): Promise<RelatorioAnualDto> {
    const academiaId = this.academiaId;
    const [pagamentosSnap, presencasSnap, usuariosSnap] = await Promise.all([
      getDocs(collection(db, 'academias', academiaId, 'pagamentos')),
      getDocs(collection(db, 'academias', academiaId, 'presencas')),
      getDocs(query(collection(db, 'academias', academiaId, 'usuarios'), where('ativo', '==', true))),
    ]);

    const receitaPorMes = new Map<number, ReceitaMensalDto>();
    for (let m = 1; m <= 12; m++) receitaPorMes.set(m, { ano, mes: m, recebido: 0, pendente: 0, atrasado: 0 });

    const inadimplentesMap = new Map<string, AlunoInadimplenteDto>();
    const nomePorAluno = new Map<string, string>();
    usuariosSnap.forEach((d) => nomePorAluno.set(d.id, d.data()['nome'] ?? ''));

    pagamentosSnap.forEach((d) => {
      const p = d.data();
      const mesRef = (p['mes_referencia'] as string) ?? '';
      const [anoStr, mesStr] = mesRef.split('-');
      if (Number(anoStr) !== ano) return;
      const mes = Number(mesStr);
      const bucket = receitaPorMes.get(mes);
      if (!bucket) return;
      const status = statusEfetivo(p['status'], p['data_vencimento']);
      const valor = (p['valor'] as number) ?? 0;
      if (status === 'Pago') bucket.recebido += valor;
      else if (status === 'Pendente') bucket.pendente += valor;
      else if (status === 'Atrasado') {
        bucket.atrasado += valor;
        const alunoId = String(p['aluno_id'] ?? '');
        const existente = inadimplentesMap.get(alunoId);
        if (existente) existente.totalDevido += valor;
        else {
          inadimplentesMap.set(alunoId, {
            alunoId,
            nomeAluno: nomePorAluno.get(alunoId) ?? '',
            totalDevido: valor,
            diasAtraso: p['data_vencimento']
              ? Math.max(0, Math.floor((Date.now() - new Date(p['data_vencimento']).getTime()) / 86400000))
              : 0,
            ultimoVencimento: p['data_vencimento'] ?? undefined,
          });
        }
      }
    });

    const frequenciaPorMes = new Map<number, { total: number; alunos: Set<string> }>();
    for (let m = 1; m <= 12; m++) frequenciaPorMes.set(m, { total: 0, alunos: new Set() });
    presencasSnap.forEach((d) => {
      const p = d.data();
      const dataStr = (p['data'] as string) ?? (p['criado_em']?.toDate?.()?.toISOString?.() as string) ?? '';
      const [anoStr, mesStr] = dataStr.split('-');
      if (Number(anoStr) !== ano) return;
      const bucket = frequenciaPorMes.get(Number(mesStr));
      if (!bucket) return;
      bucket.total++;
      const alunoId = p['aluno_id'];
      if (alunoId) bucket.alunos.add(alunoId);
    });
    const frequenciaMensal: FrequenciaMensalDto[] = [...frequenciaPorMes.entries()].map(([mes, v]) => ({
      ano,
      mes,
      totalPresencas: v.total,
      alunosUnicos: v.alunos.size,
    }));

    const totalRecebidoAno = [...receitaPorMes.values()].reduce((acc, r) => acc + r.recebido, 0);

    return {
      ano,
      totalRecebidoAno,
      totalAlunosAtivos: usuariosSnap.size,
      totalInadimplentes: inadimplentesMap.size,
      receitaMensal: [...receitaPorMes.values()],
      frequenciaMensal,
      inadimplentes: [...inadimplentesMap.values()].sort((a, b) => b.totalDevido - a.totalDevido),
    };
  }
}
