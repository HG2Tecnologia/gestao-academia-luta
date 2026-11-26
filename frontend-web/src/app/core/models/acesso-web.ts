/**
 * Quem pode usar o sistema web. Sem imports, para ser testado direto no Node
 * (`npm run test:acesso`).
 *
 * O acesso é liberado por, nesta ordem:
 * 1. Black Belt pago (`acesso_web`, gravado só pelo servidor);
 * 2. liberação manual (`web_cortesia_ate` no futuro);
 * 3. teste de 30 dias (`criado_em`), mesmo que a academia já tenha comprado o
 *    PRO durante o teste.
 *
 * A trava só vale quando `config/geral.web_bloqueio_ativo` é `true`.
 */

export type SituacaoWeb = 'black-belt' | 'cortesia' | 'teste' | 'pro' | 'suspenso' | 'gratis';

export interface AcessoWeb {
  liberado: boolean;
  situacao: SituacaoWeb;
  bloqueioAtivo: boolean;
  diasDeTesteRestantes: number;
}

type Documento = Record<string, unknown>;

const DIA_MS = 24 * 60 * 60 * 1000;
const DIAS_DE_TESTE_PADRAO = 30;

/** Aceita `Timestamp` do Firestore, `Date` ou texto ISO. */
export function paraData(valor: unknown): Date | null {
  if (!valor) return null;
  if (valor instanceof Date) return valor;
  if (typeof valor === 'string') {
    const data = new Date(valor);
    return Number.isNaN(data.getTime()) ? null : data;
  }
  const comoTimestamp = valor as { toDate?: () => Date };
  return typeof comoTimestamp.toDate === 'function' ? comoTimestamp.toDate() : null;
}

/** Mesmo critério de `isPro` no app: em carência a data vencida não derruba. */
function planoPago(academia: Documento, agora: Date): boolean {
  if (!(Number(academia['plano_tipo'] ?? 0) >= 1)) return false;
  if (academia['plano_status'] === 'periodo_carencia') return true;
  const expiracao = paraData(academia['plano_expiracao']);
  return expiracao === null || expiracao > agora;
}

function diasDeTesteRestantes(academia: Documento, config: Documento, agora: Date): number {
  const criadoEm = paraData(academia['criado_em']);
  if (!criadoEm) return 0;
  const configurado = Number(config['trial_dias']);
  const total = configurado >= 1 ? Math.floor(configurado) : DIAS_DE_TESTE_PADRAO;
  const passados = Math.floor((agora.getTime() - criadoEm.getTime()) / DIA_MS);
  return Math.max(0, Math.min(total, total - passados));
}

export function avaliarAcessoWeb(
  academia: Documento,
  config: Documento = {},
  agora: Date = new Date(),
): AcessoWeb {
  const bloqueioAtivo = config['web_bloqueio_ativo'] === true;
  const diasRestantes = diasDeTesteRestantes(academia, config, agora);
  const pago = planoPago(academia, agora);
  const cortesiaAte = paraData(academia['web_cortesia_ate']);

  let situacao: SituacaoWeb;
  if (pago && academia['acesso_web'] === true) situacao = 'black-belt';
  else if (cortesiaAte && cortesiaAte > agora) situacao = 'cortesia';
  else if (diasRestantes > 0) situacao = 'teste';
  else if (pago) situacao = 'pro';
  else if (academia['plano_status'] === 'suspenso') situacao = 'suspenso';
  else situacao = 'gratis';

  const temDireito = situacao === 'black-belt' || situacao === 'cortesia' || situacao === 'teste';
  return {
    liberado: temDireito || !bloqueioAtivo,
    situacao,
    bloqueioAtivo,
    diasDeTesteRestantes: diasRestantes,
  };
}
