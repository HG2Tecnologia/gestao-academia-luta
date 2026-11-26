# Plano Black Belt: roteiro para retestar tudo

Última atualização: 26/11/2026

Documentos relacionados:
[plano e decisões](black-belt-plano-desenvolvimento.md) ·
[cadastro nas lojas](black-belt-cadastro-lojas.md)

## 1. O que foi feito

Branch: `ajuste-novas-assinaturas`. **Nada foi publicado em produção.**

| Fase | Entrega | Commit | Principais arquivos |
|---|---|---|---|
| 1 | Simulação nos emuladores | `7dc6ccb0` | `functions/scripts/`, `frontend-web/src/environments/` |
| 2 | Correções de segurança | `aa22873f` | `functions/iap-functions.js`, `functions/domain/subscription-access.js`, `firestore.rules` |
| 3 | Black Belt no servidor e teste sem limites nas regras | `30d242fe` | os mesmos da fase 2 |
| 3 | Suspensão no Google retira o acesso | `ec1aecd9` | `functions/iap-functions.js` |
| 4 | App: dois planos, troca e bloqueios | `2c6c2775` | `mobile/lib/core/plan_catalog.dart`, `iap_service.dart`, `plan_service.dart`, `paywall_modal.dart` |
| 5 | Web: acesso, tela de bloqueio e selo do plano | sem commit na data acima | `frontend-web/src/app/core/` (`acesso-web`), `features/assinatura/` |

Os commits eram locais em 26/11/2026. Para testar em outra máquina, a branch precisa ter
sido enviada ao GitHub (`git log` deve mostrar os commits acima).

## 2. Preparação

| Item | Versão usada |
|---|---|
| Node | 22.12 |
| Java (emuladores) | 17. O Firebase CLI avisa que versões futuras vão exigir 21 |
| Flutter | 3.44.1 via FVM. **Não usar** outra versão: altera `pubspec.lock` e arquivos gerados |
| Navegador | Edge ou Chrome |
| Sistema | Windows 11 |

```bash
cd functions    && npm ci
cd frontend-web && npm ci
cd mobile       && fvm flutter pub get
```

Cuidados:

- Usar sempre os emuladores. `npm start` no web (sem `:emu`) aponta para a **produção**.
- No Windows, o emulador do Firestore (processo `java`) às vezes continua aberto depois de
  encerrado. Se a porta 8080 estiver ocupada, encerre esse processo:
  `Get-NetTCPConnection -LocalPort 8080 -State Listen` mostra o número dele.
- Para o reteste não é preciso estar logado no Firebase (`firebase login`).

## 3. Testes automáticos

### 3.1 Servidor (pasta `functions`)

Rodar um por vez, com os emuladores **fechados** (cada comando abre os seus).

| Comando | Cobre | Esperado |
|---|---|---|
| `npm test` | Unitários, inclusive cenários | 67 de 67 |
| `npm run test:rules` | Regras do Firestore | 22 de 22 |
| `npm run test:iap` | Ativação, notificações, Black Belt, suspensão | 77 de 77 |
| `npm run test:iap-reconciliation` | Reconciliação diária | 5 de 5 |
| `npm run test:exclusao` | Exclusão de conta | 4 de 4 |
| `npm run test:identity` | Identidade | 1 de 1 |
| `npm run test:admin` | Administração | **16 de 17** (ver abaixo) |
| `npm run test:aluno` | Aluno | 3 de 3 |
| `npm run test:turma` | Turma | 3 de 3 |
| `npm run test:finance` | Financeiro | 8 de 8 |
| `npm run test:graduacao` | Graduação | 4 de 4 |
| `npm run test:modalidades` | Modalidades | 11 de 11 |
| `npm run test:attribution` | Atribuição | 8 de 8 |
| `npm run test:analytics` | Analytics | 8 de 8 |

Falha conhecida em `test:admin`: *"telefone compartilhado por vários alunos vira UMA
notificação combinada"* (espera 1, recebe 3). O teste e a função são iguais aos da `main`.
Pela leitura do código, o teste conta notificações deixadas pelos testes anteriores do mesmo
arquivo. Não foi corrigido.

Como esses números foram obtidos: com os mesmos arquivos de teste, mas reaproveitando um
emulador que já estava aberto, em vez dos comandos `npm run` da tabela. Os comandos ainda
precisam ser confirmados no reteste.

