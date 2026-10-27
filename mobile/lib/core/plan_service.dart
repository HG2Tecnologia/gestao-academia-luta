import 'auth_storage.dart';
import 'firestore_service.dart';
import 'iap_service.dart';

String? planoProdutoDisplayName(String? produtoId) {
  switch (produtoId) {
    case kIapMensal:
      return 'Mensal';
    case kIapTrimestral:
      return 'Trimestral';
    case kIapAnual:
      return 'Anual';
    default:
      return null;
  }
}

class PlanService {
  static final PlanService instance = PlanService._();
  PlanService._();

  String _planoTipo = 'Gratuito';
  DateTime? _planoExpiracao;
  DateTime? _criadoEm;
  DateTime? _planoAssinadoEm;
  String? _planoProdutoId;
  String? _planoPlataforma;
  String? _planoStatus;
  bool? _planoRenovacaoAutomatica;
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

  DateTime? get planoExpiracao => _planoExpiracao;
  DateTime? get planoAssinadoEm => _planoAssinadoEm;
  String? get planoProdutoId => _planoProdutoId;
  String? get planoPlataforma => _planoPlataforma;
  String? get planoStatus => _planoStatus;
  bool? get planoRenovacaoAutomatica => _planoRenovacaoAutomatica;

  Future<void> load() async {
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user?.academiaId;
      if (academiaId == null) return;
      final d = await firestoreService.getAcademia(academiaId) ?? {};
      // plano_tipo: 0=Gratuito, 1=Pro
      final planoNum = d['plano_tipo'] as int? ?? 0;
      _planoTipo = planoNum >= 1 ? 'Pro' : 'Gratuito';
      final expStr = d['plano_expiracao']?.toString();
      _planoExpiracao = expStr != null ? DateTime.tryParse(expStr) : null;
      final criadoStr = d['criado_em']?.toString();
      _criadoEm = criadoStr != null ? DateTime.tryParse(criadoStr) : null;
      final assinadoStr = d['plano_assinado_em']?.toString();
      _planoAssinadoEm = assinadoStr != null
          ? DateTime.tryParse(assinadoStr)
          : null;
      _planoProdutoId = d['plano_produto_id']?.toString();
      _planoPlataforma = d['plano_plataforma']?.toString();
      _planoStatus = d['plano_status']?.toString();
      _planoRenovacaoAutomatica = d['plano_renovacao_automatica'] as bool?;
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
    _planoAssinadoEm = null;
    _planoProdutoId = null;
    _planoPlataforma = null;
    _planoStatus = null;
    _planoRenovacaoAutomatica = null;
  }

  bool get isLoaded => _loaded;

  String get planDisplayName {
    if (isPro) return 'Sensei PRO';
    if (isInTrial) return 'Trial Gratuito';
    return 'Plano Gratuito';
  }
}
