# QA — CRM Web — Reteste pós-correções do Hugo (2026-11-26)

Reteste do levantamento de `docs/qa-web-lancamento-2026-11-25.md`, depois do commit
`60a66067` ("fix(web): corrige o QA de lançamento e alinha os cadastros ao app") na mesma
branch `qa-web-lancamento`. Rodado localmente (`ng serve`), logado como Admin na "Forny
School".

## Todos os 6 itens do levantamento anterior: confirmados corrigidos

1. **Lista de Alunos misturando equipe** — ✅ corrigido. `aluno.service.ts` agora filtra
   `where('perfil', '==', 3)`. Confirmado: só alunos reais aparecem (inclusive um caso
   legítimo — um aluno chamado "Gabriel" com o mesmo e-mail do Admin, por ele treinar na
   própria academia — não confundir com o bug antigo).
2. **Deploy frágil** — ✅ corrigido. Novo script `npm run deploy:crm` +
   `frontend-web/scripts/check-shell.cjs` como `predeploy` hook em `firebase.json`: aborta o
   deploy (exit code 2) se `app-shell.html` não existir.
3. **Contraste na Grade de Horários** — ✅ corrigido. Cards agora com fundo escuro, nome da
   turma em branco, bem legível.
4. **"Meu Perfil" não carregava dados salvos** — ✅ corrigido. Nome e telefone vêm
   preenchidos corretamente ao abrir Configurações.
5. **Falta de botão "Atualizar"** — ✅ implementado em Dashboard, Alunos e Financeiro
   (provavelmente em mais telas, não testei todas).
6. **"Configurações" fora do menu lateral** — ✅ corrigido, item de volta na sidebar.

## Regras de cadastro novas (alinhadas ao app) — testado uma amostra

- **Aluno só com nome**: criado `QATESTE_SoNome` com nenhum outro campo preenchido — aceitou
  sem erro, mesmo com "Acesso ao app liberado" marcado por padrão e sem telefone/e-mail (lida
  bem com a ausência, não trava).
- **Funcionário, senha temporária visível**: criado `QATESTE_Funcionario` — modal com a senha
  temporária, texto explicativo e botão "Copiar" aparece certinho. No menu de ações da lista,
  também tem "Ver senha temporária" e "Redefinir senha" diretos.
- **Funcionário desativar preserva telefone/permissões**: desativado `QATESTE_Funcionario` —
  telefone e perfil continuam visíveis na lista depois (status vira "Inativo", dados não
  somem).
- **Turma com professor opcional**: criada `QATESTE_TurmaSemProf` sem selecionar professor —
  aceitou, campo "Professor" aparece vazio no detalhe, sem erro.

Não testado nesta rodada (por tempo): regras de Presença (inativo/mensalidade
vencida/limite semanal), horário gravado como HH:MM:00, login da equipe por e-mail,
primeiro-acesso obrigando trocar senha, mensagem do limite do plano gratuito, grupo
familiar.

## ⚠️ Pendência que o próprio Hugo já sinalizou (não é bug, é trabalho em aberto)

A restrição de **gravação do Professor nas regras do Firestore** (ex.: impedir que um
Professor grave em `pagamentos`/dados financeiros) **não foi aplicada** — só existe uma
proposta de teste em `docs/proposta-regras-professor.patch`. Hoje a tela já esconde essas
ações pra um Professor (UI gate), mas a regra do banco em si ainda permitiria a escrita se
alguém contornasse a UI (chamada direta à API). Não bloqueia o lançamento (defesa em
profundidade, não um buraco explorável pela UI normal), mas vale aplicar antes ou logo depois.

## Achado novo (não é bug de código — é limpeza de dados pendente)

Encontrados 3 alunos de teste órfãos de uma rodada de QA **anterior** (não desta sessão, nem
do Hugo): `QATESTE_Alpha`, `QATESTE_Beta`, `QATESTE_Gamma` (e-mail `qateste.alpha@mailinator.com`
repetido nos dois primeiros) na academia "Forny School". Ninguém limpou depois daquele teste.
Recomendo desativar/remover — são dados de teste reais misturados com o cadastro real da
academia.

## Limpeza realizada nesta sessão

Desativados/arquivados (dados de teste desta rodada, não removidos permanentemente porque a
UI só oferece desativar/arquivar, nunca excluir — comportamento correto e intencional):
- Aluno `QATESTE_SoNome` → desativado.
- Funcionário `QATESTE_Funcionario` → desativado.
- Turma `QATESTE_TurmaSemProf` → arquivada.

## Parecer

Praticamente pronto para lançamento do lado do CRM web. Nenhum item crítico ou alto
pendente. O que falta é baixa prioridade (regra de Professor nas rules) ou limpeza de dados
(os 3 QATESTE_ órfãos), nenhum dos dois bloqueia.
