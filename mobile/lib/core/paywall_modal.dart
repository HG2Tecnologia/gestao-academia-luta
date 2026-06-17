import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'iap_service.dart';

Future<bool> mostrarPaywall(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PaywallSheet(),
  );
  return result == true;
}

// ─── Static plan metadata ─────────────────────────────────────────────────────

class _PlanMeta {
  final String id;
  final String nome;
  final String precoMesFallback;
  final String precoTotalFallback;
  final String desconto;
  final String? topLabel;
  final Color? topLabelColor;
  final bool destaque;

  const _PlanMeta({
    required this.id,
    required this.nome,
    required this.precoMesFallback,
    required this.precoTotalFallback,
    required this.desconto,
    this.topLabel,
    this.topLabelColor,
    this.destaque = false,
  });
}

const _planos = [
  _PlanMeta(
    id: kIapMensal,
    nome: 'Mensal',
    precoMesFallback: 'R\$99,99',
    precoTotalFallback: '',
    desconto: '',
  ),
  _PlanMeta(
    id: kIapTrimestral,
    nome: 'Trimestral',
    precoMesFallback: 'R\$83,30',
    precoTotalFallback: 'R\$249,90 a cada 3 meses',
    desconto: '17% OFF',
    topLabel: 'MAIS POPULAR',
    topLabelColor: Color(0xFF6366F1),
    destaque: true,
  ),
  _PlanMeta(
    id: kIapAnual,
    nome: 'Anual',
    precoMesFallback: 'R\$66,66',
    precoTotalFallback: 'R\$799,90 por ano',
    desconto: '33% OFF',
    topLabel: 'MELHOR VALOR',
    topLabelColor: Color(0xFF16A34A),
  ),
];

// ─── Sheet ────────────────────────────────────────────────────────────────────

