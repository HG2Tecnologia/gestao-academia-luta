import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';
import { PlanoDto, CreatePlanoRequest, UpdatePlanoRequest } from '../models/plano.model';

@Injectable({ providedIn: 'root' })
export class PlanoService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/planos`;

  listar(): Observable<BaseResponse<PlanoDto[]>> {
    return this.http.get<BaseResponse<PlanoDto[]>>(this.api);
  }

  criar(dto: CreatePlanoRequest): Observable<BaseResponse<PlanoDto>> {
    return this.http.post<BaseResponse<PlanoDto>>(this.api, dto);
  }

  atualizar(id: string, dto: UpdatePlanoRequest): Observable<BaseResponse<PlanoDto>> {
    return this.http.put<BaseResponse<PlanoDto>>(`${this.api}/${id}`, dto);
  }

  deletar(id: string): Observable<BaseResponse<boolean>> {
    return this.http.delete<BaseResponse<boolean>>(`${this.api}/${id}`);
  }
}
