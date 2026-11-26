/// Catálogo dos planos pagos e a decisão de compra. Sem Flutter nem plugins,
/// para poder ser testado. Os IDs precisam bater com
/// `functions/domain/subscription-access.js` e com as duas lojas.
library;

const kIapMensal = 'br.com.senseimanager.pro.mensal';
const kIapTrimestral = 'br.com.senseimanager.pro.trimestral';
const kIapAnual = 'br.com.senseimanager.pro.anual';
const kIapBlackMensal = 'br.com.senseimanager.black.mensal';
const kIapBlackTrimestral = 'br.com.senseimanager.black.trimestral';
const kIapBlackAnual = 'br.com.senseimanager.black.anual';

/// A ordem importa: o índice maior é o plano superior.
enum NivelPlano {
  pro('Sensei PRO'),
  blackBelt('Sensei Black Belt');

  const NivelPlano(this.nome);
  final String nome;
}

enum Periodo {
  mensal('Mensal', 1),
  trimestral('Trimestral', 3),
  anual('Anual', 12);

  const Periodo(this.nome, this.meses);
  final String nome;
  final int meses;
}

class ProdutoPlano {
  const ProdutoPlano(this.id, this.nivel, this.periodo, this.precoReserva);

  final String id;
  final NivelPlano nivel;
  final Periodo periodo;

  /// Mostrado só quando a loja não informa o preço em reais.
  final double precoReserva;
}

const kCatalogo = [
  ProdutoPlano(kIapMensal, NivelPlano.pro, Periodo.mensal, 69.99),
  ProdutoPlano(kIapTrimestral, NivelPlano.pro, Periodo.trimestral, 149.90),
  ProdutoPlano(kIapAnual, NivelPlano.pro, Periodo.anual, 499.90),
  ProdutoPlano(kIapBlackMensal, NivelPlano.blackBelt, Periodo.mensal, 99.99),
  ProdutoPlano(
    kIapBlackTrimestral,
    NivelPlano.blackBelt,
    Periodo.trimestral,
    229.90,
  ),
  ProdutoPlano(kIapBlackAnual, NivelPlano.blackBelt, Periodo.anual, 749.90),
];

ProdutoPlano? produtoPorId(String? id) {
  for (final p in kCatalogo) {
    if (p.id == id) return p;
  }
  return null;
}

ProdutoPlano produtoDe(NivelPlano nivel, Periodo periodo) => kCatalogo
    .firstWhere((p) => p.nivel == nivel && p.periodo == periodo);

/// Economia (em %) do período em relação a pagar o mensal pelo mesmo tempo.
int descontoPercentual({
  required double precoPeriodo,
  required double precoMensal,
  required int meses,
}) {
  if (precoMensal <= 0 || meses <= 1) return 0;
  final cheio = precoMensal * meses;
  final desconto = ((1 - precoPeriodo / cheio) * 100).round();
  return desconto > 0 ? desconto : 0;
}

// ─── Decisão de compra ───────────────────────────────────────────────────────

/// O que a academia tem hoje, lido do Firestore.
class SituacaoPlano {
  const SituacaoPlano({
    required this.pago,
    this.origem,
    this.plataforma,
    this.produtoId,
    this.compraId,
    this.renovacaoAutomatica = true,
  });

  final bool pago;
  final String? origem;
  final String? plataforma;
  final String? produtoId;

  /// `plano_original_transaction_id`: o `originalTransactionId` da Apple ou o
  /// token de compra do Google.
  final String? compraId;
  final bool renovacaoAutomatica;
}

/// Assinatura vigente encontrada na conta da loja deste aparelho.
class AssinaturaNoAparelho {
  const AssinaturaNoAparelho({
    required this.compraId,
    required this.produtoId,
    this.renova = true,
  });

  final String compraId;
  final String produtoId;
  final bool renova;
}

enum ModoTroca { imediata, noProximoCiclo }

enum MotivoBloqueio {
  /// Já assina exatamente este produto.
  planoAtual,

  /// A academia paga pela outra loja: comprar aqui geraria duas cobranças.
  assinaturaEmOutraLoja,

  /// A assinatura da academia está em outra conta desta mesma loja.
  assinaturaEmOutraConta,

  /// A conta da loja já paga uma assinatura que não é a desta academia.
  contaDaLojaJaAssina,
}

sealed class DecisaoCompra {
  const DecisaoCompra();
}

class CompraNova extends DecisaoCompra {
  const CompraNova();
}

class TrocaDePlano extends DecisaoCompra {
  const TrocaDePlano({required this.compraAtualId, required this.modo});

  final String compraAtualId;
  final ModoTroca modo;
}

class CompraBloqueada extends DecisaoCompra {
  const CompraBloqueada(this.motivo);

  final MotivoBloqueio motivo;
}

/// Subir de nível vale na hora; descer ou só mudar o período vale na próxima
/// renovação (mesmo comportamento dos níveis configurados na Apple).
ModoTroca modoDeTroca(String produtoAtual, String produtoNovo) {
  final atual = produtoPorId(produtoAtual)?.nivel.index ?? 0;
  final novo = produtoPorId(produtoNovo)?.nivel.index ?? 0;
  return novo > atual ? ModoTroca.imediata : ModoTroca.noProximoCiclo;
}

/// [loja] é `ios` ou `android`. [noAparelho] é `null` quando não foi possível
/// consultar a loja: nesse caso só valem as checagens feitas com os dados da
/// academia.
DecisaoCompra decidirCompra({
  required String produtoId,
  required String loja,
  required SituacaoPlano situacao,
  List<AssinaturaNoAparelho>? noAparelho,
}) {
  final s = situacao;
  final deLoja =
      s.pago &&
      s.origem != 'cortesia' &&
      s.origem != 'manual' &&
      (s.plataforma == 'ios' || s.plataforma == 'android');
  final renovando = deLoja && s.renovacaoAutomatica;

  if (renovando && s.plataforma != loja) {
    return const CompraBloqueada(MotivoBloqueio.assinaturaEmOutraLoja);
  }
  if (renovando && s.produtoId == produtoId) {
    return const CompraBloqueada(MotivoBloqueio.planoAtual);
  }
  if (noAparelho == null) return const CompraNova();

  final renovandoNoAparelho = noAparelho.where((a) => a.renova).toList();
  AssinaturaNoAparelho? daAcademia;
  for (final a in noAparelho) {
    if (a.compraId == s.compraId) daAcademia = a;
  }
  // Ativações antigas não gravaram o identificador: com uma única assinatura no
  // aparelho, ela é a da academia.
  if (daAcademia == null &&
      s.compraId == null &&
      renovando &&
      renovandoNoAparelho.length == 1) {
    daAcademia = renovandoNoAparelho.single;
  }

  if (daAcademia != null) {
    if (daAcademia.produtoId == produtoId) return const CompraNova();
    return TrocaDePlano(
      compraAtualId: daAcademia.compraId,
      modo: modoDeTroca(daAcademia.produtoId, produtoId),
    );
  }
  if (renovando) {
    return const CompraBloqueada(MotivoBloqueio.assinaturaEmOutraConta);
  }
  if (renovandoNoAparelho.isNotEmpty) {
    return const CompraBloqueada(MotivoBloqueio.contaDaLojaJaAssina);
  }
  return const CompraNova();
}
