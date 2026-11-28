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
  /** Já tem conta de acesso vinculada. */
  temAcesso?: boolean;
  /** Presente até a pessoa entrar pela primeira vez. */
  senhaTemporaria?: string;
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
