import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';

export interface CatracaValidacaoDto {
  permitido: boolean;
  nomeAluno: string | null;
  motivo: string | null;
  presencaRegistrada: boolean;
  turmaNome: string | null;
}

export interface CatracaAberturaDto {
  aberta: boolean;
  abertaEm: string;
  operadorNome: string;
}

@Injectable({ providedIn: 'root' })
export class CatracaService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/catraca`;

  validar(identificador: string): Observable<BaseResponse<CatracaValidacaoDto>> {
    return this.http.post<BaseResponse<CatracaValidacaoDto>>(`${this.api}/validar`, { identificador });
  }

  abrirManualmente(): Observable<BaseResponse<CatracaAberturaDto>> {
    return this.http.post<BaseResponse<CatracaAberturaDto>>(`${this.api}/abrir`, {});
  }
}
