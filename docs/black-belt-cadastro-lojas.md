# Cadastro do plano Black Belt na App Store e no Google Play

Roteiro para ser executado com o Claude no Chrome, com uma pessoa acompanhando.
Última atualização: 26/11/2026

## Antes de começar

Não execute nenhum passo enquanto houver item desmarcado. Quem marca é a pessoa
responsável, não o assistente.

- [ ] Desenvolvimento concluído e **servidor novo publicado**. Data: ____
- [x] Nomes, IDs e **preços** abaixo confirmados. Data: 26/11/2026
- [ ] **Captura da tela de planos** do app novo salva no computador (exigida pela Apple)
- [ ] Acesso à conta no App Store Connect e no Play Console

## Instruções para o assistente

Contexto: o app Sensei Manager já vende o plano **Sensei PRO** (somente app). Será criado o
plano **Black Belt** (app + web), com três períodos, nas duas lojas.

| Dado | Valor |
|---|---|
| Pacote / Bundle ID | `br.com.hg2tecnologia.senseimanager` |
| Apple ID do app | `6777092562` |
| App Store Connect | https://appstoreconnect.apple.com |
| Play Console | https://play.google.com/console |

Regras:

1. **Não altere nem exclua nada do Sensei PRO** (produtos, preços, IDs, ofertas, cupom). A
   única mudança permitida é a posição nos níveis da Apple, descrita no passo A3, e somente
   após confirmação.
2. **Não envie nada para revisão** na Apple.
3. **Não ative planos básicos** no Google. A ativação é a Parte C, feita só a pedido.
4. Antes de salvar cada ID, mostre o texto digitado e espere confirmação. IDs não podem ser
   alterados nem reutilizados.
5. Não mexa em contratos, dados bancários, impostos, usuários, chaves de API ou
   configuração de notificações.
6. Se a tela for diferente do descrito, se um valor não estiver disponível ou se algum
   produto já existir, **pare e pergunte**.
7. Ao final, entregue o relatório da seção "Conferência final".

## Produtos a criar

| Nome | ID do produto (igual nas duas lojas) | Duração | Preço no Brasil |
|---|---|---|---|
| Sensei Black Belt Mensal | `br.com.senseimanager.black.mensal` | 1 mês | R$ 99,99 |
| Sensei Black Belt Trimestral | `br.com.senseimanager.black.trimestral` | 3 meses | R$ 229,90 |
| Sensei Black Belt Anual | `br.com.senseimanager.black.anual` | 1 ano | R$ 749,90 |

Os nomes seguem o padrão dos atuais ("Sensei PRO Mensal"). No levantamento (A1 e B1), se
os nomes do Sensei PRO na loja seguirem outro formato, mostre e pergunte antes de criar.

Textos em português (Brasil):

- Descrição dos três: `App e web para gerir sua academia`

Se o Sensei PRO também tiver textos em inglês, adicione:

| Nome | Descrição |
|---|---|
| Sensei Black Belt Monthly | `App and web to manage your academy` |
| Sensei Black Belt Quarterly | `App and web to manage your academy` |
| Sensei Black Belt Yearly | `App and web to manage your academy` |

## Parte A: Apple (App Store Connect)

**A1. Levantamento.** Abra o app, em Monetização > Assinaturas. Anote e mostre:
nome do grupo de assinatura; se os três produtos `br.com.senseimanager.pro.*` estão no mesmo
grupo; o nível de cada um; países disponíveis; idiomas cadastrados; se o anual tem a opção
mensal com compromisso de 12 meses. Se os três não estiverem no mesmo grupo, pare.

**A2. Criação.** No **mesmo grupo** do Sensei PRO, crie os três produtos. Em cada um:

- nome de referência igual ao nome da tabela;
- ID do produto e duração da tabela;
- preço base no Brasil;
- disponibilidade igual à do Sensei PRO;
- nome de exibição e descrição;
- captura da tela de planos (a pessoa faz o envio do arquivo, se necessário);
- notas para a revisão:
  `Black Belt includes everything in Sensei PRO plus access to the web management system for the same academy account. To find it: sign in as an academy administrator and open the plans screen.`

No anual, **não** ative a opção de pagamento mensal com compromisso de 12 meses (decisão dos
sócios).

**A3. Níveis.** Mostre a ordem atual e a proposta, e **peça confirmação antes de salvar**:

| Nível | Produtos |
|---|---|
| 1 (superior) | Os três Black Belt |
| 2 | Os três Sensei PRO |

Se os produtos do Sensei PRO estiverem hoje em níveis diferentes entre si, pare e pergunte:
juntá-los muda o comportamento das trocas de período.

**A4.** Confirme que os três aparecem como prontos para envio, sem dados faltando.
**Não envie para revisão.**

## Parte B: Google (Play Console)

**B1. Levantamento.** Abra o app, em Monetizar > Assinaturas. Anote e mostre, para cada
assinatura do Sensei PRO: ID, planos básicos, período, preço, países, período de carência,
suspensão de conta, configuração de troca de plano ou nova assinatura, e ofertas existentes
(há um plano básico de cupom, `mensal-sensei10`, no PRO mensal).

**B2. Criação.** Crie três assinaturas com os IDs e nomes da tabela. Em cada uma, um plano
básico de **renovação automática**:

| Assinatura | ID do plano básico | Período de cobrança |
|---|---|---|
| Sensei Black Belt Mensal | `mensal` | Mensal |
| Sensei Black Belt Trimestral | `trimestral` | A cada 3 meses |
| Sensei Black Belt Anual | `anual` | Anual |

- preço no Brasil conforme a tabela;
- países, carência, suspensão de conta e demais opções iguais às do Sensei PRO equivalente;
- **salve como rascunho. Não clique em Ativar.**

Não crie ofertas nem cupom.

## Conferência final

Entregue uma tabela com os seis cadastros: loja, nome, ID, período, preço, estado e, na
Apple, o nível. Liste também tudo o que ficou pendente ou diferente deste roteiro.

## Parte C: Depois do cadastro (somente a pedido)

1. **Testes:** ativar os três planos básicos no Google. Na Apple, os testes em Sandbox usam
   os produtos prontos para envio.
2. **Lançamento:** depois que todos os testes passarem, enviar as três assinaturas da Apple
   para revisão junto com a versão nova do app.

Plano completo e situação do projeto:
[black-belt-plano-desenvolvimento.md](black-belt-plano-desenvolvimento.md)
