export interface TurmaDto {
  id: string;
  nome: string;
  modalidadeId: string;
  modalidadeNome: string;
  professorId: string;
  professorNome: string;
  nivel?: string;
  capacidadeMaxima: number;
  ativo: boolean;
}

export interface TurmaDetalheDto extends TurmaDto {
  totalAlunos: number;
  alunos: MatriculaDto[];
  horarios: HorarioResumoDto[];
}

export interface HorarioResumoDto {
  id: string;
  diaSemana: number;
  diaSemanaLabel: string;
  horaInicio: string;
  horaFim: string;
  sala?: string;
}

export interface MatriculaDto {
  id: string;
  alunoId: string;
  nomeAluno: string;
  emailAluno: string;
  turmaId: string;
  nomeTurma: string;
  dataInicio: string;
  dataFim?: string;
  ativo: boolean;
}

export interface CreateTurmaRequest {
  modalidadeId: string;
  professorId: string;
  nome: string;
  nivel?: string;
  capacidadeMaxima: number;
}

export interface UpdateTurmaRequest extends CreateTurmaRequest {
  ativo: boolean;
}

export interface MatricularRequest {
  alunoId: string;
}
