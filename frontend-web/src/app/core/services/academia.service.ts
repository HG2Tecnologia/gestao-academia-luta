import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { BaseResponse } from '../models/auth.model';
import { AcademiaDto, UpdateAcademiaRequest } from '../models/academia.model';

@Injectable({ providedIn: 'root' })
export class AcademiaService {
  private readonly http = inject(HttpClient);
  private readonly api = `${environment.apiUrl}/api/academia`;

  getCurrent(): Observable<BaseResponse<AcademiaDto>> {
    return this.http.get<BaseResponse<AcademiaDto>>(this.api);
  }

  update(data: UpdateAcademiaRequest): Observable<BaseResponse<AcademiaDto>> {
    return this.http.put<BaseResponse<AcademiaDto>>(this.api, data);
  }

  updateTemplateContrato(template: string | null): Observable<BaseResponse<void>> {
    return this.http.put<BaseResponse<void>>(`${this.api}/template-contrato`, { template });
  }
}
