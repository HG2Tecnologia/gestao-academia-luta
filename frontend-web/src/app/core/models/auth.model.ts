export interface LoginRequest {
  email: string;
  senha: string;
}

export interface RegisterRequest {
  nome: string;
  email: string;
  senha: string;
  nomeAcademia: string;
  subdominio: string;
  emailAcademia?: string;
  telefone?: string;
}

export interface RefreshTokenRequest {
  accessToken: string;
  refreshToken: string;
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  expiracao: string;
  nome: string;
  email: string;
  perfil: string;
  academiaId: string;
}

export interface BaseResponse<T = void> {
  sucesso: boolean;
  mensagem?: string;
  dados?: T;
  erros: string[];
}
