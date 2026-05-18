import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';
import {
  FuncionarioListaDto,
  CreateFuncionarioRequest,
  UpdateFuncionarioRequest,
} from '../models/funcionario.model';
import { UsuarioResumoDto } from '../models/usuario.model';

@Injectable({ providedIn: 'root' })
export class FuncionarioService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/funcionarios`;

  getAll(filtros?: { nome?: string; perfil?: string }): Observable<BaseResponse<FuncionarioListaDto[]>> {
    const params: Record<string, string> = {};
    if (filtros?.nome) params['nome'] = filtros.nome;
    if (filtros?.perfil) params['perfil'] = filtros.perfil;
    return this.http.get<BaseResponse<FuncionarioListaDto[]>>(this.api, { params });
  }

  getProfessores(): Observable<BaseResponse<UsuarioResumoDto[]>> {
    return this.http.get<BaseResponse<UsuarioResumoDto[]>>(`${environment.apiUrl}/api/usuarios/professores`);
  }

  getById(id: string): Observable<BaseResponse<FuncionarioListaDto>> {
    return this.http.get<BaseResponse<FuncionarioListaDto>>(`${this.api}/${id}`);
  }

  create(data: CreateFuncionarioRequest): Observable<BaseResponse<FuncionarioListaDto>> {
    return this.http.post<BaseResponse<FuncionarioListaDto>>(this.api, data);
  }

  update(id: string, data: UpdateFuncionarioRequest): Observable<BaseResponse<FuncionarioListaDto>> {
    return this.http.put<BaseResponse<FuncionarioListaDto>>(`${this.api}/${id}`, data);
  }

  delete(id: string): Observable<BaseResponse<void>> {
    return this.http.delete<BaseResponse<void>>(`${this.api}/${id}`);
  }
}
