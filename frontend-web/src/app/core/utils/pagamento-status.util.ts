/**
 * Espelho exato de `mobile/lib/core/pagamento_status.dart` — mesmos 5
 * status, mesma regra de "vencido vira Atrasado". Qualquer mudança aqui
 * precisa da mesma mudança lá (e vice-versa).
 *
 * | int | status         |
 * |-----|----------------|
 * | 0   | Pendente       |
 * | 1   | Pago           |
 * | 2   | Atrasado *(nunca gravado — sempre derivado de um Pendente vencido)* |
 * | 3   | Previsto       |
 * | 4   | Desconsiderado |
 */
export type PagamentoStatus = 'Pendente' | 'Pago' | 'Atrasado' | 'Previsto' | 'Desconsiderado';

function statusBase(rawStatus: unknown): PagamentoStatus {
  const i = typeof rawStatus === 'number' ? rawStatus : Number(rawStatus ?? 0);
  switch (i) {
    case 1:
      return 'Pago';
    case 3:
      return 'Previsto';
    case 4:
      return 'Desconsiderado';
    default:
      return 'Pendente';
  }
}

/** Status efetivo pra exibição: Pendente/Previsto vencido vira Atrasado. Pago/Desconsiderado nunca mudam. */
export function statusEfetivo(rawStatus: unknown, dataVencimento: unknown): PagamentoStatus {
  const base = statusBase(rawStatus);
  if (base === 'Pago' || base === 'Desconsiderado') return base;
  if (!dataVencimento) return base;
  const venc = new Date(String(dataVencimento));
  if (isNaN(venc.getTime())) return base;
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);
  return venc < hoje ? 'Atrasado' : base;
}

/** Só `Pago` conta como receita recebida pela academia. */
export function contaComoReceita(status: PagamentoStatus): boolean {
  return status === 'Pago';
}

/** `Pendente` ou `Atrasado` são pendência em aberto do aluno; `Previsto`/`Desconsiderado` não. */
export function ehPendenciaAberta(status: PagamentoStatus): boolean {
  return status === 'Pendente' || status === 'Atrasado';
}
