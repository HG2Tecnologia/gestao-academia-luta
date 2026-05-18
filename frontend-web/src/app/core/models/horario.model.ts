export interface HorarioDto {
  id: string;
  turmaId: string;
  nomeTurma: string;
  nomeModalidade: string;
  nomeProfessor: string;
  diaSemana: number;
  diaSemanaLabel: string;
  horaInicio: string;
  horaFim: string;
  sala?: string;
  totalAlunos: number;
  capacidadeMaxima: number;
}

export interface GradeHorariosDto {
  grade: Record<string, HorarioDto[]>;
}

export interface CreateHorarioRequest {
  turmaId: string;
  diaSemana: number;
  horaInicio: string;
  horaFim: string;
  sala?: string;
}
