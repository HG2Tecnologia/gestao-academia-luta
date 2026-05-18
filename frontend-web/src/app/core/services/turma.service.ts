import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';
import {
  TurmaDto,
  TurmaDetalheDto,
  CreateTurmaRequest,
  UpdateTurmaRequest,
  MatriculaDto,
} from '../models/turma.model';

@Injectable({ providedIn: 'root' })
export class TurmaService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/turmas`;

  getAll(filtros?: { modalidadeId?: string; ativo?: boolean }): Observable<BaseResponse<TurmaDto[]>> {
    let params: Record<string, string> = {};
    if (filtros?.modalidadeId) params['modalidadeId'] = filtros.modalidadeId;
    if (filtros?.ativo !== undefined) params['ativo'] = String(filtros.ativo);
    return this.http.get<BaseResponse<TurmaDto[]>>(this.api, { params });
  }

  getById(id: string): Observable<BaseResponse<TurmaDetalheDto>> {
    return this.http.get<BaseResponse<TurmaDetalheDto>>(`${this.api}/${id}`);
  }

  create(data: CreateTurmaRequest): Observable<BaseResponse<TurmaDto>> {
    return this.http.post<BaseResponse<TurmaDto>>(this.api, data);
  }

  update(id: string, data: UpdateTurmaRequest): Observable<BaseResponse<TurmaDto>> {
    return this.http.put<BaseResponse<TurmaDto>>(`${this.api}/${id}`, data);
  }

  delete(id: string): Observable<BaseResponse<void>> {
    return this.http.delete<BaseResponse<void>>(`${this.api}/${id}`);
  }

  getAlunos(turmaId: string): Observable<BaseResponse<MatriculaDto[]>> {
    return this.http.get<BaseResponse<MatriculaDto[]>>(`${this.api}/${turmaId}/alunos`);
  }

  matricular(turmaId: string, alunoId: string): Observable<BaseResponse<MatriculaDto>> {
    return this.http.post<BaseResponse<MatriculaDto>>(`${this.api}/${turmaId}/matricular`, { alunoId });
  }

  desmatricular(turmaId: string, alunoId: string): Observable<BaseResponse<void>> {
    return this.http.delete<BaseResponse<void>>(`${this.api}/${turmaId}/matricular/${alunoId}`);
  }
}
