import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ConquistaDto, LancamentoPontoDto, LeaderboardCustomDto, LeaderboardDto, PerfilGamificadoDto, RankingCustomDto } from '../models/ranking.model';

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

  // ─── Custom Rankings ─────────────────────────────────────────────────────

  listarRankingsCustom(incluirInativos = false): Observable<RankingCustomDto[]> {
    return this.http.get<RankingCustomDto[]>(`${this.base}/custom`, { params: { incluirInativos } });
  }

  criarRankingCustom(req: Partial<RankingCustomDto>): Observable<RankingCustomDto> {
    return this.http.post<RankingCustomDto>(`${this.base}/custom`, req);
  }

  atualizarRankingCustom(id: string, req: Partial<RankingCustomDto>): Observable<RankingCustomDto> {
    return this.http.put<RankingCustomDto>(`${this.base}/custom/${id}`, req);
  }

  desativarRankingCustom(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/custom/${id}`);
  }

  getLeaderboardCustom(id: string, pagina = 1): Observable<LeaderboardCustomDto> {
    return this.http.get<LeaderboardCustomDto>(`${this.base}/custom/${id}/leaderboard`, { params: { pagina } });
  }

  listarLancamentos(rankingId: string, alunoId?: string): Observable<LancamentoPontoDto[]> {
    const params: Record<string, string> = {};
    if (alunoId) params['alunoId'] = alunoId;
    return this.http.get<LancamentoPontoDto[]>(`${this.base}/custom/${rankingId}/lancamentos`, { params });
  }

  lancarPontos(rankingId: string, req: { alunoId: string; pontos: number; descricao?: string; data?: string }): Observable<LancamentoPontoDto> {
    return this.http.post<LancamentoPontoDto>(`${this.base}/custom/${rankingId}/pontuar`, req);
  }

  removerLancamento(lancamentoId: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/lancamentos/${lancamentoId}`);
  }
}
