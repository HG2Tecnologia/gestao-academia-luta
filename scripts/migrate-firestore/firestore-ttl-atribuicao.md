# TTL da subcoleção `_atribuicao` — preparado, NÃO aplicado

Este arquivo documenta a configuração de retenção aprovada para os
documentos de atribuição de origem (`academias/{id}/_atribuicao/dados`).
**Nada aqui foi executado** — é o passo de infraestrutura que falta,
pra rodar manualmente só depois de autorização explícita de deploy.

## O que já está pronto no código

A Cloud Function `registrarAtribuicaoCadastro`
(`functions/attribution-functions.js`) já grava, em todo documento novo,
o campo `expira_em` (Timestamp), calculado como
`agora (relógio do servidor) + 90 dias` no momento da escrita. Isso já
está coberto por teste (`functions/test/attribution-functions.test.js`).

Esse campo sozinho **não apaga nada** — ele só serve de gatilho pra uma
política de TTL do Firestore, que precisa ser configurada separadamente
(abaixo). Sem a política aplicada, o campo fica gravado e ignorado.

## Prazo escolhido: 90 dias

Aprovado para o início — mais curto que a sugestão original de 14 meses
(alinhada à retenção padrão do GA4). Pode ser ajustado depois sem migrar
dados existentes: alterar `RETENCAO_ATRIBUICAO_MS` na function só muda o
prazo pros documentos gravados A PARTIR da mudança — documentos antigos
mantêm o `expira_em` já calculado no momento em que foram escritos.

## Comando pra aplicar (quando autorizado)

```bash
gcloud firestore fields ttls update expira_em \
  --collection-group=_atribuicao \
  --project=sensei-manager-d64c0
```

Equivalente pelo Console: Firebase Console → Firestore Database → aba
"TTL" → "Criar política" → campo `expira_em`, grupo de coleção
`_atribuicao`.

A política é por **grupo de coleção** (`_atribuicao`), não por caminho
específico — isso significa que vale automaticamente para a subcoleção
`_atribuicao` de QUALQUER academia, atuais e futuras, sem precisar
reconfigurar por academia.

## Comportamento documentado (oficial do Firestore, não deste projeto)

- **Atraso na exclusão:** o Firestore não apaga no segundo exato em que
  `expira_em` vence. A documentação oficial do Google diz que a exclusão
  acontece "dentro de 24 horas" depois do vencimento — não é instantâneo,
  é um processo em segundo plano. Pra este caso de uso (dado de
  marketing, não algo que precise sumir num horário exato por lei), essa
  janela de até 24h é aceitável.
- **Documentos sem `expira_em`:** a política de TTL simplesmente ignora
  qualquer documento que não tenha o campo (ou que tenha um valor que não
  seja um `Timestamp` válido) — eles **nunca são apagados** por este
  mecanismo, ficam para sempre, sem erro nem aviso. Hoje isso não afeta
  nenhum documento real porque a function de atribuição ainda não está
  em produção — mas qualquer doc futuro gravado por uma versão mais
  antiga do código (sem o campo) ficaria permanentemente fora do alcance
  do TTL, a menos que alguém faça um backfill manual depois.
- **Custo:** a política de TTL em si não tem custo adicional pra
  habilitar. As exclusões que ela realiza são cobradas como operações de
  exclusão normais do Firestore (mesmo preço de um `delete()` comum) —
  dado o volume aqui (no máximo 1 documento de atribuição por academia
  criada), o custo é desprezível, não chega a aparecer na fatura de forma
  perceptível.
- **Reversibilidade:** desativar a política depois (`gcloud firestore
  fields ttls update expira_em --collection-group=_atribuicao --project=... --unset-ttl`, ou pelo Console) é imediato e não afeta documentos já
  apagados — só para de agendar exclusões futuras.

## Política de Privacidade

O texto em `frontend-web/src/app/features/legal/privacidade.component.ts`
(seção 2.3) já foi atualizado pra citar o prazo de 90 dias — publicado
junto com o resto do CRM, não antes.
