# Auditoria e plano estrutural — contas, acesso e financeiro

Data da auditoria: 2026-09-02

## 1. Resumo executivo

O Sensei Manager possui hoje duas arquiteturas de dados e autenticação ativas:

- o aplicativo Flutter usa Firebase Auth e acessa o Firestore diretamente;
- o frontend Angular usa a API ASP.NET Core, JWT e PostgreSQL.

O arquivo `MOBILE_CONTEXT.md` descreve uma intenção antiga de o mobile usar a API, mas o código atual de `mobile/lib/core/firestore_service.dart` declara explicitamente que todas as chamadas REST foram substituídas por acesso direto ao Firestore. O `ApiClient` ainda existe, porém não participa dos fluxos principais do mobile.

Essa separação é determinante: uma correção feita somente em `AuthService`, `FinanceiroService` ou nas migrations do PostgreSQL não corrige o app em produção. As correções do app precisam ter uma fronteira server-side no Firebase (Cloud Functions/Admin SDK), regras Firestore revisadas e compatibilidade com os documentos existentes.

O modelo do mobile já possui o embrião correto de `Account -> vários Profiles`: `usuariosFirebase/{firebaseUid}` funciona como lookup da identidade e pode conter vários perfis. Porém a ativação, busca e autorização ainda são executadas no cliente e os vínculos são inferidos por telefone/e-mail. Isso gera ambiguidade, fragilidade e risco de segurança.

## 2. Arquitetura atual

### 2.1 Aplicativo Flutter

- Código: `mobile/lib`.
- Rotas: `GoRouter` em `mobile/lib/main.dart`.
- Estado: estado local de widgets, `ValueNotifier` para atualização de abas/perfil e `SharedPreferences` por meio de `AuthStorage`.
- Sessão: Firebase Auth mantém a sessão remota; `AuthStorage` persiste UID, perfil selecionado, academia, permissões e lista de perfis.
- Dados: `FirestoreService` acessa diretamente `academias/{academiaId}/...`.
- Autenticação: Firebase Auth por e-mail/senha. Telefone é transformado em e-mail sintético no formato `<digitos>@sensei.app`.
- Recuperação: `FirebaseAuth.sendPasswordResetEmail`; na prática, telefone sintético não recebe e-mail.
- Troca de perfil: `usuariosFirebase/{uid}.perfis` e busca dinâmica por e-mail/telefone na mesma academia.

Principais coleções do mobile:

- `academias`;
- `academias/{id}/usuarios` (inclui alunos com `perfil = 3`);
- `academias/{id}/funcionarios`;
- `academias/{id}/modalidades`;
- `academias/{id}/faixas`;
- `academias/{id}/graduacoes`;
- `academias/{id}/turmas`;
- `academias/{id}/horarios`;
- `academias/{id}/matriculas`;
- `academias/{id}/presencas`;
- `academias/{id}/planos`;
- `academias/{id}/pagamentos`;
- `academias/{id}/grupos_familiares`;
- `usuariosFirebase/{uid}` (identidade e lookup de perfis).

### 2.2 Firebase server-side

- Regras: `scripts/migrate-firestore/firestore.rules`.
- Índices: `firestore.indexes.json`.
- Cloud Functions: `functions/index.js`.
- Scheduler existente: função diária para alertas de contas da academia.
- Não existe hoje função server-side para ativação de conta, redefinição administrativa de senha, edição auditada de graduação, exclusão transacional de turma ou materialização idempotente das mensalidades.

### 2.3 Backend web

- ASP.NET Core/.NET 9 em `backend/src/AcademiaFight.API`.
- Camadas Domain, Application, Infrastructure e API.
- EF Core + PostgreSQL, migrations versionadas em `AcademiaFight.Infrastructure/Migrations`.
- JWT de 15 minutos e refresh token de sete dias armazenado no registro `Usuario`.
- Multi-tenant por `academia_id`, filtros globais do EF e `TenantMiddleware`.
- Hangfire já instalado e com jobs recorrentes.
- `Usuario` mistura identidade de autenticação e perfil de pessoa/aluno.
- `Funcionario` referencia `Usuario`; alunos também são registros de `Usuario` com perfil `Aluno`.

