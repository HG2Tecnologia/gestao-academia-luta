import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';
import {
  AtestadoMedicoDto,
  AtestadoMedicoComArquivoDto,
  AvaliarAtestadoRequest,
  UploadAtestadoPorAcademiaRequest,
} from '../models/atestado.model';

@Injectable({ providedIn: 'root' })
export class AtestadoService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/atestados`;

  obterDoAluno(alunoId: string): Observable<BaseResponse<AtestadoMedicoComArquivoDto>> {
    return this.http.get<BaseResponse<AtestadoMedicoComArquivoDto>>(`${this.api}/aluno/${alunoId}`);
  }

  avaliar(id: string, req: AvaliarAtestadoRequest): Observable<BaseResponse<void>> {
    return this.http.patch<BaseResponse<void>>(`${this.api}/${id}/avaliar`, req);
  }

  uploadPorAcademia(req: UploadAtestadoPorAcademiaRequest): Observable<BaseResponse<AtestadoMedicoDto>> {
    return this.http.post<BaseResponse<AtestadoMedicoDto>>(`${this.api}/academia`, req);
  }

  enviarLembrete(alunoId: string): Observable<BaseResponse<void>> {
    return this.http.post<BaseResponse<void>>(`${this.api}/aluno/${alunoId}/lembrete`, {});
  }
}
