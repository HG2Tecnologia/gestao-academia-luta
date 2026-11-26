import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'auth_storage.dart';
import 'firestore_service.dart';
import 'plan_catalog.dart';
import 'plan_service.dart';

// ID do base plan de cupom criado no Play Console (Monetização > Assinaturas
// > Sensei PRO Mensal > Base plans). Precisa bater exatamente com o "ID do
// plano base" configurado lá. Academias com o campo Firestore
// `cupom_base_plan_android` igual a este valor compram automaticamente por
// esse base plan com desconto, sem aparecer como opção separada na tela de
// seleção de planos.
const kCupomBasePlanIdAndroid = 'mensal-sensei10';
const kCupomCampoFirestore = 'cupom_base_plan_android';

class IapService {
  static final IapService instance = IapService._();
  IapService._();

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  List<ProductDetails> products = [];

  // No Android, cada base plan de uma assinatura (ex.: o normal e o de
  // cupom) chega como um ProductDetails SEPARADO com o mesmo `id`, diferindo
  // só no base plan/offer interno. Guardamos a resposta completa aqui — o
  // `products` exibido na tela de planos filtra fora os base plans de cupom,
  // que nunca aparecem como opção visível.
  List<ProductDetails> _todosOsProdutos = [];

  bool storeAvailable = false;
  bool _ready = false;

  void Function(bool success, String? error)? onPurchaseResult;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;

    storeAvailable = await _iap.isAvailable();
    if (!storeAvailable) return;

    _sub ??= _iap.purchaseStream.listen(_handlePurchases, onError: (_) {});

