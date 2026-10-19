/**
 * Data local (não UTC) no formato `yyyy-MM-dd`. `Date.toISOString()`
 * converte pra UTC antes de formatar — em fusos negativos (Brasil,
 * UTC-3) isso erra o dia sempre que já passou da meia-noite UTC (a
 * partir das ~21h no horário de Brasília), fazendo "hoje" virar
 * "amanhã". O mobile grava `data` com o calendário local
 * (`DateTime.now()` do Dart, que é local por padrão) — esta função
 * mantém o CRM alinhado com isso.
 */
export function dataLocalISO(d: Date = new Date()): string {
  const ano = d.getFullYear();
  const mes = String(d.getMonth() + 1).padStart(2, '0');
  const dia = String(d.getDate()).padStart(2, '0');
  return `${ano}-${mes}-${dia}`;
}
