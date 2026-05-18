export type TipoNotificacao = 'aniversario' | 'info' | 'alerta';

export interface NotificacaoDto {
  id: string;
  titulo: string;
  mensagem: string;
  tipo: number;
  tipoLabel: TipoNotificacao;
  lida: boolean;
  criadoEm: string;
  tempoRelativo: string;
}
