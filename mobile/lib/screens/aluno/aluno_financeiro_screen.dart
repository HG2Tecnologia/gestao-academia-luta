import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/tab_refresh.dart';
import '../../core/widgets.dart';

class AlunoFinanceiroScreen extends StatefulWidget {
  const AlunoFinanceiroScreen({super.key});

  @override
  State<AlunoFinanceiroScreen> createState() => _AlunoFinanceiroScreenState();
}

class _AlunoFinanceiroScreenState extends State<AlunoFinanceiroScreen> {
  List<Map<String, dynamic>> _cobrancas = [];
  Map<String, dynamic>? _planoAtivo;
  bool _loading = true;
  bool _erro = false;
  String _filtro = 'Todos';

  static const _filtros = ['Todos', 'Atrasado', 'Pendente', 'Pago'];

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

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        dio.get('/api/financeiro/minhas'),
        dio.get('/api/alunos/me'),
      ]);
      final dados = results[0].data['dados'];
      final list = dados is List ? dados : (dados is Map ? dados['items'] as List? ?? [] : []);
      if (mounted) setState(() => _cobrancas = list.cast<Map<String, dynamic>>());

      final alunoId = (results[1].data['dados'] as Map<String, dynamic>?)?['id']?.toString() ?? '';
      if (alunoId.isNotEmpty) {
        try {
          final cr = await dio.get('/api/contratos', queryParameters: {'alunoId': alunoId});
          final contratos = (cr.data['dados'] as List? ?? []).cast<Map<String, dynamic>>();
          final ativo = contratos.firstWhere(
            (c) => c['status']?.toString().toLowerCase() == 'ativo',
            orElse: () => contratos.isNotEmpty ? contratos.first : {},
          );
          if (ativo.isNotEmpty && mounted) setState(() => _planoAtivo = ativo);
        } catch (_) {}
      }
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusCor(String? s) {
    if (s == 'Pago') return kSuccess;
    if (s == 'Pendente') return kWarning;
    return kDanger;
  }

  IconData _statusIcon(String? s) {
    if (s == 'Pago') return Icons.check_circle_rounded;
    if (s == 'Pendente') return Icons.schedule_rounded;
    return Icons.warning_rounded;
  }

  String _fmtDate(String? s) {
    if (s == null) return '';
    try {
      final dt = DateTime.parse(s);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return s;
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

  int get _atrasadas => _cobrancas.where((c) => c['status'] == 'Atrasado').length;
  int get _pendentes => _cobrancas.where((c) => c['status'] == 'Pendente').length;
  num get _totalPendente => _cobrancas
      .where((c) => c['status'] != 'Pago')
      .fold<num>(0, (sum, c) => sum + ((c['valor'] as num?) ?? 0));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(backgroundColor: kBg, body: Center(child: CircularProgressIndicator(color: kPrimary)));
    }
    if (_erro && _cobrancas.isEmpty) {
      return Scaffold(backgroundColor: kBg, body: SafeArea(child: ErroConexao(onRetry: () { setState(() { _loading = true; _erro = false; }); _load(); })));
    }

    final filtrados = _filtrados;
    final temPendencia = _atrasadas > 0 || _pendentes > 0;

    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            // ── Header ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(children: [
                  GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
                  const SizedBox(width: 14),
                  Text('Financeiro', style: TextStyle(color: kText1, fontSize: 26, fontWeight: FontWeight.w900)),
                ]),
              ),
            ),

            // ── Plano ─────────────────────────────────────
            if (_planoAtivo != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.card_membership_rounded, color: kPrimary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Plano atual',
                                  style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w500)),
                              Text(
                                _planoAtivo!['nomePlano']?.toString() ??
                                    _planoAtivo!['planoNome']?.toString() ??
                                    _planoAtivo!['descricao']?.toString() ??
                                    'Plano ativo',
                                style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        if (_planoAtivo!['valorMensal'] != null || _planoAtivo!['valor'] != null)
                          Text(
                            _fmtMoeda((_planoAtivo!['valorMensal'] ?? _planoAtivo!['valor']) as num?),
                            style: TextStyle(color: kPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                      ],
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
                            ? [kDanger.withOpacity(0.25), kDanger.withOpacity(0.08)]
                            : [kSuccess.withOpacity(0.25), kSuccess.withOpacity(0.08)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: temPendencia ? kDanger.withOpacity(0.4) : kSuccess.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: (temPendencia ? kDanger : kSuccess).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            temPendencia ? Icons.account_balance_wallet_rounded : Icons.verified_rounded,
                            color: temPendencia ? kDanger : kSuccess,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                temPendencia ? 'Em aberto' : 'Em dia!',
                                style: TextStyle(
                                  color: temPendencia ? kDanger : kSuccess,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                temPendencia
                                    ? '${_fmtMoeda(_totalPendente)} a regularizar'
                                    : 'Sem pendências no momento',
                                style: TextStyle(color: kText2, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (temPendencia)
                          Column(
                            children: [
                              if (_atrasadas > 0)
                                _pillCount('$_atrasadas atrasada${_atrasadas > 1 ? 's' : ''}', kDanger),
                              if (_pendentes > 0) const SizedBox(height: 4),
                              if (_pendentes > 0)
                                _pillCount('$_pendentes pendente${_pendentes > 1 ? 's' : ''}', kWarning),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? kPrimary : kSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: sel ? kPrimary : kBorder),
                            ),
                            child: Text(f,
                                style: TextStyle(
                                  color: sel ? Colors.white : kText2,
                                  fontSize: 13,
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                                )),
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
                child: Text('COBRANÇAS',
                    style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final c = filtrados[i];
                  final s = c['status'] as String?;
                  final cor = _statusCor(s);
                  final atrasado = s == 'Atrasado';

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: atrasado ? kDanger.withOpacity(0.35) : kBorder),
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
                                  child: Icon(_statusIcon(s), color: cor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c['tipo'] ?? 'Cobrança',
                                          style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
                                      if (c['dataVencimento'] != null)
                                        Text('Vencimento: ${_fmtDate(c['dataVencimento'])}',
                                            style: TextStyle(color: kText2, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(_fmtMoeda(c['valor'] as num?),
                                        style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w800)),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: cor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(s ?? '',
                                          style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (atrasado)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: kDanger.withOpacity(0.08),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(14),
                                  bottomRight: Radius.circular(14),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.phone_outlined, size: 14, color: kDanger),
                                  const SizedBox(width: 6),
                                  Text('Entre em contato com a secretaria para regularizar.',
                                      style: TextStyle(color: kDanger, fontSize: 12)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filtrados.length,
              ),
            ),

            if (filtrados.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(children: [
                      Icon(Icons.receipt_long_rounded, color: kBorder, size: 56),
                      const SizedBox(height: 16),
                      Text('Nenhuma cobrança nessa categoria',
                          style: TextStyle(color: kText2, fontSize: 14), textAlign: TextAlign.center),
                    ]),
                  ),
                ),
              ),

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
        child: Text(text, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}