### 2.4 Frontend Angular

- Angular standalone + signals em `frontend-web/src/app`.
- `AuthService` guarda access/refresh token no `localStorage`.
- Interceptors enviam JWT e `X-Tenant-ID`.
- Guards controlam autenticação e permissões de navegação.
- Serviços REST acessam alunos, turmas, graduações e financeiro pela API .NET.

### 2.5 Migração histórica

O script `scripts/migrate-firestore/migrate.js` copiou dados do PostgreSQL para o Firestore e criou/vinculou contas Firebase. Ele confirma que os dois bancos compartilham origem histórica, mas atualmente não há sincronização bidirecional confiável.

O script contém uma string de conexão de produção no código-fonte. O segredo não é reproduzido neste documento. A credencial deve ser rotacionada e removida do histórico em uma atividade de segurança separada e prioritária.

## 3. Autenticação atual e causa raiz do telefone compartilhado

### 3.1 Mobile/Firebase — fluxo real em produção

1. O Primeiro Acesso cria uma sessão Firebase anônima.
2. O app lista academias e consulta `funcionarios` e `usuarios` por e-mail ou telefone.
3. O usuário escolhe um perfil quando há mais de um resultado.
4. Se o cadastro não tem e-mail, o app deriva `<somente-digitos>@sensei.app`.
5. O app chama `createUserWithEmailAndPassword`.
6. Se o e-mail Firebase já existe, tenta `signInWithEmailAndPassword` usando a senha digitada naquele segundo fluxo.
7. O próprio app escreve `usuariosFirebase/{uid}` e grava o mesmo UID nos perfis encontrados.

### 3.2 Cenário das duas irmãs

Para duas irmãs com o mesmo telefone e sem e-mail, as duas resolvem para o mesmo e-mail sintético. O Firebase Auth impõe unicidade de e-mail, portanto a segunda irmã não deveria criar uma segunda identidade com o mesmo valor canônico.

O comportamento observado é explicado por duas falhas combinadas:

- o fluxo permite iniciar Primeiro Acesso novamente para um identificador que já possui conta;
- ao receber `email-already-in-use`, o app tenta entrar com a nova senha como se estivesse concluindo uma ativação.

A segunda senha não sobrescreve a primeira no Firebase. Ela falha contra a conta já existente. Como a interface mistura criação, login e associação no mesmo método e os perfis podem ter formatos de telefone legados diferentes, o resultado percebido é que nenhuma senha é confiável e os vínculos podem ficar parciais.

Há ainda três fontes de inconsistência:

- `telefone_digits` não existe em todos os documentos antigos e o fallback compara apenas o texto exatamente informado;
- o vínculo `firebaseUid` é replicado em cada perfil, enquanto `usuariosFirebase/{uid}` guarda um perfil primário mutável;
- a atualização dinâmica de irmãos procura somente dentro da academia primária e por dados de contato atuais, em vez de consultar vínculos explícitos da conta.

### 3.3 Backend/PostgreSQL — bug equivalente

No backend, `Usuario` contém `Telefone` e `SenhaHash`. Não existe entidade separada de conta. Não há índice único de telefone; o único índice de identidade é `(Email, AcademiaId)` quando o e-mail não é nulo.

`AuthService.LoginAsync`, `PrimeiroAcessoAsync` e `RecuperarAcessoAsync` usam `FirstOrDefaultAsync` sobre e-mail/telefone sem ordenação nem tratamento de múltiplos resultados. Com duas irmãs:

- o Primeiro Acesso seleciona arbitrariamente um registro sem senha;
- o segundo Primeiro Acesso pode selecionar o outro;
- o login seleciona arbitrariamente apenas um dos registros e valida a senha somente daquele registro;
- uma senha válida do outro registro é rejeitada.

No PostgreSQL podem existir dois hashes diferentes. Não há sobrescrita obrigatória entre linhas, mas existe ambiguidade determinística insuficiente no login. Recuperação por telefone também pode aplicar o token ao perfil errado.

### 3.4 Conclusão da causa raiz

Telefone/e-mail estão sendo usados simultaneamente como:

