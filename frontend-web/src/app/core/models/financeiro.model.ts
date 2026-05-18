export interface PagamentoDto {
  id: string;
  alunoId: string;
  nomeAluno: string;
  telefoneAluno?: string;
  tipo: string;
  status: string;
  valor: number;
  descricao?: string;
  dataVencimento?: string;
  dataPagamento?: string;
  formaPagamento?: string;
  observacoes?: string;
  criadoEm: string;
}

export interface CreatePagamentoRequest {
  alunoId: string;
  tipo: number;
  status: number;
  valor: number;
  descricao?: string;
  dataVencimento?: string;
  dataPagamento?: string;
  formaPagamento?: string;
  observacoes?: string;
}

export interface UpdatePagamentoRequest {
  status: number;
  dataPagamento?: string;
  formaPagamento?: string;
  observacoes?: string;
}

export interface ResumoFinanceiroDto {
  totalRecebidoMes: number;
  totalPendenteMes: number;
  totalAtrasado: number;
  totalAlunos: number;
  alunosInadimplentes: number;
  alunosEmDia: number;
  pagamentosRecentes: PagamentoDto[];
  inadimplentes: AlunoInadimplenteDto[];
}

export interface AlunoInadimplenteDto {
  alunoId: string;
  nomeAluno: string;
  totalDevido: number;
  diasAtraso: number;
  ultimoVencimento?: string;
}

export const TipoPagamento: Record<number, string> = {
  1: 'Mensalidade',
  2: 'Taxa de Matrícula',
  3: 'Diária',
  4: 'Produto',
  5: 'Graduação',
  6: 'Outros',
};

export const StatusPagamento: Record<number, string> = {
  1: 'Pago',
  2: 'Pendente',
  3: 'Atrasado',
  4: 'Cancelado',
};

export interface ReceitaMensalDto {
  ano: number;
  mes: number;
  recebido: number;
  pendente: number;
  atrasado: number;
}

export interface FrequenciaMensalDto {
  ano: number;
  mes: number;
  totalPresencas: number;
  alunosUnicos: number;
}

export interface RelatorioAnualDto {
  ano: number;
  totalRecebidoAno: number;
  totalAlunosAtivos: number;
  totalInadimplentes: number;
  receitaMensal: ReceitaMensalDto[];
  frequenciaMensal: FrequenciaMensalDto[];
  inadimplentes: AlunoInadimplenteDto[];
}
