/** Espelho dos tipos reais gravados em `academias/{id}/notificacoes` pelas Cloud Functions — ver `notificacao.service.ts`. */
export type TipoNotificacao =
  | 'solicitacao_senha'
  | 'cobranca_gerada'
  | 'graduacao'
  | 'atestado_pendente'
  | 'alerta'
  | 'info'
  | 'aniversario';

export interface NotificacaoDto {
  id: string;
  titulo: string;
  mensagem: string;
  tipo: TipoNotificacao;
  lida: boolean;
  criadoEm: string;
  usuarioId?: string;
}
