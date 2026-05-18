export interface PlanoDto {
  id: string;
  nome: string;
  descricao?: string;
  valorMensal: number;
  taxaMatricula?: number;
  ativo: boolean;
  totalAlunos: number;
}

export interface CreatePlanoRequest {
  nome: string;
  descricao?: string;
  valorMensal: number;
  taxaMatricula?: number;
}

export interface UpdatePlanoRequest extends CreatePlanoRequest {
  ativo: boolean;
}
