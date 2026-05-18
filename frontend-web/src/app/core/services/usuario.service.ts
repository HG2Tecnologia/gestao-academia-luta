import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { UsuarioResumoDto } from '../models/usuario.model';

interface ApiResponse<T> { sucesso: boolean; mensagem?: string; dados?: T; }

export interface MeuPerfilDto {
  id: string;
  nome: string;
  email?: string;
  telefone?: string;
  perfil: string;
}

@Injectable({ providedIn: 'root' })
export class UsuarioService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiUrl}/api/usuarios`;

  getProfessores(): Observable<ApiResponse<UsuarioResumoDto[]>> {
    return this.http.get<ApiResponse<UsuarioResumoDto[]>>(`${this.base}/professores`);
  }

  getMeuPerfil(): Observable<ApiResponse<MeuPerfilDto>> {
    return this.http.get<ApiResponse<MeuPerfilDto>>(`${this.base}/me`);
  }

  atualizarMeuPerfil(data: { nome: string; telefone?: string }): Observable<ApiResponse<MeuPerfilDto>> {
    return this.http.put<ApiResponse<MeuPerfilDto>>(`${this.base}/me`, data);
  }
}
