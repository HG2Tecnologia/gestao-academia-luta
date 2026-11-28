# QA — CRM Web (Sensei Manager) — 2026-11-25

Levantamento feito rodando o CRM web localmente (`ng serve`), logado na academia de teste
(`gf097@hotmail.com`, academia "Forny School"), com um teste adicional de cadastro de
academia do zero (criada e depois removida — ver "Limpeza" no fim).

Cobertura: login, troca de perfil, cadastro de academia do zero, navegação por todas as
seções do menu (Dashboard, Alunos, Turmas, Horários, Presenças, Graduação, Ranking, Planos,
Financeiro, Contratos, Relatórios, Catraca, Modalidades, Configurações), F5/reload em cada
uma, e comparação do comportamento de produção (`sensei-crm.web.app`) via rede.

Não coberto nesta rodada: edição/exclusão detalhada de registros específicos, permissões de
perfil Professor/Secretaria, fluxos de contrato assinado, importação de planilha, upload de
logo, exportação de dados — nada disso foi testado a fundo.

## 🔴 Crítico — bloqueia lançamento

### 1. Lista de Alunos mistura equipe (Admin/Professor/Secretaria) com alunos reais
Confirmado criando uma academia do zero: o próprio Admin (dono da conta) aparece na lista de
"Alunos" com status "Ativo"/"Em dia", contando no total de alunos cadastrados.

**Causa raiz:** `frontend-web/src/app/core/services/aluno.service.ts:57`
(`carregarListaCompleta`) faz `getDocs` em **toda** a subcoleção `academias/{id}/usuarios`,
sem nenhum filtro por `perfil`. Essa subcoleção é compartilhada entre staff e alunos (mesmo
padrão do mobile), então qualquer membro da equipe aparece junto.

**Impacto:** provavelmente afeta toda academia já existente, não só a nova — inclusive a
"Forny School" (não confirmei visualmente por falta de tempo, mas o código não tem exceção
para ela).

**Fix sugerido:** filtrar a query (ou o resultado) por `perfil` antes de montar a lista —
excluir Admin/Professor/Secretaria, manter só o que é efetivamente aluno.

## 🟠 Alto — risco operacional

### 2. Deploy do CRM web é frágil, sem CI nem documentação
O rewrite do Firebase Hosting (`firebase.json`, target `crm`) aponta pra `/app-shell.html`.
Esse arquivo só é gerado pelo script `npm run build:prod` (roda `ng build` +
`scripts/strip-shell.cjs`) — **não** é gerado por `ng build` nem `npm run build` puro, os
comandos mais "óbvios".

Se alguém fizer o deploy com o comando errado, toda rota fora da home/termos/privacidade
(ou seja, todo o app logado: `/app/**`) passa a devolver 404 ao dar F5 ou acessar um link
direto — foi exatamente o que a rodada de QA anterior relatou. Hoje a produção
(`sensei-crm.web.app`) está servindo corretamente (testado), mas nada impede que o próximo
deploy manual quebre de novo, já que não há CI nem checagem automática.

**Fix sugerido:** um script único de deploy (ex: `npm run deploy:crm` = build:prod +
`firebase deploy --only hosting:crm`) e/ou uma checagem que falha o deploy se
`app-shell.html` não existir no `dist`.

## 🟡 Médio

### 3. Grade de Horários: nome da turma ilegível
Na tela "Horários", o nome da turma (ex. "Jiu Jitsu Adulto") aparece em cinza muito claro
sobre fundo branco dentro do card do dia — praticamente invisível (confirmado com zoom). O
nome da modalidade logo abaixo (cor normal) está correto; só a primeira linha tem o problema
de contraste.

### 4. Configurações → "Meu Perfil" não carrega nome/telefone salvos
Em `/app/configuracoes`, a seção "Meu Perfil" mostra "— sem e-mail" e os campos Nome/Telefone
vazios, mesmo havendo dados reais salvos (visíveis corretamente em outros lugares da mesma
tela, como "E-mail do administrador"). Pode confundir o usuário, parecendo que o perfil foi
resetado.

## 🟢 Baixo / melhoria de UX

### 5. Falta de atualização em tempo real na maioria das telas
Confirmado no código: de todos os serviços do CRM web, só `catraca.service.ts` e
`notificacao.service.ts` usam `onSnapshot` (tempo real). Todo o resto — Financeiro, Alunos,
Turmas, Dashboard, Presenças, Graduação, Ranking, Planos, Contratos, Relatórios,
Modalidades — busca os dados **uma vez só**, ao abrir a tela. Uma mudança feita no app
mobile, em outra aba, ou por outro usuário da equipe não aparece sem recarregar a página
inteira.

**Proposta:** adicionar um botão "Atualizar" pontual nas telas mais sensíveis a isso
(Financeiro é a mais óbvia, Dashboard e Alunos também fazem sentido) — mais barato e
controlado do que migrar todas as telas para listeners em tempo real.

### 6. "Configurações" não está no menu lateral
Só é alcançável pelo dropdown do perfil (canto superior direito) → "Meu perfil". Pequena
questão de descoberta — outras seções de administração estão todas no menu lateral.

## ✅ Verificado e confirmado OK (não são bugs)

- **F5 → "not found"**: não reproduz na produção atual. Causa raiz é o item 2 (processo de
  deploy), já registrado ali.
- **Tela de escolha de perfil no login mostrando opção de aluno**: já está implementado
  corretamente em `firebase-auth.service.ts:184-238` — filtra para só perfis de equipe
  (`PERFIS_STAFF`), bloqueia totalmente contas que só têm perfil de aluno
  (`LoginSemAcessoStaffError`), e só mostra a tela de escolha quando há 2+ perfis de
  **equipe** na mesma conta (ex.: Admin e Professor ao mesmo tempo — foi exatamente esse o
  caso testado).
- **Cadastro de academia do zero**: funciona ponta a ponta — cria conta Firebase Auth,
  documento da academia, usuário Admin, e semeia corretamente 8 modalidades padrão com 54
  faixas no total (confirmado contando os documentos criados).
- **Trial de 30 dias**: já reflete em toda a parte pública (home, fluxo de cadastro).

## Limpeza realizada nesta sessão

Para o teste do item "cadastro do zero" foi criada uma academia descartável ("QA Teste
Academia Claude", e-mail `qa.teste.claude.20261125@mailinator.com`). Removidos após o teste:
conta de autenticação, documento do usuário Admin, 8 modalidades e 54 faixas (63 documentos
no total).

**Pendente:** 2 documentos órfãos e inofensivos não puderam ser removidos via SDK cliente
(bloqueados pelas regras do Firestore, que não permitem a uma conta apagar o próprio
documento raiz da academia nem `usuariosFirebase/{uid}`) — sem a conta de autenticação
correspondente (já apagada), ninguém consegue mais acessá-los ou logar neles. Para limpeza
total, apagar manualmente no Console ou via Admin SDK:
- `academias/svvb3eSA83tk1GT6SZkH`
- `usuariosFirebase/DGwmldshpdNIIoxaHllCbF4RILq2`
