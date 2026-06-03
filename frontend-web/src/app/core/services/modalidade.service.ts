import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';

export interface ModalidadeDto {
  id: string;
  nome: string;
  descricao?: string;
  ativo: boolean;
  sistemaFaixasJson?: string;
}

export interface CreateModalidadeRequest {
  nome: string;
  descricao?: string;
  ativo?: boolean;
}

@Injectable({ providedIn: 'root' })
export class ModalidadeService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/modalidades`;

  getAll(): Observable<BaseResponse<ModalidadeDto[]>> {
    return this.http.get<BaseResponse<ModalidadeDto[]>>(this.api);
  }

  getById(id: string): Observable<BaseResponse<ModalidadeDto>> {
    return this.http.get<BaseResponse<ModalidadeDto>>(`${this.api}/${id}`);
  }

  create(data: CreateModalidadeRequest): Observable<BaseResponse<ModalidadeDto>> {
    return this.http.post<BaseResponse<ModalidadeDto>>(this.api, data);
  }

  update(id: string, data: CreateModalidadeRequest & { ativo: boolean }): Observable<BaseResponse<ModalidadeDto>> {
    return this.http.put<BaseResponse<ModalidadeDto>>(`${this.api}/${id}`, data);
  }

  delete(id: string): Observable<BaseResponse<void>> {
    return this.http.delete<BaseResponse<void>>(`${this.api}/${id}`);
  }

  seed(): Observable<{ sucesso: boolean; mensagem: string }> {
    return this.http.post<{ sucesso: boolean; mensagem: string }>(`${this.api}/seed`, {});
  }
}
