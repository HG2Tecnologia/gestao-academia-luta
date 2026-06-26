import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';

export interface MembroDto {
  id: string;
  nome: string;
  email?: string;
  perfil: string;
}

export interface GrupoFamiliarDto {
  id: string;
  nome: string;
  criadoEm: string;
  membros: MembroDto[];
}

@Injectable({ providedIn: 'root' })
export class GruposFamiliaresService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/grupos-familiares`;

  listar(): Observable<BaseResponse<GrupoFamiliarDto[]>> {
    return this.http.get<BaseResponse<GrupoFamiliarDto[]>>(this.api);
  }

  criar(nome: string): Observable<BaseResponse<GrupoFamiliarDto>> {
    return this.http.post<BaseResponse<GrupoFamiliarDto>>(this.api, { nome });
  }

  renomear(id: string, nome: string): Observable<BaseResponse<GrupoFamiliarDto>> {
    return this.http.put<BaseResponse<GrupoFamiliarDto>>(`${this.api}/${id}`, { nome });
  }

  excluir(id: string): Observable<BaseResponse<void>> {
    return this.http.delete<BaseResponse<void>>(`${this.api}/${id}`);
  }

  adicionarMembro(grupoId: string, alunoId: string): Observable<BaseResponse<GrupoFamiliarDto>> {
    return this.http.post<BaseResponse<GrupoFamiliarDto>>(`${this.api}/${grupoId}/membros`, { alunoId });
  }

  removerMembro(grupoId: string, membroId: string): Observable<BaseResponse<void>> {
    return this.http.delete<BaseResponse<void>>(`${this.api}/${grupoId}/membros/${membroId}`);
  }
}
