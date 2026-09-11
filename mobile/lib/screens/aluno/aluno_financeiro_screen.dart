import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/auth_storage.dart';
import '../../core/pagamento_status.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/firestore_service.dart';
import '../../core/tab_refresh.dart';
import '../../core/widgets.dart';

class AlunoFinanceiroScreen extends StatefulWidget {
  const AlunoFinanceiroScreen({super.key});

  @override
  State<AlunoFinanceiroScreen> createState() => _AlunoFinanceiroScreenState();
}

class _AlunoFinanceiroScreenState extends State<AlunoFinanceiroScreen> {
  List<Map<String, dynamic>> _cobrancas = [];
  bool _loading = true;
  bool _erro = false;
  String _filtro = 'Todos';
  bool _taxaAtrasoAtiva = false;
  int _taxaAtrasoTipo = 0;
  double _taxaAtrasoValor = 0.0;

  late int _ano;
  late int _mes;

  static const _filtros = ['Todos', 'Atrasado', 'Pendente', 'Pago'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _ano = now.year;
    _mes = now.month;
    alunoTabNotifier.addListener(_onTabChanged);
    _load();
  }

  @override
  void dispose() {
    alunoTabNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (alunoTabNotifier.value == 3) _load();
  }

  num _valorComTaxa(num valor) {
    if (!_taxaAtrasoAtiva) return valor;
    if (_taxaAtrasoTipo == 0) return valor * (1 + _taxaAtrasoValor / 100);
    return valor + _taxaAtrasoValor;
  }

