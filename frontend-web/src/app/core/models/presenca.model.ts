export interface PresencaDto {
  id: string;
  alunoId: string;
  nomeAluno: string;
  horarioId: string;
  nomeTurma: string;
  data: string;
  horaCheckin: string;
  metodoCheckin: string;
  confirmado: boolean;
  observacoesProfessor?: string;
}

export interface RegistrarPresencaRequest {
  alunoId: string;
  horarioId: string;
  data?: string;
  observacoesProfessor?: string;
  metodoCheckin: number;
}

export interface PresencaRelatorioDto {
  totalAulas: number;
  mediaFrequencia: number;
  alunos: AlunoFrequenciaDto[];
}

export interface AlunoFrequenciaDto {
  alunoId: string;
  nomeAluno: string;
  presencas: number;
  faltas: number;
  percentual: number;
}

export interface QrTokenResponse {
  token: string;
  expiresAt: string;
}
