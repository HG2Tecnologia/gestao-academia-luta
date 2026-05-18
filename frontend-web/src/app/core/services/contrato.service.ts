import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';
import {
  ContratoDto,
  ContratoDetalheDto,
  ContratoPublicoDto,
  CreateContratoRequest,
  AssinarContratoRequest,
} from '../models/contrato.model';

@Injectable({ providedIn: 'root' })
export class ContratoService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/contratos`;
  private readonly publicApi = `${environment.apiUrl}/api/public/contratos`;

  listar(alunoId?: string): Observable<BaseResponse<ContratoDto[]>> {
    const params: Record<string, string> = {};
    if (alunoId) params['alunoId'] = alunoId;
    return this.http.get<BaseResponse<ContratoDto[]>>(this.api, { params });
  }

  obter(id: string): Observable<BaseResponse<ContratoDetalheDto>> {
    return this.http.get<BaseResponse<ContratoDetalheDto>>(`${this.api}/${id}`);
  }

  criar(data: CreateContratoRequest): Observable<BaseResponse<ContratoDto>> {
    return this.http.post<BaseResponse<ContratoDto>>(this.api, data);
  }

  assinar(id: string, data: AssinarContratoRequest): Observable<BaseResponse<ContratoDto>> {
    return this.http.post<BaseResponse<ContratoDto>>(`${this.api}/${id}/assinar`, data);
  }

  cancelar(id: string): Observable<BaseResponse<void>> {
    return this.http.post<BaseResponse<void>>(`${this.api}/${id}/cancelar`, {});
  }

  obterPublico(token: string): Observable<BaseResponse<ContratoPublicoDto>> {
    return this.http.get<BaseResponse<ContratoPublicoDto>>(`${this.publicApi}/${token}`);
  }

  assinarPublico(token: string, data: AssinarContratoRequest): Observable<BaseResponse<ContratoDto>> {
    return this.http.post<BaseResponse<ContratoDto>>(`${this.publicApi}/${token}/assinar`, data);
  }
}
