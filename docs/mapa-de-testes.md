# Mapa de testes — Fases 1 a 8

Data: 2026-09-02

Este documento existe para ser executado de uma vez, no fim de todas as
fases, em vez de a cada fase individualmente. Ele lista **o que já está
automatizado** (arquivo, comando, o que cobre) e **o que só existe como
roteiro manual/plano de teste** vindo do `docs/account-finance-fixes-plan.md`
(seção 9), organizados por área. Rodar tudo antes de seguir o deploy descrito
em `docs/account-identity-phase2-rollout.md` (Fase 2) e
`docs/account-finance-fixes-phase8-rollout.md` (Fases 3–7).

## Como rodar tudo

```bash
# Domínio puro (Dart) — regras de negócio isoladas de UI/rede
cd mobile && flutter test

# Domínio puro (JS) + análise estática
cd functions && npm test

# Cada suíte de emulador roda sozinha (limitação conhecida: rodar duas juntas
# no mesmo `emulators:exec` às vezes falha por versão de Java do jar do
# emulador — não é bug de código, é ambiente).
cd functions
npm run test:rules
npm run test:identity
npm run test:admin
npm run test:graduacao
npm run test:turma
npm run test:finance

cd ../mobile && flutter analyze
```

Depois de cada rodada de emulador, apagar `functions/firestore-debug.log`
(artefato de debug, não deve ser commitado).

## 1. Autenticação e identidade (Fase 1 e 2)

### Automatizado

| Arquivo | Comando | Cobre |
|---|---|---|
| `functions/test/domain.test.js` | `npm test` | normalizador de telefone puro (JS) |
| `mobile/test/phone_normalizer_test.dart` | `flutter test` | normalizador de telefone puro (Dart), vetores espelhados do JS |
| `functions/test/account-functions.test.js` | `npm run test:identity` | `discoverAccessProfiles`, `activateAccessAccount`, `refreshAccessAccount` contra o emulador real |
| `functions/test/firestore.rules.test.js` | `npm run test:rules` | leitura anônima restrita, cross-tenant, escalada de privilégio nas rules v2 |

### Roteiro manual pendente (plano §9 "Autenticação")

- [ ] um telefone, uma conta, um perfil — fluxo completo de Primeiro Acesso
- [ ] duas irmãs, mesmo telefone, uma conta e dois perfis — massa sintética
      no emulador (criar os dois perfis com telefone idêntico, formatos
      diferentes, confirmar que ambas resolvem para o mesmo `usuariosFirebase`
      e aparecem como dois `profile_refs`)
- [ ] formatos `219...`, `(21)...`, `+55...` e `55...` convergem para o mesmo
      canônico
- [ ] contato compartilhado com dois UIDs gera conflito no relatório
      (`scripts/migrate-firestore/backfill-auth-accounts-v2.js` sem `--apply`)
      e não é mesclado automaticamente
- [ ] novo perfil aparece sem refazer Primeiro Acesso (ativar um segundo
      perfil no mesmo contato e confirmar que reaparece após reabrir o app)
- [ ] conta temporária exige troca e revoga senha/sessões anteriores
      (coberto em parte por `troca_senha_obrigatoria_screen_test.dart` no
      nível de widget; falta o roteiro ponta a ponta com revogação real de
      refresh token em produção/staging)
- [ ] aluno não consegue se promover a Admin nem vincular perfil de outra
      academia (tentar via chamada direta da function com payload adulterado)

## 2. Redefinição de senha administrativa (Fase 4)

### Automatizado

| Arquivo | Comando | Cobre |
|---|---|---|
| `functions/test/temp-password.test.js` | `npm test` | geração de senha temporária, RNG injetável, exclusão de caracteres ambíguos |
| `functions/test/admin-functions.test.js` | `npm run test:admin` | `adminResetPassword` (Admin ok, Secretaria sem permissão bloqueada, `must_change_password` setado, auditoria sem segredo), `completeMandatoryPasswordChange` |
| `mobile/test/troca_senha_obrigatoria_screen_test.dart` | `flutter test` | `PopScope(canPop:false)`, validação de formulário, navegação por perfil após conclusão |

