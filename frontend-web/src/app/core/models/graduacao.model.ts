export interface GraduacaoDto {
  id: string;
  alunoId: string;
  nomeAluno: string;
  faixaId: string;
  nomeFaixa: string;
  corFaixa: string;
  modalidadeId: string;
  nomeModalidade: string;
  dataExame: string;
  aprovado: boolean;
  professorId: string;
  nomeProfessor: string;
  observacoes?: string;
  certificadoUrl?: string;
}

export interface FaixaDto {
  id: string;
  modalidadeId: string;
  nomeModalidade: string;
  nome: string;
  cor: string;
  ordem: number;
  requisitosMesesMinimos: number;
  requisitosPresencasMinimas: number;
  descricao?: string;
}

export interface CreateFaixaRequest {
  modalidadeId: string;
  nome: string;
  cor: string;
  ordem: number;
  requisitosMesesMinimos: number;
  requisitosPresencasMinimas: number;
  descricao?: string;
}

export interface RegistrarGraduacaoRequest {
  alunoId: string;
  faixaId: string;
  dataExame: string;
  professorId: string;
  aprovado: boolean;
  observacoes?: string;
}

export interface AlunoAptoDto {
  alunoId: string;
  nomeAluno: string;
  emailAluno: string;
  mesesMatriculado: number;
  totalPresencas: number;
  mesesNecessarios: number;
  presencasNecessarias: number;
}
