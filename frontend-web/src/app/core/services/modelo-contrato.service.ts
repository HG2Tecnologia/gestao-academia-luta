import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';
import {
  ModeloContratoDto,
  CreateModeloContratoRequest,
  UpdateModeloContratoRequest,
} from '../models/contrato.model';

@Injectable({ providedIn: 'root' })
export class ModeloContratoService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/contratos/modelos`;

  listar(): Observable<BaseResponse<ModeloContratoDto[]>> {
    return this.http.get<BaseResponse<ModeloContratoDto[]>>(this.api);
  }

  obter(id: string): Observable<BaseResponse<ModeloContratoDto>> {
    return this.http.get<BaseResponse<ModeloContratoDto>>(`${this.api}/${id}`);
  }

  criar(data: CreateModeloContratoRequest): Observable<BaseResponse<ModeloContratoDto>> {
    return this.http.post<BaseResponse<ModeloContratoDto>>(this.api, data);
  }

  atualizar(id: string, data: UpdateModeloContratoRequest): Observable<BaseResponse<ModeloContratoDto>> {
    return this.http.put<BaseResponse<ModeloContratoDto>>(`${this.api}/${id}`, data);
  }

  excluir(id: string): Observable<BaseResponse<void>> {
    return this.http.delete<BaseResponse<void>>(`${this.api}/${id}`);
  }
}
