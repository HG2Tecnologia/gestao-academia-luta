export interface AcademiaDto {
  id: string;
  nome: string;
  subdominio: string;
  logoUrl?: string;
  email: string;
  telefone?: string;
  cnpj?: string;
  ativo: boolean;
  criadoEm: string;
  templateContrato?: string;
}

export interface UpdateAcademiaRequest {
  nome: string;
  email: string;
  telefone?: string;
  cnpj?: string;
}