### Roteiro manual pendente

- [ ] Secretaria com `acesso_redefinir_senha:true` consegue redefinir; sem a
      permissão, botão nem aparece/chamada é bloqueada — conferir os dois
      casos direto no app, não só via emulador
- [ ] copiar/compartilhar a senha temporária (testar os dois botões do
      `senha_temporaria_modal.dart` num dispositivo real)
- [ ] sessão antiga é derrubada de fato (logar em dois dispositivos, resetar
      a senha, confirmar que o dispositivo antigo perde a sessão)

## 3. Edição de aluno e graduação (Fase 5)

### Automatizado

| Arquivo | Comando | Cobre |
|---|---|---|
| `mobile/test/graduacao_order_test.dart` | `flutter test` | comparação cronológica, comparação de progressão, `montarFaixasAtuaisPorAluno` |
| `functions/test/graduacao.test.js` | `npm test` | mesma lógica espelhada em JS, `detectarConflitoDeOrdem` |
| `functions/test/graduacao-functions.test.js` | `npm run test:graduacao` | `editarGraduacao` no emulador: edição válida com auditoria before/after, bloqueio de troca de modalidade, detecção de conflito de ordem pós-transação |

### Roteiro manual pendente (plano §9 "Graduação")

- [ ] editar azul 2 para azul 1 — correção descendente sem erro
- [ ] corrigir roxa para azul — troca de faixa dentro da mesma modalidade
- [ ] preservar regra ascendente apenas na *nova* graduação (nova entrada
      continua exigindo progressão; edição de uma já existente não)
- [ ] recalcular faixa atual por modalidade depois da edição, refletido na
      tela do aluno
- [ ] duas graduações no mesmo dia usam timestamp/ordem estável (sem flicker
      entre qual é "a atual")
- [ ] validação de e-mail/telefone ao editar aluno não altera vínculo de
      autenticação silenciosamente (editar contato de um aluno já vinculado e
      confirmar que o login antigo continua funcionando)

## 4. Exclusão segura de turma (Fase 6)

### Automatizado

| Arquivo | Comando | Cobre |
|---|---|---|
| `functions/test/turma-functions.test.js` | `npm run test:turma` | `arquivarTurma` no emulador: Professor bloqueado, matrículas ativas encerradas na mesma transação, `deleted_at`/`deleted_by` gravados, dupla exclusão bloqueada (`failed-precondition`) |
| `mobile/test/turma_service_test.dart` | `flutter test` | `TurmaService.estaExcluida` |

### Roteiro manual pendente (plano §9 "Turmas")

- [ ] excluir turma com três matrículas reais no app (não só no emulador) e
      conferir a UI ponta a ponta
- [ ] turma some das listas ativas (turmas, prof_turmas, prof_presenca,
      prof_graduacao, vincular turma no aluno) mas **continua resolvendo
      nome** em financeiro, relatório de presenças, presenças do aluno,
      horários do aluno e dashboard — checar as 5 telas excluídas
      deliberadamente do filtro
- [ ] presenças e relatórios históricos continuam íntegros após a exclusão
- [ ] falha parcial faz rollback (difícil de simular manualmente; se possível
      forçar erro no meio da transação em ambiente de teste)

## 5. Financeiro automático e competência (Fase 7)

### Automatizado

| Arquivo | Comando | Cobre |
|---|---|---|
| `mobile/test/billing_period_test.dart` | `flutter test` | `BillingPeriod`, `addBillingMonths`, `dueDateForPeriod`, `resolveChargeStatus` |
| `functions/test/finance-functions.test.js` | `npm run test:finance` | `ensureChargesForPeriod` no emulador: gera só para ativo+com plano respeitando dia de vencimento, idempotência (segunda chamada não duplica nem reseta cobrança paga) |

