import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';
import {
  PresencaDto,
  RegistrarPresencaRequest,
  PresencaRelatorioDto,
  QrTokenResponse,
} from '../models/presenca.model';

@Injectable({ providedIn: 'root' })
export class PresencaService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/presencas`;

  registrar(data: RegistrarPresencaRequest): Observable<BaseResponse<PresencaDto>> {
    return this.http.post<BaseResponse<PresencaDto>>(this.api, data);
  }

  registrarQrCode(token: string): Observable<BaseResponse<PresencaDto>> {
    return this.http.post<BaseResponse<PresencaDto>>(`${this.api}/qrcode`, { token });
  }

  getHistorico(alunoId: string, de: string, ate: string): Observable<BaseResponse<PresencaDto[]>> {
    return this.http.get<BaseResponse<PresencaDto[]>>(this.api, { params: { alunoId, de, ate } });
  }

  getPresencasAula(horarioId: string, data: string): Observable<BaseResponse<PresencaDto[]>> {
    return this.http.get<BaseResponse<PresencaDto[]>>(`${this.api}/aula`, { params: { horarioId, data } });
  }

  getRelatorio(turmaId: string, de: string, ate: string): Observable<BaseResponse<PresencaRelatorioDto>> {
    return this.http.get<BaseResponse<PresencaRelatorioDto>>(`${this.api}/relatorio`, {
      params: { turmaId, de, ate },
    });
  }

  gerarQrToken(alunoId: string): Observable<BaseResponse<QrTokenResponse>> {
    return this.http.get<BaseResponse<QrTokenResponse>>(`${this.api}/qr/${alunoId}`);
  }
}
