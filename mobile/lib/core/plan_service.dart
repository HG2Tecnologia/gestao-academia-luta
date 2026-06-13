import 'api_client.dart';

class PlanService {
  static final PlanService instance = PlanService._();
  PlanService._();

  String _planoTipo = 'Gratuito';
  DateTime? _planoExpiracao;
  DateTime? _criadoEm;
  bool _loaded = false;

  bool get isPro {
    if (_planoTipo != 'Pro') return false;
    final exp = _planoExpiracao;
    return exp == null || exp.isAfter(DateTime.now());
  }

  bool get isInTrial {
    if (isPro) return false;
    final criado = _criadoEm;
    if (criado == null) return false;
    return DateTime.now().difference(criado).inDays < 7;
  }

  bool get showAds => !isPro && !isInTrial;

  int get daysLeftInTrial {
    final criado = _criadoEm;
    if (criado == null) return 0;
    final diff = 7 - DateTime.now().difference(criado).inDays;
    return diff.clamp(0, 7);
  }

  Future<void> load() async {
    try {
      final res = await dio.get('/api/academia');
      final d = res.data['dados'] as Map<String, dynamic>? ?? {};
      _planoTipo = d['planoTipo']?.toString() ?? 'Gratuito';
      final expStr = d['planoExpiracao']?.toString();
      _planoExpiracao = expStr != null ? DateTime.tryParse(expStr) : null;
      final criadoStr = d['criadoEm']?.toString();
      _criadoEm = criadoStr != null ? DateTime.tryParse(criadoStr) : null;
      _loaded = true;
    } catch (_) {}
  }

  Future<void> refresh() async {
    _loaded = false;
    await load();
  }

  void reset() {
    _loaded = false;
    _planoTipo = 'Gratuito';
    _planoExpiracao = null;
    _criadoEm = null;
  }

  bool get isLoaded => _loaded;

  String get planDisplayName {
    if (isPro) return 'Sensei PRO';
    if (isInTrial) return 'Trial Gratuito';
    return 'Plano Gratuito';
  }
}
