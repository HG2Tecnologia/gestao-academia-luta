import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

class AdService {
  static final AdService instance = AdService._();
  AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitial;
  bool _interstitialReady = false;
  DateTime? _lastInterstitialShown;

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _loadInterstitial();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: kAdInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _interstitialReady = false;
              _interstitial = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (_, __) {
              _interstitialReady = false;
              _interstitial = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _interstitialReady = false;
        },
      ),
    );
  }

  /// Shows interstitial at most once every 5 minutes.
  bool showInterstitial() {
    if (!_interstitialReady || _interstitial == null) return false;
    final now = DateTime.now();
    final last = _lastInterstitialShown;
    if (last != null && now.difference(last).inMinutes < 5) return false;
    _lastInterstitialShown = now;
    _interstitial!.show();
    return true;
  }

  BannerAd createBanner({required void Function() onLoaded}) {
    final banner = BannerAd(
      adUnitId: kAdBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(onAdLoaded: (_) => onLoaded()),
    );
    banner.load();
    return banner;
  }
}
