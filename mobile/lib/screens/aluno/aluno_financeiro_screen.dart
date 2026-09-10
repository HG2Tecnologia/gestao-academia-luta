import 'package:flutter/material.dart';
import '../../core/auth_storage.dart';
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

  static const _filtros = ['Todos', 'Atrasado', 'Pendente', 'Pago'];
  static const _statusMap = {
    0: 'Pendente',
    1: 'Pago',
    2: 'Atrasado',
    3: 'Previsto',
  };

  @override
  void initState() {
    super.initState();
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
        final statusRaw = p['status'];
        final statusInt = statusRaw is int
            ? statusRaw
            : int.tryParse(statusRaw.toString()) ?? 0;
        final statusStr = _statusMap[statusInt] ?? 'Pendente';
        return <String, dynamic>{
          ...p,
          'status': statusStr,
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
    _ => s ?? '',
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
    return context.sem.danger;
  }

  IconData _statusIcon(String? s) {
    if (s == 'Pago') return Icons.check_circle_rounded;
    if (s == 'Pendente') return Icons.schedule_rounded;
    return Icons.warning_rounded;
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

  List<Map<String, dynamic>> get _filtrados {
    if (_filtro == 'Todos') return _cobrancas;
    return _cobrancas.where((c) => c['status'] == _filtro).toList();
  }

  int get _atrasadas =>
      _cobrancas.where((c) => c['status'] == 'Atrasado').length;
  int get _pendentes =>
      _cobrancas.where((c) => c['status'] == 'Pendente').length;
  num get _totalPendente => _cobrancas
      .where((c) => c['status'] != 'Pago')
      .fold<num>(0, (sum, c) => sum + ((c['valor'] as num?) ?? 0));

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
    final temPendencia = _atrasadas > 0 || _pendentes > 0;

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

              // ── Summary card ──────────────────────────────
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
                      child: Row(
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
                                      ? context.l10n.apAmountToSettle(
                                          _fmtMoeda(_totalPendente),
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
                                if (_atrasadas > 0)
                                  _pillCount(
                                    context.l10n.apOverdueCount(_atrasadas),
                                    context.sem.danger,
                                  ),
                                if (_pendentes > 0) const SizedBox(height: 4),
                                if (_pendentes > 0)
                                  _pillCount(
                                    context.l10n.apPendingCount(_pendentes),
                                    context.sem.warning,
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Filter chips ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
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

              // ── List ──────────────────────────────────────
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
                  final s = c['status'] as String?;
                  final cor = _statusCor(s);
                  final atrasado = s == 'Atrasado';

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
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
                                  child: Icon(
                                    _statusIcon(s),
                                    color: cor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['tipo'] ??
                                            context.l10n.apChargeFallback,
                                        style: TextStyle(
                                          color: context.c.onSurface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if ((c['dataVencimento'] as String)
                                          .isNotEmpty)
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
                                        _taxaAtrasoAtiva &&
                                        (c['valor'] as num?) != null) ...[
                                      Text(
                                        _fmtMoeda((c['valor'] as num?)),
                                        style: TextStyle(
                                          color: context.c.onSurfaceVariant,
                                          fontSize: 12,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Text(
                                        _fmtMoeda(
                                          _valorComTaxa(c['valor'] as num),
                                        ),
                                        style: TextStyle(
                                          color: context.sem.danger,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        _fmtMoeda(c['valor'] as num?),
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
                                        atrasado && _taxaAtrasoAtiva
                                            ? '${_statusLabel(s, context.l10n)} ${_fmtTaxa()}'
                                            : _statusLabel(s, context.l10n),
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
                          context.l10n.apNoChargesInCategory,
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
