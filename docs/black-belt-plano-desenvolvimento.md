# Plano Black Belt (app + web): contexto e fases de desenvolvimento

Última atualização: 26/11/2026

Roteiro para o cadastro nas lojas: [black-belt-cadastro-lojas.md](black-belt-cadastro-lojas.md)

## Objetivo

Lançar um segundo plano de assinatura, o **Black Belt** (app + web), com opções mensal,
trimestral e anual. O **Sensei PRO** atual continua à venda como plano somente app.
Cada academia assina um dos dois.

## Decisões

| Assunto | Definição | Situação |
|---|---|---|
| Estrutura | Dois planos, três períodos cada, vendidos pela Apple e pelo Google | Decidido |
| Assinante PRO atual | Não recebe o web. Se quiser, muda para o Black Belt | Decidido |
| Cadastro nas lojas | Só depois do desenvolvimento terminado | Decidido |
| Nome do novo plano | Black Belt, no padrão dos atuais: "Sensei Black Belt Mensal", "Trimestral" e "Anual" | Decidido |
| IDs | No padrão dos atuais: `br.com.senseimanager.black.mensal`, `.trimestral`, `.anual` (`blackbelt` passaria dos 40 caracteres do Google) | Decidido |
| Preços (mensal / trimestral / anual) | R$ 99,99 / R$ 229,90 / R$ 749,90 | Decidido |
| Teste de 30 dias | Libera tudo: web e sem os limites do grátis | Decidido |
| Grátis depois do teste | Sem web | Decidido |
| Anual em 12 parcelas na Apple | Não por enquanto | Decidido |
| Cupom no Android para o Black Belt | Não no lançamento; o cupom segue só no PRO mensal | Decidido |
| Limites do grátis | Manter 5 alunos, 1 turma e 1 funcionário e corrigir a landing (diz 20 alunos e 2 turmas) | Decidido |
| Quem assinou contando com o web (texto atual da landing) | Regra continua PRO sem web. Avaliar caso a caso e, quando fizer sentido, liberar por tempo definido (ex.: 6 meses) | Decidido |

## Como funciona hoje

- A assinatura é da academia e há espaço para uma só, nos campos `plano_*` do documento
  `academias/{id}`. Gravação em [iap-functions.js](../functions/iap-functions.js).
- Produtos: `br.com.senseimanager.pro.mensal`, `.trimestral` e `.anual`
  ([iap_service.dart](../mobile/lib/core/iap_service.dart)).
- O app considera Pro quando `plano_tipo >= 1`
  ([plan_service.dart](../mobile/lib/core/plan_service.dart)).
- A [reconciliação diária](../functions/iap-reconciliation.js) confere assinaturas vencidas
  há mais de 3 dias.
- O web não verifica o plano. O selo "Plano Gratuito" é fixo
  ([topbar.component.ts](../frontend-web/src/app/shared/layout/topbar/topbar.component.ts)).

## Desenho da solução

- `plano_tipo` continua como hoje (0 grátis, 1 pago), para versões antigas do app seguirem
  funcionando.
- Novo campo `acesso_web` (verdadeiro ou falso) em `academias/{id}`, gravado só pelo
  servidor conforme o produto comprado. Campo ausente significa sem web.
- Web liberado quando `acesso_web` for verdadeiro ou a academia estiver no teste.
- Liberação manual do web (exceção para um cliente) usa o campo `web_cortesia_ate`, com a
  data de validade. Em `acesso_web` ela seria sobrescrita na renovação seguinte. O web
  precisa considerar esse campo na fase 5.
- Uma assinatura ativa por academia. A compra em outra loja fica bloqueada.
- Registro separado de várias assinaturas: adiado até existir checkout no site.
- O bloqueio do web é feito principalmente na interface: app e web usam o mesmo login e o
  mesmo banco.

## Problemas encontrados na análise (por leitura do código)

1. **Troca de plano no Android:** a compra não informa a assinatura anterior. Trocar de
   plano tende a criar uma segunda assinatura. Falta confirmar com conta de teste.
