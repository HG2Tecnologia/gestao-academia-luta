# Parcelamento (12x) do Sensei PRO — como funciona hoje

## Resumo

A Apple tem um recurso chamado **"Assinaturas mensais com compromisso de 12 meses"**
(lançado em abril/maio de 2026). Ele permite que uma assinatura anual seja paga em
12 parcelas mensais em vez de uma cobrança única à vista.

**Esse recurso está ativo hoje apenas no Sensei PRO Anual.** Não existe equivalente
para o Mensal nem para o Trimestral — a Apple não oferece parcelamento para
assinaturas com duração menor que 1 ano.

## Onde cada produto está hoje (App Store Connect, confirmado em 26/10/2026)

| Produto | ID | Disponibilidade |
|---|---|---|
| Sensei PRO Mensal | `br.com.senseimanager.pro.mensal` | Só "padrão" (sem parcelamento) |
| Sensei PRO Trimestral | `br.com.senseimanager.pro.trimestral` | Só "padrão" (sem parcelamento) |
| Sensei PRO Anual | `br.com.senseimanager.pro.anual` | **"1 ano antecipado"** + **"Mensal com compromisso de 12 meses"** |

## Como o cliente acessa o parcelamento

**Não é possível oferecer essa escolha dentro do nosso app.** Verificado em
26/10/2026: o plugin Flutter que usamos para IAP no iOS (`in_app_purchase_storekit`,
hoje na v0.4.10, confirmado também na versão mais recente disponível, v0.4.15) não
tem nenhuma API para selecionar um "billing plan" (à vista vs. parcelado) no momento
da compra. Isso é esperado — é um recurso muito recente da Apple e os plugins Flutter
costumam demorar meses para dar suporte a APIs novas do StoreKit.

Hoje, a única forma de o cliente escolher parcelado é:
1. Assinar o Sensei PRO Anual pelo nosso app normalmente (sempre vai cobrar à vista).
2. Depois, ir em **Ajustes do iPhone → [nome do usuário] → Assinaturas → Sensei PRO**
   e trocar para a opção "Mensal com compromisso de 12 meses" por lá — essa é a tela
   nativa da Apple, fora do nosso controle.

Nota importante sobre o compromisso: ao escolher o parcelamento, o cliente assume um
compromisso de pagamento das 12 parcelas. Cancelar a renovação automática não encerra
as parcelas já em andamento — segundo a documentação de terceiros consultada (não há
confirmação direta na documentação oficial da Apple), o cliente continua sendo cobrado
até completar o compromisso, exceto em certas regiões. O valor total parcelado também
é, por regra da própria Apple, sempre maior que o valor à vista (entre 1x e 1,5x) —
isso é esperado, não é erro de cobrança.

## Caso relatado (outubro/2026)

Um cliente relatou ter selecionado "Mensal com compromisso de 12 meses" na tela
nativa da Apple, mas foi cobrado o valor integral à vista (R$499,90) em uma única
transação, em vez de iniciar as 12 parcelas de R$49,90. Investigamos e confirmamos
que:

- A tela que ele usou é 100% nativa da Apple (nosso paywall no app tem só 3 opções
  fixas e não dá acesso a esse seletor).
- O backend (`functions/iap-functions.js`) não tem lógica própria de cálculo de
  parcelamento — ele apenas lê e confia na data de expiração (`expiresDate`) que a
  Apple manda assinada em cada evento de transação. Não identificamos nenhuma causa
  do nosso lado para a cobrança ter saído diferente do que o cliente selecionou.
- **Conclusão: possível bug/inconsistência do lado da Apple.** Não há nada a corrigir
  no nosso código ou configuração para esse caso.

## O que fazer quando isso acontecer de novo

1. Orientar o cliente a usar o botão **"Reportar problema"** no recibo da compra
   (app Wallet/extrato do cartão → detalhe da cobrança da Apple, ou
   reportaproblem.apple.com).
2. Internamente, também vale abrir um caso de suporte para desenvolvedores no App
   Store Connect (Contact Us / Developer Support), descrevendo a divergência entre
   plano selecionado e cobrança efetivada — para a Apple investigar se é um problema
   de configuração ou bug de plataforma que pode estar afetando outros clientes.
3. Pedido de reembolso ("estorno") é sempre decidido exclusivamente pela Apple,
   caso a caso — não temos nenhuma ação própria para aprovar/negar. Quando a Apple
   aprova um reembolso, o webhook `webhookAppStoreNotifications`
   (`functions/iap-functions.js`) já revoga o Pro automaticamente via o evento
   `REFUND`/`REVOKE`, uma vez implantado e registrado no App Store Connect.

## Trabalho futuro em aberto (não iniciado)

- Reavaliar se o parcelamento deve ser estendido ao Trimestral: hoje a Apple não
  oferece essa opção para assinaturas < 1 ano, então isso dependeria de a Apple
  adicionar suporte no futuro.
- Acompanhar o changelog do `in_app_purchase_storekit` por suporte a seleção de
  billing plan no momento da compra, para eventualmente oferecer essa escolha
  direto no nosso paywall.
- Google Play tem um recurso próprio e independente de parcelamento ("installments"),
  disponível para compradores no Brasil, França, Itália e Espanha — mas é uma
  configuração separada no Play Console, não herda nada do que foi feito na Apple.
  Ainda não avaliado/implementado.
