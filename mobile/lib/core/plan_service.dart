import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? _planoOrigem;
  bool? _planoRenovacaoAutomatica;
  bool _loaded = false;

  static const int _trialDurationDaysPadrao = 30;
  int _trialDurationDays = _trialDurationDaysPadrao;

  bool get isPro {
    if (_planoTipo != 'Pro') return false;
    // Período de carência (Apple/Google tentando cobrar a renovação de
    // novo, depois de uma falha) é, por definição, um estado em que a loja
    // ainda considera o assinante ativo — é pra isso que o período existe.
    // A data em `plano_expiracao` é a da assinatura ANTERIOR e já passou
    // nesse momento (senão não haveria renovação pra tentar); se
    // exigíssemos ela também, todo cliente em carência cairia pra
    // "Gratuito" bem no meio da tentativa de cobrança da própria loja.
    // Sai desse estado só quando a loja manda `DID_RENEW` (volta a
    // 'ativo' com expiração nova) ou `GRACE_PERIOD_EXPIRED`/reembolso
    // (derruba pra Gratuito de verdade) — nunca por passagem de tempo
    // aqui no cliente.
    if (_planoStatus == 'periodo_carencia') return true;
    final exp = _planoExpiracao;
    return exp == null || exp.isAfter(DateTime.now());
  }

  /// Hoje 30 dias fixos no código; se `config/geral.trial_dias` existir no
  /// Firestore, prevalece — dá pra mudar o prazo sem publicar versão nova.
  int get trialDurationDays => _trialDurationDays;

  bool get isInTrial {
    if (isPro) return false;
    final criado = _criadoEm;
    if (criado == null) return false;
    return DateTime.now().difference(criado).inDays < trialDurationDays;
  }

  bool get showAds => !isPro && !isInTrial;

  int get daysLeftInTrial {
    final criado = _criadoEm;
    if (criado == null) return 0;
    final diff = trialDurationDays - DateTime.now().difference(criado).inDays;
    return diff.clamp(0, trialDurationDays);
  }

  DateTime? get planoExpiracao => _planoExpiracao;
  DateTime? get planoAssinadoEm => _planoAssinadoEm;
  String? get planoProdutoId => _planoProdutoId;
  String? get planoPlataforma => _planoPlataforma;
  String? get planoStatus => _planoStatus;
  // "loja" | "cortesia" | "manual" — de onde veio o Pro desta academia.
  // Academias antigas (antes dessa migração) podem vir sem esse campo ainda.
  String? get planoOrigem => _planoOrigem;
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
      _planoOrigem = d['plano_origem']?.toString();
      _planoRenovacaoAutomatica = d['plano_renovacao_automatica'] as bool?;
      await _carregarTrialDias();
      _loaded = true;
    } catch (_) {}
  }

  Future<void> _carregarTrialDias() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('geral')
          .get();
      final dias = (doc.data()?['trial_dias'] as num?)?.toInt();
      _trialDurationDays = (dias != null && dias > 0)
          ? dias
          : _trialDurationDaysPadrao;
    } catch (_) {
      _trialDurationDays = _trialDurationDaysPadrao;
    }
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
    _planoOrigem = null;
    _planoRenovacaoAutomatica = null;
    _trialDurationDays = _trialDurationDaysPadrao;
  }

  bool get isLoaded => _loaded;

  String get planDisplayName {
    if (isPro) return 'Sensei PRO';
    if (isInTrial) return 'Trial Gratuito';
    return 'Plano Gratuito';
  }
}
