# Fase 8 — integração, regressão e rollout (Fases 3 a 7)

Data: 2026-09-02

## Objetivo

Consolidar em um único runbook o deploy, a observabilidade e a reversão de
tudo que foi construído nas Fases 3 a 7: nova entrada do app, redefinição
administrativa de senha, edição auditada de graduação, exclusão segura de
turma e financeiro automático por competência. A Fase 2 (identidade/múltiplos
perfis) já tem rollout próprio em `docs/account-identity-phase2-rollout.md` e
**deve estar concluída e estável em produção antes** de iniciar esta fase —
as Functions abaixo dependem de `usuariosFirebase` schema v2/`profile_refs`
para autorizar o chamador.

Este documento não substitui os testes automatizados; ele organiza a ordem
segura de publicação. A execução dos testes (automatizados e manuais) fica
registrada à parte em `docs/mapa-de-testes.md`, a ser rodada antes do deploy
em produção.

## O que esta fase entrega

| Fase | Cloud Functions novas | Rules novas/alteradas | App novo |
|---|---|---|---|
| 3 | — | — | `EntradaScreen`, login contextualizado, rotas `/boas-vindas` |
| 4 | `adminResetPassword`, `completeMandatoryPasswordChange` | `academias/{id}/auditoria` (read Admin/Secretaria, write false) | `TrocaSenhaObrigatoriaScreen`, botão "Redefinir senha" |
| 5 | `editarGraduacao` | (reusa `auditoria`) | Editar graduação em `aluno_detalhe_screen.dart` |
| 6 | `arquivarTurma` | `academias/{id}/turmas` (create/update Admin/Secretaria, delete false) | Botão "Excluir turma", filtros `deleted_at == null` |
| 7 | `ensureChargesForPeriod`, `gerarMensalidadesAutomaticas` (scheduler) | — | Fallback automático + wizard reescrito em `financeiro_screen.dart` |

Nenhuma dessas Functions ou regras foi publicada até o momento. Nenhum commit
foi feito — todas as alterações seguem apenas no working tree local.

## Pré-requisitos antes de qualquer deploy

1. Fase 2 publicada e estável (ver estado atual registrado em
   `docs/account-identity-phase2-rollout.md`) — sem isso, `loadCallerAuthority`
   / `loadFinanceAuthority` / `loadDeleterAuthority` / `loadEditorAuthority`
   não conseguem resolver o perfil de quem chama.
2. Export/backup do Firestore recente (mesmo procedimento da Fase 2).
3. `docs/mapa-de-testes.md` executado e verde: `npm test`, `npm run test:*`
   (emuladores) e `flutter test`.
4. `flutter analyze` sem erros.
5. Nenhuma credencial ou dado pessoal em fixtures/logs dos testes.

## Ordem obrigatória de implantação

A ordem segue a mesma lógica da Fase 2: **funções antes de regras, regras
antes de app novo**, para que uma versão antiga do app nunca encontre uma
regra que a bloqueie antes de existir a Function que a substitui.

Rodar sempre a partir da **raiz do repositório** (onde está `firebase.json`)
— não de dentro de `mobile/` nem `functions/`, senão o CLI não encontra os
targets:

```bash
cd /Users/gabrielfornydesouzamuniz/Documents/projetos/gestao-academia-luta
firebase use
```

### 1. Publicar as seis Cloud Functions novas juntas

```bash
firebase deploy --only functions:adminResetPassword,functions:completeMandatoryPasswordChange,functions:editarGraduacao,functions:arquivarTurma,functions:ensureChargesForPeriod,functions:gerarMensalidadesAutomaticas
```

Todas usam `IDENTITY_FUNCTION_OPTIONS` (mesma service account
`identity-functions@sensei-manager-d64c0.iam.gserviceaccount.com`). Se a
política de invoker público bloquear o deploy do jeito que aconteceu na Fase
2, repetir por serviço:

```bash
gcloud run services update <servico> --no-invoker-iam-check
```

Diferente de `discoverAccessProfiles`, nenhuma dessas seis é pública — todas
exigem `request.auth`. O passo acima é só para permitir o Cloud Run aceitar a
chamada; a autorização de negócio continua sendo validada dentro de cada
function.

`gerarMensalidadesAutomaticas` é `onSchedule` (cron `0 6 * * *`,
`America/Sao_Paulo`) — o deploy já cria o job agendado no Cloud Scheduler.
Confirmar no console que o job aparece como `ENABLED` antes de seguir.

### 2. Publicar as regras atualizadas

```bash
firebase deploy --only firestore:rules
```

As duas mudanças de regra desta fase (`auditoria` e `turmas`) só **restringem**
escrita direta do cliente em coisas que, antes, ninguém escrevia por essa via
oficialmente (auditoria não existia; exclusão de turma usava um método morto
já removido em `firestore_service.dart`). Não há janela de incompatibilidade
com o app antigo a esperar aqui — diferente da Fase 2, pode ir logo após as
functions.

### 3. Rodar o smoke test manual em produção com um usuário de teste

