import { BaseResponse } from './auth.model';

export interface AlunoListaDto {
  id: string;
  nome: string;
  email?: string;
  telefone?: string;
  matricula?: string;
  dataNascimento?: string;
  faixaAtualNome?: string;
  faixaAtualCor?: string;
  turmas: string[];
  planoNome?: string;
  ativo: boolean;
  criadoEm: string;
  situacaoFinanceira?: 'EmDia' | 'Pendente' | 'Inadimplente';
}

export interface AniversarianteDto {
  id: string;
  nome: string;
  diaNascimento: number;
  mesNascimento: number;
}

export interface AlunoDetalheDto extends AlunoListaDto {
  telefone: string;
  dataNascimento?: string;
  contatoEmergenciaNome?: string;
  contatoEmergenciaTelefone?: string;
  tipoPlano?: string;
  planoId?: string;
  planoNome?: string;
  diaVencimento?: number;
  xpTotal: number;
  nivel: string;
}

export interface CreateAlunoRequest {
  nome: string;
  email?: string;
  telefone: string;
  dataNascimento?: string;
  contatoEmergenciaNome?: string;
  contatoEmergenciaTelefone?: string;
  tipoPlano?: string;
  planoId?: string;
  diaVencimento?: number;
}

export interface UpdateAlunoRequest extends CreateAlunoRequest {
  ativo: boolean;
}

export interface PagedResult<T> {
  itens: T[];
  totalItens: number;
  pagina: number;
  tamanhoPagina: number;
  totalPaginas: number;
}