### 3.2 Web (pasta `frontend-web`)

```bash
npm run test:acesso     # regra de acesso: esperado 22 de 22
npm run build:prod      # deve compilar (há um aviso antigo de tamanho no CSS da landing)
```

Telas em navegador real (esperado: **22 verificações, 0 falhas**):

```bash
# terminal 1, em functions
npm run emu
# terminal 2, em functions
npm run seed:emu
# terminal 3, em frontend-web
npm run start:emu
# terminal 4, em frontend-web
npm i --no-save playwright-core
npm run test:telas       # NAVEGADOR=chrome para usar o Chrome
```

O final da execução mostra a pasta com as capturas de tela.

### 3.3 App (pasta `mobile`)

```bash
fvm flutter test                       # esperado: 221 de 221
fvm flutter analyze --no-pub lib test  # 466 avisos que já existiam; nenhum erro
```

## 4. Testes manuais nos emuladores

```bash
# functions, terminal 1
npm run emu
# functions, terminal 2
npm run seed:emu
npm run cenario                       # lista os cenários
npm run cenario -- black              # aplica um
npm run cenario -- bloqueio ligado    # trava do web (ou: desligado)
# frontend-web
npm run start:emu
# mobile (emulador Android ou simulador iOS)
fvm flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

| Login | Senha | Perfil |
|---|---|---|
| `admin.teste@academia.com` | `admin123` | Admin |
| `prof.teste@academia.com` | `prof123` | Professor |

Depois de trocar de cenário, **feche e reabra o app** e recarregue o web.

### 4.1 Cenários (com a trava do web **ligada**)

| Cenário | App deve mostrar | Web | Web [ok] | App [ok] |
|---|---|---|---|---|
| `teste` | Sem limites e sem anúncios | Entra, selo "Teste: 30 dias" | [ ] | [ ] |
| `teste-acabando` | Aviso de 3 dias, sem limites | Entra, selo "Teste: 3 dias" | [ ] | [ ] |
| `gratis` | Plano gratuito, limites 5 alunos, 1 turma, 1 funcionário | "Seu período de teste terminou" | [ ] | [ ] |
| `pro` | "Sensei PRO · Mensal", "O sistema web faz parte do Sensei Black Belt" | "O sistema web faz parte do Black Belt" | [ ] | [ ] |
| `black` | "Sensei Black Belt · Mensal", "Inclui o sistema web" | Entra, selo "Black Belt" | [ ] | [ ] |
| `pro-cancelado` | Aviso de assinatura cancelada, acesso mantido | Bloqueado como `pro` | [ ] | [ ] |
| `black-cancelado` | Aviso de cancelada, acesso mantido | Entra | [ ] | [ ] |
| `pro-carencia` | Aviso de problema no pagamento, acesso mantido | Bloqueado como `pro` | [ ] | [ ] |
| `black-carencia` | Aviso de problema no pagamento, acesso mantido | Entra | [ ] | [ ] |
| `suspenso` | Plano gratuito; tocar no plano em Configurações abre "Meu plano" com o aviso "Assinatura suspensa" | "Assinatura suspensa" | [ ] | [ ] |
| `expirado` | Plano gratuito | "Seu período de teste terminou" | [ ] | [ ] |
| `reembolsado` | Plano gratuito | "Seu período de teste terminou" | [ ] | [ ] |
| `cortesia-web` | Plano gratuito | Entra, selo "Acesso cortesia" | [ ] | [ ] |
| `cortesia` | Sensei PRO | Bloqueado como `pro` | [ ] | [ ] |

### 4.2 Outros pontos

| Verificação | Esperado | [ok] |
|---|---|---|
| Trava desligada com `gratis`, `pro` e `black` | Todos entram; o selo mostra o plano | [ ] |
| Professor com `gratis` no web | "Peça a quem administra a academia" | [ ] |
| Digitar `/app/alunos` com `pro` | Volta para a tela de bloqueio | [ ] |
| "Já assinei, verificar novamente" após aplicar `black` | Entra no sistema | [ ] |
| "Sair" na tela de bloqueio | Volta ao login | [ ] |
| Link público de assinatura de contrato com `gratis` | Abre normalmente | [ ] |
| Tela de planos do app (em depuração) | Seletor "PRO só app" e "Black Belt app + web", três períodos | [ ] |
| Preços de reserva do Black Belt | R$ 99,99 / 229,90 / 749,90 | [ ] |
| App com `pro` abrindo a tela de planos | Abre na aba Black Belt; no PRO, o Mensal aparece travado como plano atual | [ ] |
| Professor no app com `black`, depois de reabrir | Sem bloqueios de plano | [ ] |

Nos emuladores **não há compra**: o app mostra os preços de reserva.

## 5. Testes nas lojas (fase 8)

Só depois de publicar o servidor (fase 6) e cadastrar os produtos (fase 7). Usar **uma
academia de teste**: compra de teste libera o plano de verdade no banco (marcada como
`sandbox`). Os tempos de renovação acelerada estão na documentação da
[Apple](https://developer.apple.com/help/app-store-connect/test-in-app-purchases/manage-sandbox-apple-account-settings/)
e do [Google](https://developer.android.com/google/play/billing/test).

| Cenário | Esperado | Apple [ok] | Google [ok] |
|---|---|---|---|
| Compra de cada um dos seis produtos | Plano certo; web só no Black Belt | [ ] | [ ] |
| Upgrade PRO para Black Belt | Web na hora; **uma só assinatura na loja** | [ ] | [ ] |
| Downgrade Black Belt para PRO | Web até a renovação, depois sem web | [ ] | [ ] |
| Troca só de período | Vale na renovação, sem segunda cobrança | [ ] | [ ] |
| Cancelamento | Acesso até o fim do período | [ ] | [ ] |
| Falha de cobrança com carência | Acesso mantido, com aviso | [ ] | [ ] |
| Fim da carência / suspensão (Google) | Perde o acesso; volta ao pagar | [ ] | [ ] |
| Expiração | Volta ao grátis | [ ] | [ ] |
| Reembolso | Perde o acesso | [ ] | [ ] |
| "Restaurar compra" | Mantém o plano correto | [ ] | [ ] |
| Mesma compra em outra academia | Mensagem de assinatura em uso | [ ] | [ ] |
| Comprar com assinatura ativa na outra loja | Compra bloqueada, sem cobrança | [ ] | [ ] |
| Comprar com outra conta da loja | Compra bloqueada, sem cobrança | [ ] | [ ] |
| Cupom do PRO mensal (Android) | Continua aplicando o desconto | [ ] | [ ] |
| Assinante PRO antigo, após a publicação | Continua PRO, sem web | [ ] | [ ] |

## 6. Depois de publicar o servidor

| Verificação | Esperado | [ok] |
|---|---|---|
| Cadastro de academia nova no app (versão atual das lojas) e no web | Conclui sem erro | [ ] |
| URL de `testarReconciliacaoAssinaturas` sem autenticação | Recusada (403) | [ ] |
| "Restaurar compra" em uma conta PRO existente | Continua PRO | [ ] |
| Academia no teste cadastrando o sexto aluno (app novo) | Permitido | [ ] |

## 7. O que não foi verificado e pontos de atenção

**Não verificado em 26/11/2026**

- Compilação do app para Android e iOS e uso em aparelho.
- Qualquer compra real ou de teste na Apple ou no Google: as respostas das lojas foram
  simuladas nos testes.
- No iPhone, a detecção de assinatura em outra conta da loja.
- O fluxo completo `npm run emu` + app.

**Decisão tomada no desenvolvimento, a confirmar pelos sócios**

- Quem compra o PRO durante o teste continua com o web até o teste acabar.

**Limitações conhecidas**

- A trava do web é de interface. App e web usam o mesmo login e o mesmo banco, e as regras
  não distinguem um do outro.
- Se a leitura do plano falhar no web (rede, por exemplo), o acesso é liberado.
- O web reavalia o plano a cada 60 segundos de navegação.
- A tela de planos do app está só em português.
- Apple em nova tentativa de cobrança sem carência mantém o acesso (comportamento anterior,
  a confirmar na documentação da Apple).
- `testarVencimentosContasAcademia` e `testarAlertasEngajamento` continuam públicas.
- Landing, termos e textos de preço **ainda não** foram atualizados (fase 9).

## 8. Anotações do reteste

| Data | Quem | Seção | O que aconteceu |
|---|---|---|---|
| | | | |
