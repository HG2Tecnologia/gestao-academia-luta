import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ad_banner.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/tab_refresh.dart';

class AdminFinanceiroScreen extends StatefulWidget {
  const AdminFinanceiroScreen({super.key});

  @override
  State<AdminFinanceiroScreen> createState() => _AdminFinanceiroScreenState();
}

class _AdminFinanceiroScreenState extends State<AdminFinanceiroScreen> {
  Map<String, dynamic>? _resumo;
  List<Map<String, dynamic>> _cobrancas = [];
  bool _loading = true;

  late int _ano;
  late int _mes;

  static const _meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _ano = now.year;
    _mes = now.month;
    adminTabNotifier.addListener(_onTabChanged);
    _load();
  }

  @override
  void dispose() {
    adminTabNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (adminTabNotifier.value == 4) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        dio.get('/api/financeiro/resumo', queryParameters: {'ano': _ano, 'mes': _mes}),
        dio.get('/api/financeiro', queryParameters: {'pageSize': 50, 'ano': _ano, 'mes': _mes}),
      ]);
      final r = results[0].data as Map<String, dynamic>;
      final c = results[1].data as Map<String, dynamic>;
      final dados = c['dados'];
      final list = dados is List ? dados : (dados is Map ? (dados['itens'] as List? ?? []) : []);
      if (mounted) {
        setState(() {
          _resumo = r['dados'] as Map<String, dynamic>?;
          _cobrancas = list.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navMes(int delta) {
    setState(() {
      _mes += delta;
      if (_mes > 12) { _mes = 1; _ano++; }
      if (_mes < 1) { _mes = 12; _ano--; }
    });
    _load();
  }

  Color _statusCor(String? s) {
    if (s == 'Pago') return kSuccess;
    if (s == 'Pendente') return kWarning;
    if (s == 'Previsto') return kText2;
    return kDanger;
  }

  Future<void> _criarCobrancaAvulsa() async {
    List<Map<String, dynamic>> alunos = [];
    try {
      final res = await dio.get('/api/alunos', queryParameters: {'pageSize': 200, 'status': 'Ativo'});
      final dados = res.data['dados'];
      final list = dados is List ? dados : (dados is Map ? (dados['itens'] as List? ?? []) : []);
      alunos = list.cast<Map<String, dynamic>>();
    } catch (_) {}

    if (!mounted) return;

    String? alunoId;
    int tipo = 1;
    final valorCtrl = TextEditingController();
    DateTime vencimento = DateTime.now().add(const Duration(days: 5));

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
              Row(children: [
                Icon(Icons.add_circle_outline_rounded, color: kPrimary, size: 22),
                const SizedBox(width: 10),
                Text('Nova cobrança', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 20),
              Text('Aluno', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                child: DropdownButton<String>(
                  value: alunoId,
                  isExpanded: true,
                  dropdownColor: kSurface,
                  underline: const SizedBox(),
                  hint: Text('Selecione o aluno', style: TextStyle(color: kText2, fontSize: 13)),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: kText2),
                  items: alunos.map((a) => DropdownMenuItem<String>(
                    value: a['id']?.toString(),
                    child: Text(a['nome']?.toString() ?? '', style: TextStyle(color: kText1, fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setModal(() => alunoId = v),
                ),
              ),
              const SizedBox(height: 14),
              Text('Tipo', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                child: DropdownButton<int>(
                  value: tipo,
                  isExpanded: true,
                  dropdownColor: kSurface,
                  underline: const SizedBox(),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: kText2),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Mensalidade')),
                    DropdownMenuItem(value: 2, child: Text('Taxa de Matrícula')),
                  ],
                  onChanged: (v) => setModal(() => tipo = v ?? 1),
                ),
              ),
              const SizedBox(height: 14),
              Text('Valor (R\$)', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: valorCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: kText1, fontSize: 15),
                decoration: InputDecoration(
                  hintText: '0,00',
                  hintStyle: TextStyle(color: kText2),
                  filled: true,
                  fillColor: kBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                ),
              ),
              const SizedBox(height: 14),
              Text('Vencimento', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: vencimento,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('pt', 'BR'),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(colorScheme: ColorScheme.dark(primary: kPrimary, surface: kSurface, onSurface: kText1)),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => vencimento = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded, color: kText2, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${vencimento.day.toString().padLeft(2,'0')}/${vencimento.month.toString().padLeft(2,'0')}/${vencimento.year}',
                      style: TextStyle(color: kText1, fontSize: 14),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: alunoId == null ? null : () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: kPrimary.withOpacity(0.3),
                ),
                child: const Text('Gerar cobrança', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kText2,
                  side: BorderSide(color: kBorder),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true || alunoId == null || !mounted) return;
    final valorStr = valorCtrl.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(valorStr) ?? 0;
    if (valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Informe um valor válido.'),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final dataStr = '${vencimento.year}-${vencimento.month.toString().padLeft(2,'0')}-${vencimento.day.toString().padLeft(2,'0')}';
    try {
      await dio.post('/api/financeiro', data: {
        'alunoId': alunoId,
        'tipo': tipo,
        'valor': valor,
        'dataVencimento': dataStr,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Cobrança criada com sucesso!'),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
        ));
        _load();
      }
    } catch (e) {
      String msg = 'Erro ao criar cobrança.';
      try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _gerarCobrancas() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
            Row(children: [
              Icon(Icons.receipt_long_rounded, color: kPrimary, size: 22),
              const SizedBox(width: 10),
              Text('Gerar Cobranças',
                  style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            Text(
              'Isso gerará as cobranças mensais para todos os alunos ativos que ainda não possuem cobrança em ${_meses[_mes - 1]}/$_ano.',
              style: TextStyle(color: kText2, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Gerar cobranças agora',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: kText2,
                side: BorderSide(color: kBorder),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await dio.post('/api/financeiro/gerar-cobrancas',
          data: {'ano': _ano, 'mes': _mes});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Cobranças geradas com sucesso!'),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
        ));
        _load();
      }
    } catch (e) {
      String msg = 'Erro ao gerar cobranças.';
      try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _marcarPago(Map<String, dynamic> c) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20, left: 0),
                decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
            Text('Marcar como pago', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('${c['nomeAluno']} · ${c['tipo']}', style: TextStyle(color: kText2, fontSize: 13)),
            Text('R\$ ${((c['valor'] as num?) ?? 0).toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: kSuccess,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirmar pagamento', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: kText2,
                side: BorderSide(color: kBorder),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final now = DateTime.now();
      final dataStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await dio.patch('/api/financeiro/${c['id']}', data: {'status': 1, 'dataPagamento': dataStr});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${c['nomeAluno']} marcado como pago!'),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
        ));
        _load();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Erro ao atualizar pagamento.'),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _resumo;
    final isAtual = DateTime.now().year == _ano && DateTime.now().month == _mes;
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton(
        onPressed: _criarCobrancaAvulsa,
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
                  if (_loading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Financeiro', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => context.push('/admin/financeiro/relatorio'),
                                icon: Icon(Icons.bar_chart_rounded, color: kText2, size: 22),
                                tooltip: 'Relatório Anual',
                              ),
                              TextButton.icon(
                                onPressed: _gerarCobrancas,
                                icon: Icon(Icons.receipt_long_rounded, size: 16, color: kPrimary),
                                label: Text('Gerar cobranças',
                                    style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                style: TextButton.styleFrom(
                                  backgroundColor: kPrimary.withOpacity(0.10),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => _navMes(-1),
                              icon: Icon(Icons.chevron_left, color: kText1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Column(
                              children: [
                                Text(
                                  '${_meses[_mes - 1]} $_ano',
                                  style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                                if (isAtual)
                                  Text('Mês atual', style: TextStyle(color: kPrimary, fontSize: 11)),
                              ],
                            ),
                            IconButton(
                              onPressed: isAtual ? null : () => _navMes(1),
                              icon: Icon(Icons.chevron_right, color: isAtual ? kBorder : kText1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (r != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      sliver: SliverGrid.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                        children: [
                          _met('Recebido', 'R\$ ${((r['totalRecebidoMes'] as num?) ?? 0).toStringAsFixed(0)}', kSuccess),
                          _met('Pendente', 'R\$ ${((r['totalPendenteMes'] as num?) ?? 0).toStringAsFixed(0)}', kWarning),
                          _met('Atrasado', 'R\$ ${((r['totalAtrasado'] as num?) ?? 0).toStringAsFixed(0)}', kDanger),
                          _met('Inadimplentes', '${r['alunosInadimplentes'] ?? 0}', kDanger),
                        ],
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Text(
                        _cobrancas.isEmpty ? 'Nenhuma cobrança neste período.' : 'Cobranças · ${_cobrancas.length}',
                        style: TextStyle(color: kText2, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final c = _cobrancas[i];
                        final status = c['status'] as String?;
                        String? dataStr;
                        if (c['dataVencimento'] != null) {
                          try {
                            final dt = DateTime.parse(c['dataVencimento']);
                            dataStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                          } catch (_) {}
                        }
                        final isPago = status == 'Pago';
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: !isPago ? _statusCor(status).withOpacity(0.3) : kBorder),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c['nomeAluno'] ?? '', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
                                          Text(
                                            [c['tipo'], if (dataStr != null) 'Venc. $dataStr'].join(' · '),
                                            style: TextStyle(color: kText2, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'R\$ ${((c['valor'] as num?) ?? 0).toStringAsFixed(2).replaceAll('.', ',')}',
                                          style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700),
                                        ),
                                        Text(status ?? '', style: TextStyle(color: _statusCor(status), fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!isPago)
                                InkWell(
                                  onTap: () => _marcarPago(c),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: kSuccess.withOpacity(0.08),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_outline_rounded, color: kSuccess, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Marcar como pago', style: TextStyle(color: kSuccess, fontSize: 13, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                      childCount: _cobrancas.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: AdBannerWidget()),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ], // end else
            ],
          ),
        ),
      ),
    );
  }

  Widget _met(String label, String value, Color color) => Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: kText2, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      );
}