- dado de contato do perfil;
- identificador exclusivo da credencial;
- mecanismo implícito de associação familiar.

Esses conceitos precisam ser separados. Um telefone compartilhado identifica uma conta/responsável, não um aluno específico. Os perfis vinculados devem ser explícitos e persistentes.

## 4. Riscos de segurança identificados

1. As regras permitem leitura anônima das academias, alunos e funcionários durante o Primeiro Acesso. Isso possibilita enumeração ampla de dados pessoais.
2. A criação de `usuariosFirebase/{uid}` valida apenas que o UID do documento é o do solicitante. Não valida no servidor a academia, o perfil ou o vínculo informado. Um cliente adulterado pode tentar atribuir a si mesmo outro tenant/perfil.
3. A regra genérica permite a qualquer professor escrever em todas as coleções da própria academia, independentemente das permissões granulares exibidas no app.
4. Operações sensíveis no mobile são executadas diretamente no cliente, sem auditoria confiável e sem transação composta server-side.
5. O backend usa `[Authorize]` em vários controllers administrativos, mas não aplica policies/roles por operação. Um aluno autenticado pode alcançar endpoints que deveriam ser administrativos se o service não fizer validação adicional.
6. `TenantMiddleware` aceita `X-Tenant-ID` quando não há claim autenticada. Rotas protegidas ainda exigem autenticação, mas a autorização precisa sempre derivar academia e papel da identidade autenticada.
7. Existe segredo de banco versionado em script de migração. Rotação é necessária.

Esses itens devem ser tratados antes ou junto dos novos endpoints sensíveis.

## 5. Modelos e estruturas afetados

### Firebase/Firestore

- `usuariosFirebase/{uid}`: evoluir para conta de autenticação explícita.
- `academias/{academyId}/usuarios/{studentId}`: manter perfil do aluno; remover a função de identidade.
- `academias/{academyId}/funcionarios/{employeeId}`: perfil de equipe.
- nova subcoleção/coleção de vínculos explícitos de conta e perfil.
- nova coleção de auditoria por academia.
- `graduacoes`: acrescentar metadados de atualização/auditoria e padronizar modalidade.
- `turmas`: `deleted_at`, `deleted_by` e estado arquivado.
- `matriculas`: encerrar/desativar vínculo em vez de apagar histórico.
- `pagamentos`: consolidar `mes_referencia`/competência e identidade determinística.

### PostgreSQL

- `usuarios`: hoje mistura conta e perfil.
- nova `auth_accounts` (ou equivalente).
- nova `auth_account_profiles` para associação N:N/1:N.
- campos de telefone canônico, troca obrigatória de senha e revogação de sessão.
- tabela de auditoria.
- `graduacoes`: atualização auditada.
- `turmas`: `deleted_at`/`deleted_by`.
- `pagamentos`: competência e índice único por tenant/aluno/competência/tipo.

O PostgreSQL não deve ser migrado antes de decidir formalmente qual plataforma é a fonte de verdade. Para o release mobile, o Firestore é a fonte operacional observada no código.

## 6. Endpoints/funções e telas envolvidas

### Mobile

- Entrada: nova rota `Escolha seu perfil` antes do login.
- Login com contexto `Aluno/Responsável` ou `Academia/Equipe`.
- Primeiro Acesso.
- Esqueci minha senha.
- Seleção e troca de perfil.
- Detalhe/edição de aluno.
- Segurança e Acesso do aluno.
- Histórico/edição de graduação.
- Detalhe/exclusão de turma.
- Financeiro com competência anterior, atual e futura.

### Firebase server-side a criar

- resolução segura de Primeiro Acesso;
- associação de conta a múltiplos perfis;
- redefinição administrativa e conclusão de troca obrigatória;
- edição auditada de graduação;
- exclusão lógica transacional de turma;
- `ensureChargesForPeriod` idempotente;
- job agendado para competência atual e próxima;
- relatório/backfill de contatos e vínculos ambíguos.

### Backend existente