### Roteiro manual pendente (plano §9 "Financeiro")

- [ ] virada de competência gera o mês atual automaticamente (sem abrir o
      app manualmente — depende do scheduler `gerarMensalidadesAutomaticas`
      rodando às 06h; validar em staging observando o log do cron)
- [ ] execução repetida e **concorrente** não duplica (duas abas/dispositivos
      abrindo Financeiro ao mesmo tempo — o `get`+`create` transacional já
      cobre isso em teoria; vale um teste de carga leve)
- [ ] pendente/atrasado/pago calculados corretamente na UI, não só na função
- [ ] próximo mês existe e aceita pagamento antecipado — navegar para o mês
      seguinte no app e dar baixa antes do vencimento
- [ ] `data_pagamento` registra a data real, mesmo com baixa antecipada
- [ ] aluno sem plano/inativo/inelegível não recebe cobrança — já coberto no
      emulador; confirmar visualmente que ele não aparece na lista do mês
- [ ] cobrança antiga (gerada pelo fluxo manual anterior, ID aleatório) nunca
      é tocada pelo novo fluxo — abrir Financeiro num mês com cobranças
      antigas reais e confirmar que nada muda nelas

## 6. Regressão geral (Fase 8)

Nenhum destes tem automação dedicada — são passes manuais de fumaça cobrindo
o sistema inteiro depois de tudo publicado, antes de liberar para todos os
usuários:

- [ ] login e refresh no web (Angular/.NET) — fora do escopo desta rodada de
      fases, mas confirmar que nada no Firestore mudou de um jeito que quebre
      a leitura pelo backend .NET, se ainda houver dependência cruzada
- [ ] login Firebase no mobile com cada perfil: Admin, Secretaria, Professor,
      Aluno
- [ ] dashboard, alunos, turmas, presença, graduação e financeiro abrindo sem
      erro para cada perfil acima
- [ ] troca de perfil/academia sem logout
- [ ] logout e restauração de sessão (`/boas-vindas` aparecendo certo,
      sessão antiga não vazando perfil de outra conta)
- [ ] `flutter analyze` limpo e `npm test`/suítes de emulador todas verdes
      juntas pela última vez, imediatamente antes do deploy

## 7. Massa sintética "duas irmãs" (Fase 8, gate antes do backfill de produção)

Roteiro específico pedido no plano (§8 Fase 8 e §11 "critérios de gate"):
montar no emulador dois perfis de aluno com o mesmo telefone em formatos
diferentes (`21999999999`, `(21) 99999-9999`, `+5521999999999`) e sem e-mail,
e validar:

- [ ] as duas resolvem para o mesmo `telefone_digits` canônico
- [ ] `discoverAccessProfiles` retorna as duas como candidatas do mesmo
      contato
- [ ] ativação da primeira não impede a ativação/vínculo da segunda como
      perfil adicional da mesma conta (não cria uma segunda conta Firebase)
- [ ] o relatório do backfill (`auth-account-v2-report.json`, gerado por
      `scripts/migrate-firestore/backfill-auth-accounts-v2.js` sem
      `--apply`) lista corretamente o caso como resolvido (uma conta, dois
      perfis) e não como conflito
- [ ] um terceiro perfil com o mesmo telefone mas pertencente a um UID já
      existente e *diferente* (simulando dado legado inconsistente) aparece
      no relatório como conflito e não é mesclado automaticamente

Este é o mesmo gate já citado como pré-requisito de produção na Fase 2; useo
como confirmação final antes de rodar o backfill com `--apply` em produção
outra vez, caso haja nova leva de contas pendentes de revisão manual.

## Status

Nenhum item de "roteiro manual pendente" foi executado ainda — por decisão
do usuário, a execução de testes fica para depois que todas as fases de
implementação estiverem prontas. Este documento é o ponto de partida para
essa rodada final.
