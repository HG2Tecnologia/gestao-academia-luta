import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { NotificacaoDto } from '../models/notificacao.model';

interface ApiResponse<T> { sucesso: boolean; dados?: T; mensagem?: string; }

@Injectable({ providedIn: 'root' })
export class NotificacaoService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiUrl}/notificacoes`;

  listar(): Observable<ApiResponse<NotificacaoDto[]>> {
    return this.http.get<ApiResponse<NotificacaoDto[]>>(this.base);
  }

  marcarLida(id: string): Observable<ApiResponse<void>> {
    return this.http.patch<ApiResponse<void>>(`${this.base}/${id}/lida`, {});
  }

  marcarTodasLidas(): Observable<ApiResponse<void>> {
    return this.http.post<ApiResponse<void>>(`${this.base}/marcar-todas-lidas`, {});
  }

  excluir(id: string): Observable<ApiResponse<void>> {
    return this.http.delete<ApiResponse<void>>(`${this.base}/${id}`);
  }
}