    // Produto ainda não criado na loja só volta em `notFoundIDs`.
    final response = await _iap.queryProductDetails({
      for (final p in kCatalogo) p.id,
    });
    _todosOsProdutos = response.productDetails;
    products = _todosOsProdutos.where((p) => !_ehBasePlanDeCupom(p)).toList();
  }

  bool _ehBasePlanDeCupom(ProductDetails p) {
    if (p is! GooglePlayProductDetails) return false;
    final idx = p.subscriptionIndex;
    final offers = p.productDetails.subscriptionOfferDetails;
    if (idx == null || offers == null || idx >= offers.length) return false;
    return offers[idx].basePlanId == kCupomBasePlanIdAndroid;
  }

  // Assinaturas vigentes na conta da loja deste aparelho, e (no Android) a
  // compra original de cada uma, exigida pela Google para trocar de plano.
  final Map<String, GooglePlayPurchaseDetails> _comprasAndroid = {};

  /// `null` quando a loja não pôde ser consultada.
  Future<List<AssinaturaNoAparelho>?> _assinaturasNoAparelho() async {
    try {
      if (Platform.isAndroid) {
        final resposta = await _iap
            .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
            .queryPastPurchases();
        if (resposta.error != null) return null;
        _comprasAndroid.clear();
        final assinaturas = <AssinaturaNoAparelho>[];
        for (final compra in resposta.pastPurchases) {
          if (produtoPorId(compra.productID) == null) continue;
          final token = compra.verificationData.serverVerificationData;
          _comprasAndroid[token] = compra;
          assinaturas.add(
            AssinaturaNoAparelho(
              compraId: token,
              produtoId: compra.productID,
              renova: compra.billingClientPurchase.isAutoRenewing,
            ),
          );
        }
        return assinaturas;
      }
      if (Platform.isIOS) {
        // Vem o histórico inteiro: fica só a transação mais recente de cada
        // assinatura que ainda não venceu.
        final recentes = <String, SK2Transaction>{};
        for (final t in await SK2Transaction.transactions()) {
          if (produtoPorId(t.productId) == null) continue;
          final anterior = recentes[t.originalId];
          if (anterior == null ||
              t.purchaseDate.compareTo(anterior.purchaseDate) > 0) {
            recentes[t.originalId] = t;
          }
        }
        final agora = DateTime.now();
        return [
          for (final t in recentes.values)
            if (DateTime.tryParse(t.expirationDate ?? '')?.isAfter(agora) ??
                false)
              AssinaturaNoAparelho(
                compraId: t.originalId,
                produtoId: t.productId,
              ),
        ];
      }
    } catch (_) {}
    return null;
  }

  /// O que acontece se a academia comprar [product] neste aparelho. Chamar
  /// antes de [comprar] e não comprar quando vier [CompraBloqueada].
  Future<DecisaoCompra> avaliar(ProductDetails product) async {
    await PlanService.instance.refresh();
    return decidirCompra(
      produtoId: product.id,
      loja: Platform.isIOS ? 'ios' : 'android',
      situacao: PlanService.instance.situacao,
      noAparelho: await _assinaturasNoAparelho(),
    );
  }

  Future<void> comprar(ProductDetails product, DecisaoCompra decisao) async {
    assert(decisao is! CompraBloqueada);
    PurchaseParam parametros = PurchaseParam(productDetails: product);
    if (product is GooglePlayProductDetails) {
      ChangeSubscriptionParam? troca;
      // Na Apple a troca é automática dentro do grupo de assinaturas. No
      // Google, sem informar a compra atual, nasce uma segunda assinatura.
      if (decisao is TrocaDePlano) {
        final atual = _comprasAndroid[decisao.compraAtualId];
        if (atual == null) {
          throw StateError('Assinatura atual não encontrada na loja.');
        }
        troca = ChangeSubscriptionParam(
          oldPurchaseDetails: atual,
          replacementMode: decisao.modo == ModoTroca.imediata
              ? ReplacementMode.withTimeProration
              : ReplacementMode.deferred,
        );
      }
      parametros = GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: await _offerTokenCupomElegivel(product),
        changeSubscriptionParam: troca,
      );
    }
    final abriu = await _iap.buyNonConsumable(purchaseParam: parametros);
    if (!abriu) {
      onPurchaseResult?.call(false, 'Não foi possível abrir a loja.');
    }
  }

  // Numa troca agendada, o Google pode avisar o sucesso sem enviar a compra.
  // Ela é buscada na loja para o servidor registrar o token novo.
  Future<void> _concluirTrocaSemCompra() async {
    await _assinaturasNoAparelho();
    if (_comprasAndroid.isEmpty) {
      onPurchaseResult?.call(true, null);
      return;
    }
    for (final compra in _comprasAndroid.values.toList()) {
      await _ativarBackend(compra);
    }
  }

  // Elegibilidade é decidida só pelo nosso Firestore (campo
  // `cupom_base_plan_android` na academia) — o Google nunca filtra isso
  // sozinho. Sem esse campo, compra segue 100% o fluxo normal de sempre.
  Future<String?> _offerTokenCupomElegivel(ProductDetails product) async {
    if (!Platform.isAndroid || product.id != kIapMensal) return null;

    final user = await AuthStorage.getUser();
    final academiaId = user?.academiaId;
    if (academiaId == null) return null;

    final academia = await firestoreService.getAcademia(academiaId);
    final temCupom = academia?[kCupomCampoFirestore] == kCupomBasePlanIdAndroid;
    if (!temCupom) return null;

    final produtoComCupom = _todosOsProdutos.firstWhere(
      (p) => p.id == kIapMensal && _ehBasePlanDeCupom(p),
      orElse: () => product,
    );
    if (produtoComCupom is! GooglePlayProductDetails) return null;

    final idx = produtoComCupom.subscriptionIndex;
    final offers = produtoComCupom.productDetails.subscriptionOfferDetails;
    if (idx == null || offers == null || idx >= offers.length) return null;
    return offers[idx].offerIdToken;
  }

  Future<void> restaurar() async => _iap.restorePurchases();

  void resetar() => _ready = false;

  void _handlePurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (Platform.isAndroid &&
              p.verificationData.serverVerificationData.isEmpty) {
            _concluirTrocaSemCompra();
          } else {
            _ativarBackend(p);
          }
        case PurchaseStatus.error:
          onPurchaseResult?.call(false, p.error?.message ?? 'Erro desconhecido.');
        case PurchaseStatus.canceled:
          onPurchaseResult?.call(false, null);
        default:
          break;
      }
      if (p.pendingCompletePurchase) _iap.completePurchase(p);
    }
  }

  // A ativação do Pro é sempre validada no servidor (ativarAssinaturaIOS /
  // ativarAssinaturaAndroid) antes de qualquer campo de plano ser gravado —
  // o app nunca escreve isso direto no Firestore. Isso evita tanto compras
  // de sandbox/teste quanto gravação manual indevida serem confundidas com
  // assinatura real (as regras do Firestore também bloqueiam escrita direta
  // desses campos pelo cliente, como segunda camada).
  Future<void> _ativarBackend(PurchaseDetails purchase) async {
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user?.academiaId;
      if (academiaId == null) throw Exception('Academia não identificada');

      if (Platform.isIOS) {
        await FirebaseFunctions.instance.httpsCallable('ativarAssinaturaIOS').call({
          'academiaId': academiaId,
          'jwsTransaction': purchase.verificationData.serverVerificationData,
        });
      } else if (Platform.isAndroid) {
        await FirebaseFunctions.instance.httpsCallable('ativarAssinaturaAndroid').call({
          'academiaId': academiaId,
          'purchaseToken': purchase.verificationData.serverVerificationData,
        });
      } else {
        throw Exception('Plataforma sem validação de compra configurada.');
      }
      onPurchaseResult?.call(true, null);
    } on FirebaseFunctionsException catch (e) {
      onPurchaseResult?.call(
        false,
        e.message ?? 'Não foi possível validar sua compra junto à loja.',
      );
    } catch (_) {
      onPurchaseResult?.call(
        false,
        'Compra confirmada, mas erro ao ativar. Entre em contato com o suporte.',
      );
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
