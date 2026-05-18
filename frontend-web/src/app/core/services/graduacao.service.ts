import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';
import {
  GraduacaoDto,
  FaixaDto,
  CreateFaixaRequest,
  RegistrarGraduacaoRequest,
  AlunoAptoDto,
} from '../models/graduacao.model';

@Injectable({ providedIn: 'root' })
export class GraduacaoService {
  private readonly http = inject(HttpClient);
  private readonly apiGrad = `${environment.apiUrl}/api/graduacoes`;
  private readonly apiFaixa = `${environment.apiUrl}/api/faixas`;

  getHistoricoAluno(alunoId: string): Observable<BaseResponse<GraduacaoDto[]>> {
    return this.http.get<BaseResponse<GraduacaoDto[]>>(this.apiGrad, { params: { alunoId } });
  }

  registrar(data: RegistrarGraduacaoRequest): Observable<BaseResponse<GraduacaoDto>> {
    return this.http.post<BaseResponse<GraduacaoDto>>(this.apiGrad, data);
  }

  getAptos(faixaId: string): Observable<BaseResponse<AlunoAptoDto[]>> {
    return this.http.get<BaseResponse<AlunoAptoDto[]>>(`${this.apiGrad}/aptos`, { params: { faixaId } });
  }

  getAllFaixas(): Observable<BaseResponse<FaixaDto[]>> {
    return this.http.get<BaseResponse<FaixaDto[]>>(this.apiFaixa);
  }

  getFaixasByModalidade(modalidadeId: string): Observable<BaseResponse<FaixaDto[]>> {
    return this.http.get<BaseResponse<FaixaDto[]>>(this.apiFaixa, { params: { modalidadeId } });
  }

  criarFaixa(data: CreateFaixaRequest): Observable<BaseResponse<FaixaDto>> {
    return this.http.post<BaseResponse<FaixaDto>>(this.apiFaixa, data);
  }

  atualizarFaixa(id: string, data: CreateFaixaRequest): Observable<BaseResponse<FaixaDto>> {
    return this.http.put<BaseResponse<FaixaDto>>(`${this.apiFaixa}/${id}`, data);
  }

  deletarFaixa(id: string): Observable<BaseResponse<void>> {
    return this.http.delete<BaseResponse<void>>(`${this.apiFaixa}/${id}`);
  }

  reordenarFaixas(modalidadeId: string, ids: string[]): Observable<BaseResponse<void>> {
    return this.http.patch<BaseResponse<void>>(`${this.apiFaixa}/reordenar`, { modalidadeId, ids });
  }
}
