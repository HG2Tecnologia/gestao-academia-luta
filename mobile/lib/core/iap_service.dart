import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'auth_storage.dart';
import 'firestore_service.dart';

const kIapMensal = 'br.com.senseimanager.pro.mensal';
const kIapTrimestral = 'br.com.senseimanager.pro.trimestral';
const kIapAnual = 'br.com.senseimanager.pro.anual';

const _kProductIds = {kIapMensal, kIapTrimestral, kIapAnual};

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

    final response = await _iap.queryProductDetails(_kProductIds);
    _todosOsProdutos = response.productDetails;
    products = _todosOsProdutos.where((p) => !_ehBasePlanDeCupom(p)).toList()
      ..sort((a, b) => _order(a.id).compareTo(_order(b.id)));
  }

  int _order(String id) {
    if (id == kIapMensal) return 0;
    if (id == kIapTrimestral) return 1;
    return 2;
  }

  bool _ehBasePlanDeCupom(ProductDetails p) {
    if (p is! GooglePlayProductDetails) return false;
    final idx = p.subscriptionIndex;
    final offers = p.productDetails.subscriptionOfferDetails;
    if (idx == null || offers == null || idx >= offers.length) return false;
    return offers[idx].basePlanId == kCupomBasePlanIdAndroid;
  }

  Future<void> comprar(ProductDetails product) async {
    final offerToken = await _offerTokenCupomElegivel(product);
    if (offerToken != null && product is GooglePlayProductDetails) {
      await _iap.buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: product,
          offerToken: offerToken,
        ),
      );
      return;
    }
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
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
          _ativarBackend(p);
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
