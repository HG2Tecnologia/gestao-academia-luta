import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';
import {
  AlunoListaDto,
  AlunoDetalheDto,
  AniversarianteDto,
  CreateAlunoRequest,
  UpdateAlunoRequest,
  PagedResult,
} from '../models/aluno.model';

@Injectable({ providedIn: 'root' })
export class AlunoService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/alunos`;

  getAll(filtros?: { nome?: string; ativo?: boolean; page?: number; pageSize?: number }): Observable<BaseResponse<PagedResult<AlunoListaDto>>> {
    const params: Record<string, string> = {};
    if (filtros?.nome) params['nome'] = filtros.nome;
    if (filtros?.ativo !== undefined) params['ativo'] = String(filtros.ativo);
    if (filtros?.page) params['page'] = String(filtros.page);
    if (filtros?.pageSize) params['pageSize'] = String(filtros.pageSize);
    return this.http.get<BaseResponse<PagedResult<AlunoListaDto>>>(this.api, { params });
  }

  buscarPorNome(nome: string): Observable<BaseResponse<PagedResult<AlunoListaDto>>> {
    return this.http.get<BaseResponse<PagedResult<AlunoListaDto>>>(this.api, { params: { nome, pageSize: '10' } });
  }

  getById(id: string): Observable<BaseResponse<AlunoDetalheDto>> {
    return this.http.get<BaseResponse<AlunoDetalheDto>>(`${this.api}/${id}`);
  }

  create(data: CreateAlunoRequest): Observable<BaseResponse<AlunoListaDto>> {
    return this.http.post<BaseResponse<AlunoListaDto>>(this.api, data);
  }

  update(id: string, data: UpdateAlunoRequest): Observable<BaseResponse<AlunoListaDto>> {
    return this.http.put<BaseResponse<AlunoListaDto>>(`${this.api}/${id}`, data);
  }

  toggleAtivo(id: string, ativo: boolean): Observable<BaseResponse<AlunoListaDto>> {
    return this.http.patch<BaseResponse<AlunoListaDto>>(`${this.api}/${id}/status`, { ativo });
  }

  delete(id: string): Observable<BaseResponse<void>> {
    return this.http.delete<BaseResponse<void>>(`${this.api}/${id}`);
  }

  getAniversariantes(mes?: number): Observable<BaseResponse<AniversarianteDto[]>> {
    const params: Record<string, string> = {};
    if (mes !== undefined) params['mes'] = String(mes);
    return this.http.get<BaseResponse<AniversarianteDto[]>>(`${this.api}/aniversariantes`, { params });
  }
}
