export interface FuncionarioListaDto {
  id: string;
  usuarioId: string;
  nome: string;
  email: string;
  telefone?: string;
  cargo: string;
  perfil: string;
  turmasVinculadas: string[];
  ativo: boolean;
  dataAdmissao: string;
  permissoes: Record<string, boolean>;
}

export interface CreateFuncionarioRequest {
  nome: string;
  email?: string;
  telefone: string;
  cargo: string;
  perfil: string;
  permissoes?: Record<string, boolean>;
}

export interface UpdateFuncionarioRequest extends CreateFuncionarioRequest {
  ativo: boolean;
}
