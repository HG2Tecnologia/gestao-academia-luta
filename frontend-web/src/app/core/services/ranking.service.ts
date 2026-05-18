import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ConquistaDto, LeaderboardDto, PerfilGamificadoDto } from '../models/ranking.model';

@Injectable({ providedIn: 'root' })
export class RankingService {
  private readonly base = `${environment.apiUrl}/api/ranking`;

  constructor(private http: HttpClient) {}

  getLeaderboardAcademia(periodo: 'mensal' | 'historico', pagina = 1): Observable<LeaderboardDto> {
    return this.http.get<LeaderboardDto>(`${this.base}/leaderboard/academia`, {
      params: { periodo, pagina: pagina.toString() }
    });
  }

  getLeaderboardTurma(turmaId: string, periodo: 'mensal' | 'historico', pagina = 1): Observable<LeaderboardDto> {
    return this.http.get<LeaderboardDto>(`${this.base}/leaderboard/turma/${turmaId}`, {
      params: { periodo, pagina: pagina.toString() }
    });
  }

  getPerfilGamificado(alunoId: string): Observable<PerfilGamificadoDto> {
    return this.http.get<PerfilGamificadoDto>(`${this.base}/perfil/${alunoId}`);
  }

  getConquistas(alunoId: string): Observable<ConquistaDto[]> {
    return this.http.get<ConquistaDto[]>(`${this.base}/conquistas/${alunoId}`);
  }

  marcarConquistasVistas(alunoId: string): Observable<void> {
    return this.http.post<void>(`${this.base}/conquistas/marcar-vistas`, { alunoId });
  }
}