  String _fmtTaxa() {
    if (_taxaAtrasoTipo == 0)
      return '+${_taxaAtrasoValor.toStringAsFixed(1).replaceAll('.', ',')}%';
    return '+R\$ ${_taxaAtrasoValor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Converte o enum de status para a string canônica usada na UI.
  String _stStr(PagamentoStatus s) => switch (s) {
    PagamentoStatus.pago => 'Pago',
    PagamentoStatus.atrasado => 'Atrasado',
    PagamentoStatus.previsto => 'Previsto',
    PagamentoStatus.desconsiderado => 'Desconsiderado',
    PagamentoStatus.pendente => 'Pendente',
  };

  Future<void> _load() async {
    try {
      final user = await AuthStorage.getUser();
      if (user == null) {
        if (mounted)
          setState(() {
            _erro = true;
            _loading = false;
          });
        return;
      }
      final results = await Future.wait([
        firestoreService.getPagamentos(user.academiaId!, alunoId: user.id),
        firestoreService.getAcademia(user.academiaId!).catchError((_) => null),
      ]);
      final list = List<Map<String, dynamic>>.from(results[0] as List);
      final acadData = results[1] as Map<String, dynamic>? ?? {};
      if (mounted)
        setState(() {
          _taxaAtrasoAtiva = acadData['taxa_atraso_ativa'] as bool? ?? false;
          _taxaAtrasoTipo =
              (acadData['taxa_atraso_tipo'] as num?)?.toInt() ?? 0;
          _taxaAtrasoValor =
              (acadData['taxa_atraso_valor'] as num?)?.toDouble() ?? 0.0;
        });
      final converted = list.map((p) {
        final st = pagamentoStatusEfetivo(
          rawStatus: p['status'],
          dataVencimento: p['data_vencimento'] ?? p['dataVencimento'],
        );
        return <String, dynamic>{
          ...p,
          'status': _stStr(st),
          'mesRef': pagamentoMesReferencia(p),
          'dataVencimento': _fmtDate(
            p['data_vencimento'] ?? p['dataVencimento'],
          ),
          'tipo': (p['tipo'] ?? p['plano_nome'] ?? 'Cobrança').toString(),
        };
      }).toList();
      if (mounted) setState(() => _cobrancas = converted);
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusLabel(String? s, AppLocalizations l) => switch (s) {
    'Pago' => l.fiStPaid,
    'Pendente' => l.fiStPending,
    'Atrasado' => l.fiStOverdue,
    'Previsto' => l.fiStForecast,
    'Desconsiderado' => l.fiStDismissed,
    _ => l.fiStPending,
  };

  String _filtroLabel(String f, AppLocalizations l) => switch (f) {
    'Todos' => l.fiTabAll,
    'Atrasado' => l.fiTabOverdue,
    'Pendente' => l.fiTabPending,
    'Pago' => l.fiTabPaid,
    _ => f,
  };

  Color _statusCor(String? s) {
    if (s == 'Pago') return context.sem.success;
    if (s == 'Pendente') return context.sem.warning;
    if (s == 'Atrasado') return context.sem.danger;
    if (s == 'Previsto') return context.c.onSurfaceVariant;
    if (s == 'Desconsiderado') return context.c.onSurfaceVariant;
    return context.sem.warning;
  }

  IconData _statusIcon(String? s) {
    if (s == 'Pago') return Icons.check_circle_rounded;
    if (s == 'Pendente') return Icons.schedule_rounded;
    if (s == 'Atrasado') return Icons.error_rounded;
    if (s == 'Desconsiderado') return Icons.block_rounded;
    return Icons.receipt_long_rounded;
  }

  String _fmtDate(dynamic s) {
    if (s == null) return '';
    if (s is int) {
      final ms = s > 100000000000 ? s : s * 1000;
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    try {
      final dt = DateTime.parse(s.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return s.toString();
    }
  }

  String _fmtMoeda(num? v) {
    if (v == null) return 'R\$ 0,00';
    return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get _mesRefSel =>
      '${_ano.toString().padLeft(4, '0')}-${_mes.toString().padLeft(2, '0')}';

  String _mesLabel(int ano, int mes) {
    final loc = Localizations.localeOf(context).languageCode;
    final nome = DateFormat.MMMM(loc).format(DateTime(ano, mes));
    final cap = nome.isEmpty
        ? nome
        : '${nome[0].toUpperCase()}${nome.substring(1)}';
    return '$cap $ano';
  }

  void _mudarMes(int delta) {
    final base = DateTime(_ano, _mes + delta);
    setState(() {
      _ano = base.year;
      _mes = base.month;
    });
  }

  bool get _ehMesAtual {
    final now = DateTime.now();
    return _ano == now.year && _mes == now.month;
  }

  void _irParaMesAtual() {
    if (_ehMesAtual) return;
    final now = DateTime.now();
    setState(() {
      _ano = now.year;
      _mes = now.month;
    });
  }

  /// Cobranças do mês selecionado (para a lista), ordenadas por vencimento.
  List<Map<String, dynamic>> get _doMes {
    final l =
        _cobrancas.where((c) => (c['mesRef'] as String? ?? '') == _mesRefSel)
            .toList()
          ..sort(
            (a, b) => (a['data_vencimento'] ?? '').toString().compareTo(
              (b['data_vencimento'] ?? '').toString(),
            ),
          );
    return l;
  }

  List<Map<String, dynamic>> get _filtrados {
    if (_filtro == 'Todos') return _doMes;
    return _doMes.where((c) => c['status'] == _filtro).toList();
  }

  /// Todas as atrasadas, de qualquer mês.
  List<Map<String, dynamic>> get _atrasadasTodas =>
      _cobrancas.where((c) => c['status'] == 'Atrasado').toList()..sort(
        (a, b) => (a['data_vencimento'] ?? '').toString().compareTo(
          (b['data_vencimento'] ?? '').toString(),
        ),
      );

  int get _atrasadasGeral => _atrasadasTodas.length;
  int get _pendentesGeral =>
      _cobrancas.where((c) => c['status'] == 'Pendente').length;

  /// Total em aberto somando TODOS os meses (pendente + atrasado).
  num get _totalEmAberto => _cobrancas
      .where((c) => c['status'] == 'Pendente' || c['status'] == 'Atrasado')
      .fold<num>(0, (sum, c) => sum + ((c['valor'] as num?) ?? 0));

  bool get _temPendencia => _atrasadasGeral > 0 || _pendentesGeral > 0;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.c.surface,
        body: Center(
          child: CircularProgressIndicator(color: context.c.primary),
        ),
      );
    }
    if (_erro && _cobrancas.isEmpty) {
      return Scaffold(
        backgroundColor: context.c.surface,
        body: SafeArea(
          child: ErroConexao(
            onRetry: () {
              setState(() {
                _loading = true;
                _erro = false;
              });
              _load();
            },
          ),
        ),
      );
    }

    final filtrados = _filtrados;
    final temPendencia = _temPendencia;

    return Scaffold(
      backgroundColor: context.c.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.c.primary,
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Text(
                    context.l10n.navBilling,
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              // ── Summary card (todos os meses) ─────────────
              if (_cobrancas.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: temPendencia
                              ? [
                                  context.sem.danger.withOpacity(0.25),
                                  context.sem.danger.withOpacity(0.08),
                                ]
                              : [
                                  context.sem.success.withOpacity(0.25),
                                  context.sem.success.withOpacity(0.08),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: temPendencia
                              ? context.sem.danger.withOpacity(0.4)
                              : context.sem.success.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color:
                                      (temPendencia
                                              ? context.sem.danger
                                              : context.sem.success)
                                          .withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  temPendencia
                                      ? Icons.account_balance_wallet_rounded
                                      : Icons.verified_rounded,
                                  color: temPendencia
                                      ? context.sem.danger
                                      : context.sem.success,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      temPendencia
                                          ? context.l10n.apOutstanding
                                          : context.l10n.apAllPaid,
                                      style: TextStyle(
                                        color: temPendencia
                                            ? context.sem.danger
                                            : context.sem.success,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      temPendencia
                                          ? context.l10n.apTotalOpenAllMonths(
                                              _fmtMoeda(_totalEmAberto),
                                            )
                                          : context.l10n.apNoPendingNow,
                                      style: TextStyle(
                                        color: context.c.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (temPendencia)
                                Column(
                                  children: [
                                    if (_atrasadasGeral > 0)
                                      _pillCount(
                                        context.l10n.apOverdueCount(
                                          _atrasadasGeral,
                                        ),
                                        context.sem.danger,
                                      ),
                                    if (_pendentesGeral > 0)
                                      const SizedBox(height: 4),
                                    if (_pendentesGeral > 0)
                                      _pillCount(
                                        context.l10n.apPendingCount(
                                          _pendentesGeral,
                                        ),
                                        context.sem.warning,
                                      ),
                                  ],
                                ),
                            ],
                          ),
                          if (_atrasadasGeral > 0) ...[
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: _abrirAtrasadas,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: context.sem.danger.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.priority_high_rounded,
                                      size: 16,
                                      color: context.sem.danger,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        context.l10n.apViewAllOverdue,
                                        style: TextStyle(
                                          color: context.sem.danger,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: context.sem.danger,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Navegação de mês ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.c.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.c.outline),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _mudarMes(-1),
                          tooltip: context.l10n.apPrevMonth,
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: context.c.onSurface,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _ehMesAtual ? null : _irParaMesAtual,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _mesLabel(_ano, _mes),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: context.c.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (_ehMesAtual)
                                  Text(
                                    context.l10n.fiCurrentMonth,
                                    style: TextStyle(
                                      color: context.c.primary,
                                      fontSize: 11,
                                    ),
                                  )
                                else
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.today_rounded,
                                        size: 12,
                                        color: context.c.primary,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        context.l10n.tdToday,
                                        style: TextStyle(
                                          color: context.c.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _mudarMes(1),
                          tooltip: context.l10n.apNextMonth,
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color: context.c.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Filter chips ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filtros.map((f) {
                        final sel = _filtro == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filtro = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? context.c.primary
                                    : context.c.surfaceContainer,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel
                                      ? context.c.primary
                                      : context.c.outline,
                                ),
                              ),
                              child: Text(
                                _filtroLabel(f, context.l10n),
                                style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : context.c.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // ── List label ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    context.l10n.apChargesUpper,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final c = filtrados[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _CobrancaCard(
                      c: c,
                      statusCor: _statusCor,
                      statusIcon: _statusIcon,
                      statusLabel: (s) => _statusLabel(s, context.l10n),
                      fmtMoeda: _fmtMoeda,
                      fmtTaxa: _fmtTaxa,
                      valorComTaxa: _valorComTaxa,
                      taxaAtrasoAtiva: _taxaAtrasoAtiva,
                    ),
                  );
                }, childCount: filtrados.length),
              ),

              if (filtrados.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: context.c.outline,
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filtro == 'Todos'
                              ? context.l10n.apNoChargesThisMonth(
                                  _mesLabel(_ano, _mes),
                                )
                              : context.l10n.apNoChargesInCategory,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirAtrasadas() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.c.surfaceContainer,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final atrasadas = _atrasadasTodas;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: ctx.c.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_rounded,
                        color: ctx.sem.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ctx.l10n.apAllOverdueTitle,
                          style: TextStyle(
                            color: ctx.c.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        ctx.l10n.apOverdueCount(atrasadas.length),
                        style: TextStyle(
                          color: ctx.sem.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: atrasadas.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CobrancaCard(
                        c: atrasadas[i],
                        statusCor: _statusCor,
                        statusIcon: _statusIcon,
                        statusLabel: (s) => _statusLabel(s, ctx.l10n),
                        fmtMoeda: _fmtMoeda,
                        fmtTaxa: _fmtTaxa,
                        valorComTaxa: _valorComTaxa,
                        taxaAtrasoAtiva: _taxaAtrasoAtiva,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pillCount(String text, Color cor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: cor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _CobrancaCard extends StatelessWidget {
  final Map<String, dynamic> c;
  final Color Function(String?) statusCor;
  final IconData Function(String?) statusIcon;
  final String Function(String?) statusLabel;
  final String Function(num?) fmtMoeda;
  final String Function() fmtTaxa;
  final num Function(num) valorComTaxa;
  final bool taxaAtrasoAtiva;

  const _CobrancaCard({
    required this.c,
    required this.statusCor,
    required this.statusIcon,
    required this.statusLabel,
    required this.fmtMoeda,
    required this.fmtTaxa,
    required this.valorComTaxa,
    required this.taxaAtrasoAtiva,
  });

  @override
  Widget build(BuildContext context) {
    final s = c['status'] as String?;
    final cor = statusCor(s);
    final atrasado = s == 'Atrasado';

    return Container(
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: atrasado
              ? context.sem.danger.withOpacity(0.35)
              : context.c.outline,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon(s), color: cor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['tipo'] ?? context.l10n.apChargeFallback,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((c['dataVencimento'] as String? ?? '').isNotEmpty)
                        Text(
                          context.l10n.apDueDatePrefix(
                            c['dataVencimento'] as String,
                          ),
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (atrasado &&
                        taxaAtrasoAtiva &&
                        (c['valor'] as num?) != null) ...[
                      Text(
                        fmtMoeda(c['valor'] as num?),
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        fmtMoeda(valorComTaxa(c['valor'] as num)),
                        style: TextStyle(
                          color: context.sem.danger,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ] else
                      Text(
                        fmtMoeda(c['valor'] as num?),
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        atrasado && taxaAtrasoAtiva
                            ? '${statusLabel(s)} ${fmtTaxa()}'
                            : statusLabel(s),
                        style: TextStyle(
                          color: cor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (atrasado)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: context.sem.danger.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: context.sem.danger,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.apContactSecretary,
                    style: TextStyle(
                      color: context.sem.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
