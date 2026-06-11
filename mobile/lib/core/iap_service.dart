import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'api_client.dart';

const kIapMensal = 'br.com.senseimanager.pro.mensal';
const kIapTrimestral = 'br.com.senseimanager.pro.trimestral';
const kIapAnual = 'br.com.senseimanager.pro.anual';

const _kProductIds = {kIapMensal, kIapTrimestral, kIapAnual};

class IapService {
  static final IapService instance = IapService._();
  IapService._();

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  List<ProductDetails> products = [];
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
    products = List.of(response.productDetails)
      ..sort((a, b) => _order(a.id).compareTo(_order(b.id)));
  }

  int _order(String id) {
    if (id == kIapMensal) return 0;
    if (id == kIapTrimestral) return 1;
    return 2;
  }

  Future<void> comprar(ProductDetails product) async {
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
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

  Future<void> _ativarBackend(PurchaseDetails purchase) async {
    try {
      final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
      await dio.post('/api/academia/plano/iap', data: {
        'productId': purchase.productID,
        'purchaseToken': purchase.verificationData.serverVerificationData,
        'platform': platform,
      });
      onPurchaseResult?.call(true, null);
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
