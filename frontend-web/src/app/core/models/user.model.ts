export interface UserPayload {
  sub: string;
  email: string;
  nome: string;
  academia_id: string;
  perfil: string;
  permissoes?: Record<string, boolean>;
  jti: string;
  exp: number;
  iat: number;
}