2. **Uma assinatura sobrescreve a outra** nos campos da academia.
3. **Ativação sem checar dono:** `ativarAssinaturaIOS` e `ativarAssinaturaAndroid` não
   conferem se o usuário pertence à academia nem se a compra já foi usada em outra.
4. **Regras do Firestore:** a criação da academia aceita `plano_tipo: 1` vindo do cliente.
   `plano_status`, `plano_origem` e `plano_renovacao_automatica` não estão protegidos na
   edição.
5. **`testarReconciliacaoAssinaturas`** não exige autenticação no código.
6. **Outros gatilhos manuais públicos** (fora do escopo, a decidir):
   `testarVencimentosContasAcademia` e `testarAlertasEngajamento` não exigem
   autenticação.
7. **Textos divergentes:** preços e limites da landing, e "14 dias" no cadastro web contra
   30 dias nos demais textos.

## Simulação local

Tudo roda nos emuladores; os scripts recusam endereço que não seja local.

```bash
# na pasta functions
npm run emu                      # deixa os emuladores no ar (outro terminal para o resto)
npm run seed:emu                 # cria a academia e o Admin de teste
npm run cenario                  # lista os cenários
npm run cenario -- black         # aplica um cenário
npm run cenario -- pro android   # escolhe a loja (padrão: ios)

# na pasta frontend-web
npm run start:emu                # web nos emuladores

# na pasta mobile
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

Login de teste: `admin.teste@academia.com` / `admin123`. Depois de trocar de cenário,
reabra o app ou recarregue o web.

- `npm start` (sem `:emu`) continua apontando para a **produção**.
- Até as fases 4 e 5, app e web ainda não reagem a `acesso_web`: o web não verifica plano
  nenhum.
- `npm run emu` cria `functions/.secret.local` com segredos falsos, para o emulador não usar
  os reais (por exemplo, no envio de e-mail).
- Porta 8080 ocupada indica emulador que ficou aberto: encerre o processo `java` dele.

## Correções de base (fase 2)

Feitas no código, **ainda não publicadas**.

| Problema | Correção |
|---|---|
| 3: quem ativa | Só Admin, Secretaria ou Professor da própria academia ([subscription-access.js](../functions/domain/subscription-access.js)) |
| 3: compra repetida | Uma compra em uso não ativa outra academia (`already-exists`). Coleção nova `vinculos_assinatura`, acessada só pelo servidor |
| 4: regras | Academia nova só nasce com `plano_tipo` 0 ou sem o campo; `plano_status`, `plano_origem`, `plano_renovacao_automatica` e `acesso_web` protegidos |
| 5: teste de reconciliação | Exige chamada autenticada (`invoker: "private"`) |

Comportamentos a conhecer:

- Se a academia anterior não usa mais a compra (expirada, revogada ou excluída), ela passa
  para a nova. Se a anterior ainda constava como paga com data vencida, volta ao grátis com
  situação `transferido`.
- Duplicidades que já existam em produção continuam funcionando; a trava vale para vínculos
  novos.

Para publicar:

1. `firebase login --reauth` (o login desta máquina estava vencido em 26/11/2026).
2. Publicar as regras (`npm run deploy:rules`, na pasta `functions`) e as funções de
   assinatura (`ativarAssinaturaIOS`, `ativarAssinaturaAndroid`, os dois webhooks e as duas
   de reconciliação).
3. Conferir que a URL de `testarReconciliacaoAssinaturas` recusa chamada sem autenticação.
4. Testar um cadastro novo no app e no web, e "Restaurar compra" em uma conta Pro de teste.

## Servidor e regras (fase 3)

Feito no código, **ainda não publicado**.

- Produtos aceitos e regras de substituição em
  [subscription-access.js](../functions/domain/subscription-access.js).
- `acesso_web` é verdadeiro só para produtos `black`. Cancelamento e carência mantêm;
  expiração, reembolso, revogação e transferência retiram.
- `plano_transacao_em` (campo novo, Apple): transação mais antiga que a gravada é ignorada,
  inclusive reembolso do período anterior a um upgrade.
- Outra assinatura enquanto a atual está ativa e renovando não troca por plano menor, nem por
  um de mesmo nível que vença antes. A ativação responde com sucesso e o campo `ignorada`.
- Google: o token novo de uma troca assume o lugar do anterior (`linkedPurchaseToken`), pelo
  app ou pela notificação. Troca agendada mantém o plano atual até a renovação.
- Regras: sem limites do grátis durante o teste (`config/geral.trial_dias`, padrão 30);
  `criado_em`, `web_cortesia_ate` e `plano_transacao_em` protegidos.
- O app ainda aplica os limites durante o teste até a fase 4.

### Suspensão no Google

`ON_HOLD` retira o plano e o web (situação `suspenso`) e o acesso volta quando a loja
informa a assinatura ativa, conforme a
[documentação do Google](https://developer.android.com/google/play/billing/subscriptions).
Vale também para quem já assina o PRO. A carência continua com acesso. Se a notificação da
volta se perder, a reconciliação diária não revisa academias suspensas: o app tenta
restaurar ao abrir, ou a pessoa usa "Restaurar compra".

### A decidir (comportamento anterior, não alterado)

| Situação | Hoje no sistema | Segundo a loja |
|---|---|---|
| Apple em nova tentativa de cobrança sem período de carência | Mantém o acesso | A confirmar na documentação da Apple |

## App (fase 4)

Feito no código, **ainda não testado em aparelho nem publicado**.

- Catálogo e decisão de compra em [plan_catalog.dart](../mobile/lib/core/plan_catalog.dart).
- Tela de planos com seletor PRO / Black Belt. Em versão publicada, o Black Belt só aparece
  quando a loja devolve os produtos; em depuração aparece sempre.
- Android: a troca informa a assinatura atual (upgrade na hora, com crédito do tempo
  restante; downgrade e mudança de período na renovação).
- Compra bloqueada quando a academia paga pela outra loja ou por outra conta da loja, ou
  quando a conta da loja já paga uma assinatura que não é da academia.
- Teste de 30 dias libera todos os recursos; o plano passa a ser carregado também para
  Professor.
- Textos novos de "Meu plano" em português e inglês. A tela de planos continua só em
  português, como antes.
- **Publicar o servidor antes do app**: com as regras antigas, o cadastro acima do limite
  durante o teste seria recusado.

Para rodar testes e análise, usar o Flutter do FVM (`~/fvm/versions/3.44.1`).

## Fases

Marque cada item quando o critério for atendido.

- [x] **Fase 0: Decisões** (sócios). Concluída em 26/11/2026.
- [ ] **Fase 1: Ambiente de simulação** (implementada; falta conferir nas telas). Web conectado aos emuladores; script que alterna
  entre grátis, teste, PRO, Black Belt, carência e expirado; carga de dados de teste
  funcionando no Windows.
  *Pronto quando* todo cenário puder ser reproduzido sem tocar em produção.
- [x] **Fase 2: Correções de base** (falta publicar). Problemas 3, 4 e 5.
  *Pronto quando* cada correção tiver teste e o cadastro continuar funcionando no app e no
  web (ambos criam a academia com `plano_tipo: 0`).
- [x] **Fase 3: Servidor e regras** (falta publicar). Aceitar os produtos novos; controlar `acesso_web` na
  compra, renovação, troca, expiração, reembolso e reconciliação; proteger o campo; tratar
  a troca de assinatura do Google, que gera novo identificador de compra
  (`linkedPurchaseToken`); impedir que eventos de assinatura antiga alterem a atual; liberar
  os limites do grátis durante o teste nas regras, protegendo `criado_em` (senão o cliente
  estende o próprio teste) e respeitando `config/geral.trial_dias`.
  *Pronto quando* os testes cobrirem upgrade, downgrade, cancelamento, falha de cobrança e
  reembolso.
- [x] **Fase 4: App** (falta conferir em aparelho). Seletor PRO / Black Belt com três períodos; troca de plano no
  Android sem cobrança dupla; bloqueio de compra com assinatura ativa na outra loja; tela
  "Meu plano"; sem limites do grátis durante o teste (hoje [plan_limits.dart](../mobile/lib/core/plan_limits.dart)
  só olha o plano pago); textos em português e inglês.
  *Pronto quando* as telas funcionarem em cada cenário simulado.
- [ ] **Fase 5: Web.** Liberação por `acesso_web` ou teste; tela de bloqueio explicando como
  assinar ou mudar de plano; correção do selo; chave para ligar o bloqueio sem nova
  publicação.
  *Pronto quando* cada perfil vir o acesso correto, com a chave ligada e desligada.
- [ ] **Fase 6: Publicar o servidor** com o bloqueio do web desligado.
  *Pronto quando* os assinantes PRO seguirem normais.
- [ ] **Fase 7: Cadastro nas lojas**, conforme o
  [roteiro](black-belt-cadastro-lojas.md).
  *Pronto quando* os seis cadastros (três por loja) estiverem conferidos.
- [ ] **Fase 8: Testes nas lojas** com uma academia de teste: compra, upgrade, downgrade,
  cancelamento, falha de cobrança e expiração.
  *Pronto quando* tudo passar na Apple e no Google, sem cobrança dupla.
- [ ] **Fase 9: Lançamento.** Enviar app e assinaturas da Apple para revisão; publicar o app
  aprovado; avisar quem já usa o web; atualizar landing e termos (limites do grátis, dias de
  teste e web só no Black Belt); ligar o bloqueio do web.
  *Pronto quando* uma pessoa conseguir assinar o Black Belt e entrar no web.

## Cuidados

- O servidor novo precisa estar publicado **antes** de os produtos poderem ser comprados. O
  servidor atual recusa produtos que não conhece.
- O projeto Firebase configurado é o de produção. Compra de teste libera o plano de verdade
  no banco (marcada como `sandbox`): usar só academia de teste.

## Registro de alterações

| Data | O que mudou |
|---|---|
| 26/11/2026 | Fases 1 e 2 em commits locais separados (a correção de segurança é o commit `aa22873f`) |
| 26/11/2026 | Fase 3 em commit local `30d242fe` |
| 26/11/2026 | Decisão e implementação: suspensão no Google retira o acesso |
| 26/11/2026 | Fase 4: app. Verificado: 221 de 221 testes do app (28 novos), análise sem avisos novos, imagens das telas geradas em teste; servidor com 77 de 77 de assinatura, 5 de 5 de reconciliação e 67 de 67 unitários. Não verificado: compilação para Android e iOS, uso em aparelho e compras nas lojas. Sem commit |
| 26/11/2026 | Fase 3: servidor e regras. Verificado nos emuladores: assinatura 73 de 73, reconciliação 5 de 5, regras 22 de 22, exclusão de conta 4 de 4 e unitários 67 de 67. Compras das lojas simuladas; nada testado contra Apple ou Google. Não publicado |
| 26/11/2026 | Fase 2: correções de base. Verificado nos emuladores: assinatura 44 de 44, reconciliação 5 de 5, regras 17 de 17, exclusão de conta 4 de 4 e unitários 67 de 67. Um teste antigo teve o identificador de compra trocado, porque reaproveitava o de outra academia. Não publicado |
| 26/11/2026 | Decisão: preços confirmados e grátis sem web depois do teste. Fase 0 concluída |
| 26/11/2026 | Decisão: nomes e IDs seguem o padrão dos produtos atuais |
| 26/11/2026 | Fase 1: web ligado aos emuladores (`npm run start:emu`), scripts de cenários, carga de teste compatível com Windows e segredos falsos no emulador. Verificado: 67 de 67 testes unitários; 12 cenários nas duas lojas (24 aplicações) lidos com as regras ativas; web compila nas configurações de emulador e de produção, a de produção com o emulador desligado. Não verificado: telas do web e do app, e `npm run emu` completo (porta 8080 ocupada) |
| 26/11/2026 | Decisões: sem 12 parcelas e sem cupom no Black Belt; teste libera tudo; grátis segue 5/1/1; exceções de web caso a caso |
| 26/11/2026 | Análise e plano. Nenhuma alteração de código. Testes atuais executados nos emuladores: assinatura 28 de 28 e reconciliação 4 de 4 (a reconciliação em portas alternativas, porque a 8080 estava ocupada) |
