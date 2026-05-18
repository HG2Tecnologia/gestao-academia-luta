# Contexto para Claude Code — App Mobile (Academia Fight)

## Stack atual (sistema web — 100% completo)
- **Backend**: .NET 9 / ASP.NET Core, EF Core, PostgreSQL 15, JWT Auth, Hangfire, SignalR
- **Frontend web**: Angular 17 (standalone + signals), hospedado separado
- **Pasta**: `backend/src/AcademiaFight.API` + `frontend-web/src/`
- **API base**: `http://localhost:5226` (dev); prefixo `/api/`

## Entidades principais já existentes no backend
| Entidade | Notas |
|----------|-------|
| Academia | multi-tenant; todo recurso tem `AcademiaId` |
| Usuario | `Perfil`: Admin, Secretaria, Professor, Aluno |
| Aluno | ligado a Usuario; tem Faixa, XP, MatriculaAtiva |
| Turma | tem ModalidadeId, ProfessorId, Capacidade |
| Horario | TurmaId, DiaSemana, HoraInicio, HoraFim |
| Matricula | AlunoId + TurmaId; campo `Ativo` |
| Presenca | AlunoId, HorarioId, Data, HoraCheckin |
| Graduacao | tabela de eventos de promoção de faixa |
| Faixa | ModalidadeId, Nome, Cor, Ordem |
| Modalidade | Nome, Descricao, Ativa |
| Plano | nome, valor mensal, modalidades |
| Contrato | AlunoId, PlanoId, datas, status |
| Cobranca | AlunoId, valor, vencimento, status (Pendente/Pago/Atrasado) |
| Ranking | XP por aluno; endpoints `/api/ranking` |
| Funcionario | UsuarioId, Cargo, Permissoes (JSON) |

## Endpoints existentes relevantes para mobile
```
POST /api/auth/login                → { email, senha } → { token, perfil, nome, academiaId }
POST /api/auth/primeiro-acesso      → { email | telefone, academia } → cria/valida, retorna token setup
POST /api/auth/alterar-senha        → { senhaAtual, novaSenha }
POST /api/auth/definir-senha        → { token setup, novaSenha } (primeiro acesso)

GET  /api/usuarios/me               → { id, nome, email, telefone, perfil }
PUT  /api/usuarios/me               → { nome, telefone }

GET  /api/alunos                    → lista (admin/secretaria)
GET  /api/alunos/:id                → detalhe completo
GET  /api/alunos/:id/presencas      → histórico
GET  /api/alunos/:id/contratos      → contratos + cobranças
GET  /api/alunos/me                 → perfil do aluno logado (PRECISA CRIAR)

GET  /api/turmas                    → lista; query: modalidadeId, professorId
GET  /api/turmas/:id                → detalhe + alunos matriculados

GET  /api/horarios                  → lista; query: turmaId, diaSemana
GET  /api/horarios/meus             → horários do professor logado (PRECISA CRIAR)

GET  /api/presencas                 → lista; query: alunoId, turmaId, dataInicio, dataFim
POST /api/presencas                 → { alunoId, horarioId, data } (professor/admin)

GET  /api/graduacao/faixas          → faixas por modalidade
POST /api/graduacao                 → promover aluno de faixa

GET  /api/ranking                   → ranking geral
GET  /api/dashboard                 → métricas gerais (admin)

GET  /api/funcionarios              → lista
POST /api/funcionarios              → criar
DELETE /api/funcionarios/:id        → remover

GET  /api/modalidades               → lista
GET  /api/cobrancas/minhas          → cobranças do aluno logado (PRECISA CRIAR)
GET  /api/cobrancas                 → todas (admin)
```

## Perfis de usuário no app mobile

### Admin
- Dashboard: métricas resumidas (alunos ativos, receita mês, presenças hoje)
- Alunos: lista + detalhe (somente leitura no mobile)
- Turmas: lista + detalhe
- Horários: grade semanal
- Funcionários: lista, adicionar, remover
- Graduação: visualizar eventos recentes
- Rankings: top alunos
- Presenças: histórico
- Financeiro: cobranças gerais + status

### Professor
- Meu perfil (editar nome/telefone)
- Minhas turmas: ver alunos matriculados (somente leitura)
- Meus horários: grade dos horários onde é professor
- Registrar presença: selecionar turma/aula → marcar alunos presentes
- Graduação: promover faixa de aluno

### Aluno
- Meu perfil (nome, foto avatar, faixa atual, XP)
- Horários da academia: grade de todos os horários; turmas sem matrícula ficam dimmed
- Minhas presenças: contador + histórico
- Financeiro: status da mensalidade atual (Pago / Pendente / Atrasado), histórico de cobranças
- Ranking: posição geral + top 10

## Primeiro acesso (aluno e professor)
- Entram no app → "Primeiro acesso"
- Informam e-mail **ou** telefone + subdomínio da academia
- Sistema valida que o usuário existe e está ativo (criado pelo admin)
- Se válido: envia código/link → usuário define senha → logado
- Endpoint a criar: `POST /api/auth/primeiro-acesso`

## Tech stack sugerido para mobile
- **React Native + Expo** (mais rápido, cross-platform iOS/Android)
- **TypeScript**
- **Expo Router** (file-based navigation, similar ao Angular Router)
- **Axios** ou **fetch** para HTTP (apontando para mesma API .NET)
- **AsyncStorage** para persistir JWT
- **React Native Paper** ou **NativeWind** para UI

## Estrutura de pastas sugerida
```
mobile/
  app/
    (auth)/           # login, primeiro-acesso
    (admin)/          # tabs: dashboard, alunos, turmas, funcionários, financeiro
    (professor)/      # tabs: turmas, horários, presença, graduação
    (aluno)/          # tabs: perfil, horários, presenças, financeiro, ranking
  src/
    services/         # api.ts, auth.service.ts, aluno.service.ts ...
    components/       # componentes compartilhados
    hooks/            # useAuth, useAcademia
    constants/        # cores, fontes
```

## Contexto de negócio
- SaaS multi-tenant: cada academia tem subdomínio próprio
- App mobile usa o **mesmo backend** da versão web
- JWT inclui claims: `sub` (usuarioId), `academiaId`, `perfil`, `nome`
- Cores primárias: indigo `#6366f1` (roxo/azul), fundo escuro `#0f172a`
- Nome do produto: **Tatame** (domínio: tatame.app)

## O que precisa ser criado no backend antes do mobile
1. `GET /api/alunos/me` — dados do aluno logado (perfil, faixa, XP)
2. `GET /api/horarios/meus` — horários do professor logado
3. `POST /api/auth/primeiro-acesso` — validar e iniciar fluxo de senha
4. `GET /api/cobrancas/minhas` — cobranças do aluno logado