- `/api/auth/login`, `/primeiro-acesso`, `/recuperar-acesso`, `/forgot-password`, `/reset-password`;
- `/api/alunos`;
- `/api/graduacoes`;
- `/api/turmas`;
- `/api/financeiro` e `/gerar-cobrancas`.

## 7. Estratégia de compatibilidade

1. Nenhum aluno, senha, pagamento, presença ou graduação será apagado na migração.
2. `usuariosFirebase/{uid}` será lido nos formatos antigo e novo durante uma janela de compatibilidade.
3. Vínculos existentes por `firebaseUid` terão prioridade e serão convertidos em vínculos explícitos.
4. Inferência por contato será usada apenas para gerar candidatos/relatório; não escolherá automaticamente entre contas conflitantes.
5. Telefones serão normalizados para formato canônico brasileiro (`+55...`) em um serviço único, mantendo os campos legados para leitura durante a transição.
6. Casos com um contato ligado a múltiplos UIDs serão marcados como conflito para resolução controlada; não haverá merge automático de credenciais.
7. Cobranças usarão IDs determinísticos para garantir idempotência no Firestore. Cobranças existentes serão reconhecidas por aluno, tipo e competência antes do backfill.
8. Pagamentos já quitados, descontos, observações e datas reais não serão sobrescritos.
9. Exclusão de turma será lógica; presenças e horários históricos permanecerão referenciáveis.
10. Deploy deverá ser compatível em ordem: funções/regras compatíveis, backfill, app novo e somente depois endurecimento final das regras legadas.

## 8. Plano de implementação por fases

### Fase 1 — testes de caracterização e fundações

- adicionar testes que reproduzem telefone compartilhado e ambiguidade do backend;
- criar normalizador canônico único em Dart, JavaScript e, se mantido, C# com vetores compartilhados;
- criar modelos de competência/status financeiro puros e testáveis;
- registrar o formato de documentos atual em fixtures sem dados reais;
- preparar emuladores Firebase para testes de rules/functions.

### Fase 2 — identidade e múltiplos perfis

- evoluir `usuariosFirebase` para Auth Account versionada;
- persistir `profile_refs` explícitos;
- criar Cloud Function autenticada para associação/ativação;
- impedir nova senha para um telefone que já possui conta: orientar para Entrar/Recuperar;
- selecionar perfil após login e permitir troca sem logout;
- suportar perfis em múltiplas academias sem elevação de privilégio;
- criar backfill e relatório de conflitos, sem merge arbitrário;
- restringir leitura anônima e criação livre de lookup nas rules.

### Fase 3 — nova entrada do aplicativo

- tela inicial com os dois cards solicitados;
- login contextualizado por público;
- ocultar cadastro de academia do fluxo aluno/responsável;
- renomear ação empresarial para `Criar uma academia`;
- revisar semântica, contraste, foco, tamanhos e áreas clicáveis;
- testes de widget e navegação.

### Fase 4 — redefinição administrativa e senha temporária

- Cloud Function somente Admin/Secretaria com permissão específica;
- gerar senha temporária segura e atualizar Firebase Auth via Admin SDK;
- armazenar apenas flag/data, nunca a senha;
- revogar refresh tokens;
- gravar auditoria sem segredo;
- exibir senha uma única vez com copiar/compartilhar;
- bloquear navegação enquanto `must_change_password` estiver ativo;
- concluir troca de senha e limpar flag server-side.

### Fase 5 — edição do aluno e graduação

- inventariar e liberar somente campos administrativos legítimos;
- validar e normalizar telefone/e-mail centralmente;
- não alterar vínculo de autenticação silenciosamente ao editar contato;
- adicionar ação Editar em cada graduação;
- permitir correção sem regra de progressão ascendente;
- transação server-side com `before/after`, operador e timestamp;
- recalcular faixa atual por modalidade, usando data/hora e desempate estável;
- alertar quando a correção entrar em conflito com eventos posteriores.

### Fase 6 — exclusão segura de turma

- substituir hard delete por arquivamento/soft delete;
- marcar matrículas ativas como encerradas na mesma transação;
- manter presenças, graduações, horários históricos e alunos;
- filtrar turmas excluídas em listagens operacionais;
- manter resolução do nome da turma em relatórios históricos;
- registrar auditoria.

