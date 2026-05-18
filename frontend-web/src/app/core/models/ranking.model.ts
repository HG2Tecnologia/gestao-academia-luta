export interface LeaderboardItemDto {
  posicao: number;
  alunoId: string;
  nomeAluno: string;
  avatarUrl?: string;
  nivel: string;
  xpPeriodo: number;
  xpTotal: number;
  totalConquistas: number;
  variacao: number;
}

export interface LeaderboardDto {
  periodo: string;
  totalParticipantes: number;
  pagina: number;
  tamanhoPagina: number;
  totalPaginas: number;
  items: LeaderboardItemDto[];
}

export interface ConquistaDto {
  id: string;
  tipo: string;
  nome: string;
  descricao: string;
  iconeUrl: string;
  pontosXpBonus: number;
  desbloqueada: boolean;
  desbloqueadaEm?: string;
}

export interface HistoricoXpItemDto {
  id: string;
  tipoEvento: string;
  pontos: number;
  data: string;
  criadoEm: string;
}

export interface PerfilGamificadoDto {
  alunoId: string;
  nome: string;
  nivel: string;
  xpTotal: number;
  xpMensal: number;
  xpParaProximoNivel: number;
  posicaoGlobal: number;
  posicaoTurma: number;
  sequenciaAtual: number;
  conquistasDesbloqueadas: ConquistaDto[];
  historicoXp: HistoricoXpItemDto[];
}

export const NIVEL_CONFIG: Record<string, { cor: string; label: string }> = {
  Iniciante: { cor: '#94a3b8', label: 'Iniciante' },
  Guerreiro: { cor: '#22c55e', label: 'Guerreiro' },
  Veterano:  { cor: '#3b82f6', label: 'Veterano' },
  Elite:     { cor: '#a855f7', label: 'Elite' },
  Mestre:    { cor: '#f59e0b', label: 'Mestre' },
};