class _PaywallSheet extends StatefulWidget {
  const _PaywallSheet();

  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  int _selected = 1; // default: trimestral
  bool _loading = false;
  bool _initLoading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _initIap();
  }

  Future<void> _initIap() async {
    final iap = IapService.instance;
    await iap.init();
    iap.onPurchaseResult = _onResult;
    if (mounted) setState(() => _initLoading = false);
  }

  void _onResult(bool success, String? error) {
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sensei PRO ativado com sucesso! Aproveite.'),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (error != null) {
      setState(() => _erro = error);
    }
    // null error = cancelado pelo usuário, não mostrar nada
  }

  Future<void> _assinar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    final iap = IapService.instance;

    if (!iap.storeAvailable) {
      setState(() {
        _loading = false;
        _erro = 'Loja não disponível no momento. Verifique sua conexão.';
      });
      return;
    }

    final planId = _planos[_selected].id;
    final matches = iap.products.where((p) => p.id == planId);
    if (matches.isEmpty) {
      setState(() {
        _loading = false;
        _erro = 'Produto não encontrado na loja. Tente novamente.';
      });
      return;
    }

    await iap.comprar(matches.first);
    // loading permanece até stream responder
  }

  Future<void> _restaurar() async {
    setState(() => _loading = true);
    await IapService.instance.restaurar();
    // resultado chega pelo onPurchaseResult
  }

  // Resolve preço exibido: usa dado real da loja se disponível
  String _precoMes(int index) {
    final meta = _planos[index];
    final products = IapService.instance.products;
    if (products.isEmpty) return meta.precoMesFallback;

    final matches = products.where((p) => p.id == meta.id);
    if (matches.isEmpty) return meta.precoMesFallback;

    final p = matches.first;
    if (p.currencyCode != 'BRL') return meta.precoMesFallback;

    final months = index == 0 ? 1 : (index == 1 ? 3 : 12);
    final perMonth = p.rawPrice / months;
    return 'R\$${perMonth.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _precoTotal(int index) {
    final meta = _planos[index];
    if (index == 0) return '/mês';
    final products = IapService.instance.products;
    if (products.isEmpty) return meta.precoTotalFallback;

    final matches = products.where((p) => p.id == meta.id);
    if (matches.isEmpty) return meta.precoTotalFallback;

    final p = matches.first;
    if (p.currencyCode != 'BRL') return meta.precoTotalFallback;

    return '${p.price} total';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary, kPrimary.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sensei PRO',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Desbloqueie tudo e faça sua academia crescer sem limites',
              textAlign: TextAlign.center,
              style: TextStyle(color: kText2, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Benefits
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: const [
                  _Benefit(Icons.people_alt_rounded, 'Alunos ilimitados', 'Sem limite de cadastros'),
                  _Benefit(Icons.class_rounded, 'Turmas ilimitadas', 'Organize quantas turmas quiser'),
                  _Benefit(Icons.bar_chart_rounded, 'Relatórios completos', 'Financeiro, frequência e mais'),
                  _Benefit(Icons.notifications_active_rounded, 'Notificações push', 'Comunique alunos em tempo real'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Plan cards
            Text(
              'Escolha seu plano',
              style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            if (_initLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ...List.generate(_planos.length, (i) => _PlanCard(
                meta: _planos[i],
                precoMes: _precoMes(i),
                precoTotal: _precoTotal(i),
                selected: _selected == i,
                onTap: _loading ? null : () => setState(() => _selected = i),
              )),

            const SizedBox(height: 20),

            // Erro
            if (_erro != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kDanger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_erro!, style: TextStyle(color: kDanger, fontSize: 13)),
              ),

            // CTA
            FilledButton(
              onPressed: _loading || _initLoading ? null : _assinar,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                disabledBackgroundColor: kPrimary.withValues(alpha: 0.4),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text(
                      'Assinar Sensei PRO',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
            ),
            const SizedBox(height: 10),

            // Restaurar + fechar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _loading ? null : _restaurar,
                  child: Text('Restaurar compra', style: TextStyle(color: kText2, fontSize: 12)),
                ),
                Text('·', style: TextStyle(color: kBorder)),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                  child: Text('Agora não', style: TextStyle(color: kText2, fontSize: 12)),
                ),
              ],
            ),
            Text(
              'A cobrança é feita pela App Store ou Google Play. Cancele quando quiser.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kText2.withValues(alpha: 0.6), fontSize: 10, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: TextStyle(color: kText2.withValues(alpha: 0.55), fontSize: 10, height: 1.6),
                children: [
                  const TextSpan(text: 'Ao assinar, você concorda com os nossos '),
                  TextSpan(
                    text: 'Termos de Uso',
                    style: TextStyle(color: kPrimary, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => launchUrl(Uri.parse(kTermosUrl), mode: LaunchMode.externalApplication),
                  ),
                  const TextSpan(text: ' e '),
                  TextSpan(
                    text: 'Política de Privacidade',
                    style: TextStyle(color: kPrimary, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => launchUrl(Uri.parse(kPrivacidadeUrl), mode: LaunchMode.externalApplication),
                  ),
                  const TextSpan(text: '. A assinatura renova automaticamente até ser cancelada.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Plan Card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final _PlanMeta meta;
  final String precoMes;
  final String precoTotal;
  final bool selected;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.meta,
    required this.precoMes,
    required this.precoTotal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: selected ? kPrimary.withValues(alpha: 0.08) : kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? kPrimary : kBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top label (MAIS POPULAR / MELHOR VALOR)
              if (meta.topLabel != null)
                Container(
                  color: meta.topLabelColor,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    meta.topLabel!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Radio
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? kPrimary : kBorder,
                          width: 2,
                        ),
                        color: selected ? kPrimary : Colors.transparent,
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 13)
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Nome + total
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.nome,
                            style: TextStyle(
                              color: kText1,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (precoTotal.isNotEmpty)
                            Text(
                              precoTotal,
                              style: TextStyle(color: kText2, fontSize: 12),
                            ),
                        ],
                      ),
                    ),

                    // Preço/mês + badge desconto
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: precoMes,
                                style: TextStyle(
                                  color: selected ? kPrimary : kText1,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: '/mês',
                                style: TextStyle(color: kText2, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (meta.desconto.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kSuccess.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: kSuccess.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              meta.desconto,
                              style: TextStyle(
                                color: kSuccess,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Benefit Row ──────────────────────────────────────────────────────────────

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String sub;
  const _Benefit(this.icon, this.titulo, this.sub);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(sub, style: TextStyle(color: kText2, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: kSuccess, size: 18),
        ],
      ),
    );
  }
}
