export interface AtestadoMedicoDto {
  id: string;
  alunoId: string;
  alunoNome: string;
  status: number; // 0=Pendente, 1=Aprovado, 2=Rejeitado, 3=Expirado
  motivoRejeicao?: string;
  dataUpload: string;
  dataValidade: string;
  anexadoPorAcademia: boolean;
  arquivoMimeType: string;
  arquivoNome?: string;
  criadoEm: string;
  vencendoEmBreve: boolean;
}

export interface AtestadoMedicoComArquivoDto extends AtestadoMedicoDto {
  arquivoBase64: string;
}

export interface UploadAtestadoPorAcademiaRequest {
  alunoId: string;
  arquivoBase64: string;
  arquivoMimeType: string;
  arquivoNome?: string;
  dataValidade?: string;
}

export interface AvaliarAtestadoRequest {
  aprovado: boolean;
  motivoRejeicao?: string;
}
