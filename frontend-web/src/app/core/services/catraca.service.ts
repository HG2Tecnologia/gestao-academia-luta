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

export interface CatracaAlunoVinculoDto {
  alunoId: string;
  nomeAluno: string;
  email: string | null;
  deviceUserId: number | null;
  vinculado: boolean;
}

export interface CatracaAgentConfigDto {
  backendUrl: string;
  apiKey: string;
  academiaId: string;
  toletusCatracaIp: string;
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

  listarVinculos(): Observable<BaseResponse<CatracaAlunoVinculoDto[]>> {
    return this.http.get<BaseResponse<CatracaAlunoVinculoDto[]>>(`${this.api}/vinculos`);
  }

  vincularAluno(alunoId: string, deviceUserId?: number): Observable<BaseResponse<CatracaAlunoVinculoDto>> {
    return this.http.post<BaseResponse<CatracaAlunoVinculoDto>>(`${this.api}/vincular`, { alunoId, deviceUserId });
  }

  desvincularAluno(alunoId: string): Observable<BaseResponse<boolean>> {
    return this.http.delete<BaseResponse<boolean>>(`${this.api}/vincular/${alunoId}`);
  }

  getAgentConfig(): Observable<CatracaAgentConfigDto> {
    return this.http.get<CatracaAgentConfigDto>(`${this.api}/agent/config`);
  }

  downloadAgentPacote(): Observable<Blob> {
    return this.http.get(`${this.api}/agent/pacote`, { responseType: 'blob' });
  }
}