### Fase 7 — financeiro automático e competência

- consolidar `mes_referencia` como `YYYY-MM` em todas as mensalidades;
- usar ID determinístico, por exemplo hash/concatenação segura de academia, aluno, competência e tipo;
- implementar `ensureChargesForPeriod` em Cloud Functions com transação/create idempotente;
- agendar geração de mês atual + próximo;
- chamar garantia server-side ao abrir Financeiro como fallback, nunca gerar apenas no cliente;
- respeitar alunos ativos, plano e dia de vencimento já usados pelo fluxo manual;
- habilitar navegação para próximo mês;
- permitir baixa antecipada preservando a data real de pagamento;
- manter geração manual apenas como ferramenta excepcional/avulsa;
- backfill idempotente sem tocar em cobranças existentes.

### Fase 8 — integração, regressão e rollout

- testes de functions, rules, widgets e integração;
- teste com emuladores e massa sintética de duas irmãs;
- relatório de conflitos antes do backfill de produção;
- deploy progressivo e observabilidade;
- rollback documentado;
- atualizar modal e notas da loja somente após aprovação funcional.

## 9. Plano de testes

### Autenticação

- um telefone, uma conta, um perfil;
- duas irmãs, mesmo telefone, uma conta e dois perfis;
- formatos `219...`, `(21)...`, `+55...` e `55...` convergem;
- contato compartilhado com dois UIDs gera conflito e não merge automático;
- novo perfil aparece sem refazer Primeiro Acesso;
- conta temporária exige troca e revoga senha/sessões anteriores;
- aluno não consegue se promover a Admin nem vincular perfil de outra academia.

### Graduação

- editar azul 2 para azul 1;
- corrigir roxa para azul;
- preservar regra ascendente apenas na nova graduação;
- recalcular atual por modalidade;
- mesmo dia usa timestamp/ordem estável;
- auditoria contém before/after sem perda do registro.

### Turmas

- excluir turma com três matrículas;
- turma some das listas ativas;
- alunos permanecem;
- matrículas ficam inativas/encerradas;
- presenças e relatórios históricos continuam íntegros;
- falha parcial faz rollback.

### Financeiro

- virada de competência gera mês atual;
- execução repetida e concorrente não duplica;
- pendente/atrasado/pago calculados corretamente;
- próximo mês existe e aceita pagamento antecipado;
- `paid_at` registra a data real;
- aluno sem plano/inativo/inelegível não recebe cobrança;
- cobrança antiga ou paga nunca é sobrescrita.

### Regressão

- login e refresh no web;
- login Firebase no mobile;
- perfis Admin, Secretaria, Professor e Aluno;
- dashboard, alunos, turmas, presença, graduação e financeiro;
- troca de perfil/academia;
- logout e restauração de sessão;
- regras Firestore testadas contra acesso cross-tenant.

## 10. Riscos e decisões pendentes

- É necessário definir oficialmente se Firestore ou PostgreSQL será a fonte de verdade de longo prazo. No curto prazo, o app exige correções no Firebase.
- Primeiro Acesso apenas com telefone, sem OTP e sem senha temporária emitida pela academia, não comprova posse do número. A opção zero-custo segura é ativação assistida pela academia; OTP pode ser plugado no futuro.
- Merge de contas Firebase não é operação automática segura. Conflitos precisam de relatório e resolução controlada.
- Regras antigas precisam permanecer compatíveis durante rollout, mas a janela permissiva deve ser a menor possível.
- Backfill em produção deve rodar em modo dry-run antes de qualquer escrita.
- As alterações equivalentes no backend web exigem migrations PostgreSQL próprias; não devem ser confundidas com o rollout Firestore do mobile.

## 11. Critérios de gate antes de alterar produção

- testes de caracterização vermelhos reproduzem os bugs;
- emuladores Firebase configurados;
- rules novas testadas contra escalada de privilégio e cross-tenant;
- relatório de conflitos executado em dry-run;
- ordem de deploy e rollback aprovadas;
- nenhuma credencial ou dado pessoal em fixtures/logs;
- nenhuma alteração ou commit automático em produção.