Antes de liberar a versão nova do app para todo mundo:

- `adminResetPassword`: redefinir senha de um funcionário de teste, confirmar
  que o app força `/troca-senha-obrigatoria` e que a senha antiga para de
  funcionar (revogação de refresh token).
- `editarGraduacao`: editar uma graduação de teste, confirmar `auditoria`
  gravada e que a faixa atual recalculada aparece certa no app.
- `arquivarTurma`: arquivar uma turma de teste com matrícula ativa, confirmar
  que a matrícula vira `ativo:false` e a turma some das listagens
  operacionais mas continua resolvendo nome em relatórios históricos.
- `ensureChargesForPeriod`: abrir Financeiro no mês atual com um aluno de
  teste ativo/com plano, confirmar que a cobrança é criada uma vez só mesmo
  reabrindo a tela várias vezes.

### 4. Publicar o app novo (Fase 3 a 7 juntas)

Só depois do smoke test do passo 3 passar. Publicar como versão única — as
mudanças de Fase 3 a 7 são pequenas o bastante e interdependentes o bastante
(ex.: navegação `/boas-vindas`, `must_change_password`) para não valer a pena
fatiar em releases de loja separados.

**Notas de loja e texto do modal de atualização só devem ser escritos e
publicados depois da aprovação funcional** — isto é, depois do smoke test do
passo 3. Este runbook não inclui esse texto; ele é o último passo, feito à
parte, quando o restante já estiver validado.

### 5. Acompanhar adoção e observabilidade

- **Cloud Functions Logs** (Firebase Console → Functions → cada função):
  monitorar taxa de erro das seis functions novas nas primeiras 48h.
  `ensureChargesForPeriod` e `gerarMensalidadesAutomaticas` merecem atenção
  extra no primeiro dia 06:00 (horário do cron) — conferir que
  `criadas`/`ignoradas` batem com o número de alunos ativos com plano.
- **Auditoria** (`academias/{id}/auditoria`): conferir volume e amostrar
  alguns documentos de `adminResetPassword`, `editarGraduacao` e
  `arquivarTurma` para confirmar `before/after`/`operador`/timestamp
  presentes e sem segredo (nunca a senha temporária).
- **Erros no app**: acompanhar o console de crash/erro do Firebase
  (Crashlytics, se configurado) por telas novas (`EntradaScreen`,
  `TrocaSenhaObrigatoriaScreen`, edição de graduação, financeiro).
- **Cloud Scheduler**: confirmar execução diária bem-sucedida de
  `gerarMensalidadesAutomaticas` (histórico de execuções no console).

## Reversão

Mesma filosofia da Fase 2: nunca apagar dado, sempre voltar o app/rules e
deixar as functions novas publicadas e paradas (sem uso) se necessário.

- **App com bug em campo**: pausar o rollout da loja (não removê-lo); a
  versão anterior do app não chama nenhuma das seis functions novas nem
  depende das regras de `auditoria`/`turmas`, então continua funcionando
  normalmente enquanto a correção é feita.
- **Function com bug**:
  - `adminResetPassword`/`completeMandatoryPasswordChange`: desativar o botão
    "Redefinir senha" no app (feature flag ou nova versão) evita novos
    acionamentos; usuários já com `must_change_password:true` seguem
    conseguindo trocar a senha normalmente, pois `completeMandatoryPasswordChange`
    é independente do reset em si.
  - `editarGraduacao`: reverter para a versão anterior do app remove o botão
    de editar; nenhuma graduação é perdida, o pior caso é uma edição
    incorreta já auditada, corrigível com uma nova edição (o histórico
    `before/after` preserva o registro original).
  - `arquivarTurma`: se o arquivamento por engano ocorrer, não há "desfazer"
    automático — reverter manualmente via Admin SDK/console: voltar
    `ativo:true` na turma, remover `deleted_at`/`deleted_by`, e reativar as
    matrículas que tinham `encerrado_motivo:'turma_excluida'` (a auditoria
    grava a lista de matrículas encerradas para essa reversão pontual).
  - `ensureChargesForPeriod`/`gerarMensalidadesAutomaticas`: pausar o
    scheduler no Cloud Scheduler console interrompe a geração automática
    imediatamente; a criação é sempre idempotente e por `create()`, então uma
    cobrança gerada errada só existe se os dados de origem (`plano`,
    `dia_vencimento`) estavam errados — corrigir o cadastro e apagar
    manualmente o documento `mensalidade__{alunoId}__{period}` afetado (nunca
    sobrescrever um documento já marcado como pago sem confirmação humana).
- **Regras com problema**: restaurar a versão anterior de
  `scripts/migrate-firestore/firestore.rules` e publicar de novo com
  `firebase deploy --only firestore:rules` — reversível a qualquer momento,
  sem impacto em dado.

## Estado atual

Em 2026-09-02: nenhuma function, regra ou versão de app desta fase foi
publicada. Nenhum commit foi feito. Este runbook fica pronto para uso assim
que o `docs/mapa-de-testes.md` for executado e a Fase 2 estiver confirmada
estável em produção.
