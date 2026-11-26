import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'iap_service.dart';
import 'plan_catalog.dart';
import 'plan_service.dart';
import 'theme/context_ext.dart';

Future<bool> mostrarPaywall(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PaywallSheet(),
  );
  return result == true;
}

String _formatarPreco(double valor) =>
    'R\$${valor.toStringAsFixed(2).replaceAll('.', ',')}';

String _mensagemDeBloqueio(MotivoBloqueio motivo, String? plataforma) {
  final loja = plataforma == 'ios' ? 'App Store' : 'Google Play';
  return switch (motivo) {
    MotivoBloqueio.planoAtual => 'Este já é o seu plano atual.',
    MotivoBloqueio.assinaturaEmOutraLoja =>
      'Sua assinatura atual é da $loja. Para não pagar duas vezes, troque de '
          'plano em um aparelho com essa loja ou cancele a renovação por lá '
          'antes de assinar aqui.',
    MotivoBloqueio.assinaturaEmOutraConta =>
      'A assinatura desta academia está em outra conta da loja. Entre com ela '
          'para trocar de plano.',
    MotivoBloqueio.contaDaLojaJaAssina =>
      'Esta conta da loja já tem uma assinatura ativa. Toque em "Restaurar '
          'compra". Se ela for de outra academia, fale com o suporte.',
  };
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class _PaywallSheet extends StatefulWidget {
  const _PaywallSheet();

  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  Periodo _periodo = Periodo.trimestral;

  // Quem já é PRO abre direto no plano superior.
  late NivelPlano _nivel = PlanService.instance.nivel == NivelPlano.pro
      ? NivelPlano.blackBelt
      : PlanService.instance.nivel ?? NivelPlano.pro;

  // Evita fechar a tela duas vezes quando a loja devolve mais de uma compra.
  bool _concluido = false;
  DecisaoCompra? _decisao;

  /// O Black Belt só aparece quando a loja já o oferece. Em depuração aparece
  /// sempre, para testar a tela antes do cadastro dos produtos.
  bool get _temBlackBelt =>
      kDebugMode ||
      IapService.instance.products.any(
        (p) => produtoPorId(p.id)?.nivel == NivelPlano.blackBelt,
      );

  NivelPlano get _nivelVisivel => _temBlackBelt ? _nivel : NivelPlano.pro;

  ProdutoPlano get _selecionado => produtoDe(_nivelVisivel, _periodo);

  /// Plano que a academia já paga e que vai continuar renovando.
  bool _ehPlanoAtual(String produtoId) {
    final plan = PlanService.instance;
    return plan.isPro &&
        plan.planoProdutoId == produtoId &&
        plan.planoRenovacaoAutomatica != false;
  }

  bool _loading = false;
  bool _initLoading = true;
  String? _erro;

  // `restorePurchases()` só resolve de verdade via `purchaseStream` quando
  // encontra algo pra restaurar — se a conta não tiver nenhuma compra
  // (ex.: testando com uma conta diferente da que comprou, ou alguém que
  // nunca assinou), o stream nunca emite nada e o loading ficava girando
  // pra sempre. Esse timer dá um prazo e mostra uma mensagem neutra se
  // nada chegar. O token evita que ele dispare depois de um resultado
  // real já ter chegado (ex.: restauração lenta que chega em 9s).
  Timer? _restoreTimeout;
  int _restoreToken = 0;

  @override
  void initState() {
    super.initState();
    _initIap();
  }

  @override
  void dispose() {
    _restoreTimeout?.cancel();
    super.dispose();
  }

  Future<void> _initIap() async {
    final iap = IapService.instance;
    await iap.init();
    iap.onPurchaseResult = _onResult;
    if (mounted) setState(() => _initLoading = false);
  }

  void _onResult(bool success, String? error) {
    _restoreTimeout?.cancel();
    _restoreToken++;
    if (!mounted || _concluido) return;
    setState(() => _loading = false);
    if (success) {
      _concluido = true;
      final decisao = _decisao;
      final agendada =
          decisao is TrocaDePlano && decisao.modo == ModoTroca.noProximoCiclo;
      final mensagem = agendada
          ? 'Troca agendada: o plano novo começa na próxima renovação.'
          : decisao == null
          ? 'Assinatura ativada com sucesso! Aproveite.'
          : '${_selecionado.nivel.nome} ativado com sucesso! Aproveite.';
      final messenger = ScaffoldMessenger.of(context);
      final cor = context.sem.success;
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: cor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (error != null) {
      setState(() => _erro = error);
    }
    // null error = cancelado pelo usuário, não mostrar nada
  }

  void _falhar(String mensagem) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _erro = mensagem;
    });
  }

  Future<void> _assinar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    final iap = IapService.instance;

    if (!iap.storeAvailable) {
      _falhar('Loja não disponível no momento. Verifique sua conexão.');
      return;
    }

    final matches = iap.products.where((p) => p.id == _selecionado.id);
    if (matches.isEmpty) {
      _falhar('Produto não encontrado na loja. Tente novamente.');
      return;
    }

    try {
      final decisao = await iap.avaliar(matches.first);
      if (!mounted) return;
      if (decisao is CompraBloqueada) {
        _falhar(
          _mensagemDeBloqueio(
            decisao.motivo,
            PlanService.instance.planoPlataforma,
          ),
        );
        return;
      }
      _decisao = decisao;
      await iap.comprar(matches.first, decisao);
      // loading permanece até stream responder
    } catch (_) {
      _falhar('Não foi possível iniciar a compra. Tente novamente.');
    }
  }

  Future<void> _restaurar() async {
    _decisao = null;
    setState(() {
      _loading = true;
      _erro = null;
    });
    final token = ++_restoreToken;
    _restoreTimeout?.cancel();
    _restoreTimeout = Timer(const Duration(seconds: 10), () {
      if (!mounted || token != _restoreToken) return;
      setState(() {
        _loading = false;
        _erro = 'Nenhuma assinatura ativa encontrada nessa conta.';
      });
    });
    await IapService.instance.restaurar();
    // resultado (se houver algo pra restaurar) chega pelo onPurchaseResult
  }

  ProductDetails? _daLoja(String id) {
    for (final p in IapService.instance.products) {
      if (p.id == id && p.currencyCode == 'BRL') return p;
    }
    return null;
  }

  double _valor(ProdutoPlano plano) =>
      _daLoja(plano.id)?.rawPrice ?? plano.precoReserva;

  /// Valor efetivamente cobrado, à vista, numa transação só.
  String _precoCobrado(ProdutoPlano plano) =>
      _daLoja(plano.id)?.price ?? _formatarPreco(plano.precoReserva);

  // Para trimestral/anual, o valor "por mês" é só uma referência de economia,
  // NUNCA o cobrado. Mostrá-lo em destaque dava a entender, pra alguns
  // clientes, que a compra era parcelada — mesma confusão que já aconteceu com
  // o parcelamento nativo da Apple.
  String _precoMes(ProdutoPlano plano) =>
      _formatarPreco(_valor(plano) / plano.periodo.meses);

  /// Texto de cadência de cobrança (não repete o valor, que já aparece em
  /// destaque do lado direito do card) — deixa explícito que é uma cobrança
  /// única à vista, não parcelada.
  String _cadencia(Periodo periodo) => switch (periodo) {
    Periodo.trimestral => 'Cobrado a cada 3 meses, em uma única parcela',
    Periodo.anual => 'Cobrado 1x por ano, em uma única parcela',
    Periodo.mensal => '',
  };

  Widget _cardDoPlano(Periodo periodo) {
    final plano = produtoDe(_nivelVisivel, periodo);
    final desconto = descontoPercentual(
      precoPeriodo: _valor(plano),
      precoMensal: _valor(produtoDe(_nivelVisivel, Periodo.mensal)),
      meses: periodo.meses,
    );
    final atual = _ehPlanoAtual(plano.id);
    final (rotulo, cor) = switch (periodo) {
      _ when atual => ('SEU PLANO ATUAL', const Color(0xFF475569)),
      Periodo.trimestral => ('MAIS POPULAR', const Color(0xFFC9A020)),
      Periodo.anual => ('MELHOR VALOR', const Color(0xFF16A34A)),
      Periodo.mensal => (null, null),
    };
    return _PlanCard(
      key: ValueKey(plano.id),
      nome: periodo.nome,
      topLabel: rotulo,
      topLabelColor: cor,
      desconto: desconto > 0 ? '$desconto% OFF' : '',
      precoCobrado: _precoCobrado(plano),
      precoMesReferencia: _precoMes(plano),
      precoTotal: _cadencia(periodo),
      isMensal: periodo == Periodo.mensal,
      selected: _periodo == periodo,
      onTap: _loading ? null : () => setState(() => _periodo = periodo),
    );
  }

  String get _textoDoBotao {
    final plan = PlanService.instance;
    if (_ehPlanoAtual(_selecionado.id)) return 'Este é o seu plano';
    if (!plan.isPro) return 'Assinar ${_nivelVisivel.nome}';
    if (plan.nivel != _nivelVisivel) {
      return 'Mudar para o ${_nivelVisivel.nome}';
    }
    return 'Trocar de período';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: context.c.surface,
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
                  color: context.c.outline,
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
                    colors: [
                      context.c.primary,
                      context.c.primary.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: context.c.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _nivelVisivel.nome,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Desbloqueie tudo e faça sua academia crescer sem limites',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            if (_temBlackBelt) ...[
              SegmentedButton<NivelPlano>(
                segments: const [
                  ButtonSegment(
                    value: NivelPlano.pro,
                    label: Text('PRO\nsó app', textAlign: TextAlign.center),
                  ),
                  ButtonSegment(
                    value: NivelPlano.blackBelt,
                    label: Text(
                      'Black Belt\napp + web',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                selected: {_nivel},
                showSelectedIcon: false,
                onSelectionChanged: _loading
                    ? null
                    : (s) => setState(() {
                        _nivel = s.first;
                        _erro = null;
                      }),
              ),
              const SizedBox(height: 16),
            ],

            // Benefits
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.c.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.c.outline),
              ),
              child: Column(
                children: [
                  if (_nivelVisivel == NivelPlano.blackBelt)
                    const _Benefit(
                      Icons.computer_rounded,
                      'Sistema web',
                      'Gerencie a academia também pelo computador',
                    ),
                  const _Benefit(Icons.people_alt_rounded, 'Alunos ilimitados', 'Sem limite de cadastros'),
                  const _Benefit(Icons.class_rounded, 'Turmas ilimitadas', 'Organize quantas turmas quiser'),
                  const _Benefit(Icons.bar_chart_rounded, 'Relatórios completos', 'Financeiro, frequência e mais'),
                  const _Benefit(Icons.notifications_active_rounded, 'Notificações push', 'Comunique alunos em tempo real'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Plan cards
            Text(
              'Escolha seu plano',
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
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
              for (final periodo in Periodo.values) _cardDoPlano(periodo),

            const SizedBox(height: 20),

            // Erro
            if (_erro != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.sem.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _erro!,
                  style: TextStyle(color: context.sem.danger, fontSize: 13),
                ),
              ),

            // CTA
            FilledButton(
              onPressed:
                  _loading || _initLoading || _ehPlanoAtual(_selecionado.id)
                  ? null
                  : _assinar,
              style: FilledButton.styleFrom(
                backgroundColor: context.c.primary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: context.c.primary.withValues(alpha: 0.4),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                    )
                  : Text(
                      _textoDoBotao,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(height: 10),

            // Restaurar + fechar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _loading ? null : _restaurar,
                  child: Text(
                    'Restaurar compra',
                    style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
                  ),
                ),
                Text('·', style: TextStyle(color: context.c.outline)),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                  child: Text(
                    'Agora não',
                    style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.c.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.c.outline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: context.c.onSurfaceVariant,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O pagamento é processado inteiramente pela loja do seu '
                      'celular (App Store ou Google Play) — o Sensei Manager '
                      'não tem nenhum vínculo com a cobrança, não acessa seus '
                      'dados de pagamento e não oferece parcelamento próprio. '
                      'Condições de parcelas eventualmente exibidas na tela de '
                      'assinatura são um recurso nativo da Apple ou do Google, '
                      'fora do nosso controle. Cancele quando quiser direto '
                      'nas configurações da sua conta Apple/Google.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant.withValues(alpha: 0.75),
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: TextStyle(
                  color: context.c.onSurfaceVariant.withValues(alpha: 0.55),
                  fontSize: 10,
                  height: 1.6,
                ),
                children: [
                  const TextSpan(text: 'Ao assinar, você concorda com os nossos '),
                  TextSpan(
                    text: 'Termos de Uso',
                    style: TextStyle(color: context.c.primary, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => launchUrl(Uri.parse(kTermosUrl), mode: LaunchMode.externalApplication),
                  ),
                  const TextSpan(text: ' e '),
                  TextSpan(
                    text: 'Política de Privacidade',
                    style: TextStyle(color: context.c.primary, decoration: TextDecoration.underline),
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
  final String nome;
  final String? topLabel;
  final Color? topLabelColor;
  final String desconto;
  final String precoCobrado;
  final String precoMesReferencia;
  final String precoTotal;
  final bool isMensal;
  final bool selected;
  final VoidCallback? onTap;

  const _PlanCard({
    super.key,
    required this.nome,
    required this.topLabel,
    required this.topLabelColor,
    required this.desconto,
    required this.precoCobrado,
    required this.precoMesReferencia,
    required this.precoTotal,
    required this.isMensal,
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
          color: selected
              ? context.c.primary.withValues(alpha: 0.08)
              : context.c.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? context.c.primary : context.c.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top label (MAIS POPULAR / MELHOR VALOR)
              if (topLabel != null)
                Container(
                  color: topLabelColor,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    topLabel!,
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
                          color: selected ? context.c.primary : context.c.outline,
                          width: 2,
                        ),
                        color: selected ? context.c.primary : Colors.transparent,
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
                            nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.c.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (precoTotal.isNotEmpty)
                            Text(
                              precoTotal,
                              style: TextStyle(
                                color: context.c.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Preço cobrado (à vista) + referência por mês + badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: precoCobrado,
                                style: TextStyle(
                                  color: selected
                                      ? context.c.primary
                                      : context.c.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (isMensal)
                                TextSpan(
                                  text: '/mês',
                                  style: TextStyle(
                                    color: context.c.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!isMensal) ...[
                          const SizedBox(height: 2),
                          Text(
                            'equivale a $precoMesReferencia/mês',
                            style: TextStyle(
                              color: context.c.onSurfaceVariant,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                        if (desconto.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: context.sem.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: context.sem.success.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              desconto,
                              style: TextStyle(
                                color: context.sem.success,
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
              color: context.c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: context.c.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: context.sem.success, size: 18),
        ],
      ),
    );
  }
}
