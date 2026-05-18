import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';
import {
  PagamentoDto,
  ResumoFinanceiroDto,
  RelatorioAnualDto,
  CreatePagamentoRequest,
  UpdatePagamentoRequest,
} from '../models/financeiro.model';

@Injectable({ providedIn: 'root' })
export class FinanceiroService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/financeiro`;

  getResumo(ano?: number, mes?: number): Observable<BaseResponse<ResumoFinanceiroDto>> {
    const params: Record<string, string> = {};
    if (ano) params['ano'] = String(ano);
    if (mes) params['mes'] = String(mes);
    return this.http.get<BaseResponse<ResumoFinanceiroDto>>(`${this.api}/resumo`, { params });
  }

  listar(filtros?: { alunoId?: string; status?: string; ano?: number; mes?: number; page?: number; pageSize?: number }): Observable<BaseResponse<PagamentoDto[]>> {
    const params: Record<string, string> = {};
    if (filtros?.alunoId) params['alunoId'] = filtros.alunoId;
    if (filtros?.status) params['status'] = filtros.status;
    if (filtros?.ano) params['ano'] = String(filtros.ano);
    if (filtros?.mes) params['mes'] = String(filtros.mes);
    if (filtros?.page) params['page'] = String(filtros.page);
    if (filtros?.pageSize) params['pageSize'] = String(filtros.pageSize);
    return this.http.get<BaseResponse<PagamentoDto[]>>(this.api, { params });
  }

  listarPorAluno(alunoId: string): Observable<BaseResponse<PagamentoDto[]>> {
    return this.http.get<BaseResponse<PagamentoDto[]>>(`${this.api}/aluno/${alunoId}`);
  }

  criar(dto: CreatePagamentoRequest): Observable<BaseResponse<PagamentoDto>> {
    return this.http.post<BaseResponse<PagamentoDto>>(this.api, dto);
  }

  atualizar(id: string, dto: UpdatePagamentoRequest): Observable<BaseResponse<PagamentoDto>> {
    return this.http.patch<BaseResponse<PagamentoDto>>(`${this.api}/${id}`, dto);
  }

  deletar(id: string): Observable<BaseResponse<boolean>> {
    return this.http.delete<BaseResponse<boolean>>(`${this.api}/${id}`);
  }

  gerarCobrancasMensais(): Observable<BaseResponse<number>> {
    return this.http.post<BaseResponse<number>>(`${this.api}/gerar-cobrancas`, {});
  }

  getRelatorioAnual(ano?: number): Observable<BaseResponse<RelatorioAnualDto>> {
    const params: Record<string, string> = {};
    if (ano) params['ano'] = String(ano);
    return this.http.get<BaseResponse<RelatorioAnualDto>>(`${this.api}/relatorio-anual`, { params });
  }
}
