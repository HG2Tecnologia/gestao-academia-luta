# Fase 2 — implantação segura da identidade Firebase

Data: 2026-09-02

## Objetivo

Implantar a conta de autenticação versionada (`usuariosFirebase` schema v2) e
os vínculos explícitos entre uma credencial Firebase e vários perfis, sem
dependência da API C# e sem alterar arbitrariamente registros em produção.

O mobile continua usando exclusivamente Firebase Auth, Firestore e Cloud
Functions. O backend .NET/PostgreSQL não participa do login nem da resolução
de perfis do aplicativo.

## Ordem obrigatória de implantação

1. Fazer export/backup do Firestore e registrar a versão atualmente publicada
   do aplicativo.
2. Publicar os índices de collection group e aguardar todos ficarem prontos.
3. Publicar as três Cloud Functions de identidade.
   Se a organização aplicar compartilhamento restrito por domínio, o deploy
   criará os serviços mas não conseguirá adicionar `allUsers`. Nesse caso,
   desativar o Invoker IAM check somente nos três serviços de identidade com
   `gcloud run services update <servico> --no-invoker-iam-check`. A validação
   de usuário continua sendo feita pelas callables; `discoverAccessProfiles`
   é intencionalmente público para permitir o Primeiro Acesso.
4. Executar o backfill sem `--apply` e revisar o relatório de conflitos.
5. Resolver manualmente contatos ligados a UIDs diferentes. O script não faz
   merge de credenciais.
6. Executar o backfill com `--apply` apenas depois da revisão e do backup.
7. Publicar o novo aplicativo e acompanhar adoção, erros de Functions e login.
8. Publicar as regras endurecidas somente quando a janela de compatibilidade
   da versão antiga tiver terminado ou quando a atualização for obrigatória.

Não publicar as regras endurecidas antes das Functions e da migração: versões
antigas ainda fazem busca anônima e associação pelo cliente e deixariam de
concluir o Primeiro Acesso.

## Comandos de preparação

Executar a partir da raiz do repositório, no projeto Firebase explicitamente
selecionado e conferido:

```bash
firebase use
firebase deploy --only firestore:indexes
firebase deploy --only functions:discoverAccessProfiles,functions:activateAccessAccount,functions:refreshAccessAccount
```

Backfill em modo seguro (padrão):

```bash
cd scripts/migrate-firestore
npm run backfill:accounts
```

Depois de revisar `auth-account-v2-report.json` e somente com autorização:

```bash
npm run backfill:accounts:apply
```

As regras devem ser a última etapa:

```bash
firebase deploy --only firestore:rules
```

## Critérios de validação

- conta antiga continua entrando com e-mail ou telefone sintético legado;
- novo perfil com o mesmo contato aparece após reabrir/login, sem repetir o
  Primeiro Acesso;
- o perfil selecionado permanece selecionado após o refresh;
- uma conta vinculada a duas academias enxerga ambas;
- papel de Admin/Professor não é herdado em uma academia onde a conta possui
  somente perfil de Aluno;
- contato ligado a UIDs diferentes aparece no relatório e não é mesclado;
- nenhuma senha, presença, graduação, pagamento ou cadastro é apagado.

## Reversão

- Functions novas podem permanecer publicadas sem serem chamadas pelo app
  antigo.
- O schema v2 mantém os campos legados usados pelas versões publicadas.
- Em caso de falha no app, pausar o rollout da loja; não apagar os novos campos.
- Se as regras causarem incompatibilidade, restaurar temporariamente as regras
  anteriores e corrigir a janela de rollout. Restaurar dados apenas a partir do
  export validado, nunca por merge automático de contas.

## Estado atual

Em 2026-09-02, no projeto `sensei-manager-d64c0`:

- os 55 índices do Firestore estão prontos;
- as três Functions de identidade estão `ACTIVE` e usam exclusivamente a conta
  `identity-functions@sensei-manager-d64c0.iam.gserviceaccount.com`, com os
  papéis `Firebase Authentication Admin` e `Cloud Datastore User`;
- o Invoker IAM check foi desativado somente nesses três serviços, preservando
  a validação de autenticação dentro das callables;
- `discoverAccessProfiles` respondeu HTTP 200 para um contato inexistente, e
  as operações privadas responderam HTTP 401 sem credencial;
- o export anterior ao backfill terminou com sucesso em
  `gs://sensei-manager-d64c0-firestore-backups/phase2-pre-backfill-2026-09-02`;
- o backfill migrou 121 das 128 contas para o schema v2 e vinculou 133 perfis;
- quatro contas com conflito de UID e três contas sem perfil confirmável foram
  deliberadamente ignoradas e permanecem para revisão manual;
- a validação encontrou zero documentos v2 estruturalmente inválidos e nenhum
  erro nas revisões novas das Functions após a migração;
- as regras endurecidas continuam sem deploy e nenhuma versão do aplicativo foi
  publicada por este procedimento.

O runtime Node.js 20 das Functions deve ser atualizado antes da desativação
anunciada pelo Google para 2026-10-30. Essa atualização não foi misturada com o
rollout de identidade para evitar introduzir mudanças incompatíveis nesta etapa.
