import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';
import { HorarioDto, GradeHorariosDto, CreateHorarioRequest } from '../models/horario.model';

@Injectable({ providedIn: 'root' })
export class HorarioService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/horarios`;

  getGrade(): Observable<BaseResponse<GradeHorariosDto>> {
    return this.http.get<BaseResponse<GradeHorariosDto>>(`${this.api}/grade`);
  }

  getByTurma(turmaId: string): Observable<BaseResponse<HorarioDto[]>> {
    return this.http.get<BaseResponse<HorarioDto[]>>(this.api, { params: { turmaId } });
  }

  create(data: CreateHorarioRequest): Observable<BaseResponse<HorarioDto>> {
    return this.http.post<BaseResponse<HorarioDto>>(this.api, data);
  }

  update(id: string, data: CreateHorarioRequest): Observable<BaseResponse<HorarioDto>> {
    return this.http.put<BaseResponse<HorarioDto>>(`${this.api}/${id}`, data);
  }

  delete(id: string): Observable<BaseResponse<void>> {
    return this.http.delete<BaseResponse<void>>(`${this.api}/${id}`);
  }
}
