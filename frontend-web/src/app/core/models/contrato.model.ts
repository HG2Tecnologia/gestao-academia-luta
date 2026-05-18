export type StatusContrato = 1 | 2 | 3;

export interface ContratoDto {
  id: string;
  alunoId: string;
  nomeAluno: string;
  matriculaId?: string;
  modalidadeId?: string;
  nomeModalidade?: string;
  status: StatusContrato;
  statusLabel: string;
  dataAssinatura?: string;
  nomeAssinou?: string;
  criadoEm: string;
  tokenPublico: string;
}

export interface ContratoDetalheDto extends ContratoDto {
  conteudoHtml: string;
  ipAssinatura?: string;
}

export interface ContratoPublicoDto {
  id: string;
  nomeAluno: string;
  nomeAcademia: string;
  logoUrl?: string;
  conteudoHtml: string;
  status: StatusContrato;
  dataAssinatura?: string;
  nomeAssinou?: string;
}

export interface CreateContratoRequest {
  alunoId: string;
  matriculaId?: string;
  modalidadeId?: string;
  modeloContratoId?: string;
}

export interface AssinarContratoRequest {
  nomeCompleto: string;
}

export interface ModeloContratoDto {
  id: string;
  nome: string;
  conteudoHtml: string;
  criadoEm: string;
}

export interface CreateModeloContratoRequest {
  nome: string;
  conteudoHtml: string;
}

export interface UpdateModeloContratoRequest {
  nome: string;
  conteudoHtml: string;
}
