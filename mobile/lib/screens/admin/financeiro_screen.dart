import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/ad_banner.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';
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
  String? _academiaId;

  late int _ano;
  late int _mes;

  static const _meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
  static const _statusMap = {0: 'Pendente', 1: 'Pago', 2: 'Atrasado', 3: 'Previsto'};

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
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId ?? '';
      if (_academiaId!.isEmpty) return;

      final todos = await firestoreService.getPagamentos(_academiaId!);

      // Filter for selected month
      final doMes = todos.where((p) {
        final venc = p['data_vencimento'] as String? ?? '';
        if (venc.isEmpty) return false;
        try {
          final dt = DateTime.parse(venc);
          return dt.year == _ano && dt.month == _mes;
        } catch (_) {
          return false;
        }
      }).toList();

      // Compute resumo client-side
      double recebido = 0, pendente = 0, atrasado = 0;
      final Set<String> inadimplentesSet = {};
      final now = DateTime.now();

      for (final p in todos) {
        final statusRaw = p['status'];
        final statusInt = statusRaw is int ? statusRaw : int.tryParse(statusRaw.toString()) ?? 0;
        final statusStr = _statusMap[statusInt] ?? 'Pendente';
        final valor = (p['valor'] as num? ?? 0).toDouble();
        final venc = p['data_vencimento'] as String? ?? '';
        DateTime? vencDt;
        try { vencDt = DateTime.parse(venc); } catch (_) {}

        if (statusStr == 'Pago') {
          if (vencDt != null && vencDt.year == _ano && vencDt.month == _mes) recebido += valor;
        } else if (statusStr == 'Pendente' || statusStr == 'Previsto') {
          if (vencDt != null && vencDt.year == _ano && vencDt.month == _mes) pendente += valor;
          if (vencDt != null && vencDt.isBefore(now)) {
            atrasado += valor;
            final alunoId = p['aluno_id']?.toString() ?? '';
            if (alunoId.isNotEmpty) inadimplentesSet.add(alunoId);
          }
        }
      }

      // Convert status for display
      final cobrancasComStatus = doMes.map((p) {
        final statusRaw = p['status'];
        final statusInt = statusRaw is int ? statusRaw : int.tryParse(statusRaw.toString()) ?? 0;
        final statusStr = _statusMap[statusInt] ?? 'Pendente';
        final rawNome = (p['nome_aluno'] ?? p['nomeAluno'] ?? p['aluno_nome'] ?? '').toString();
        final rawTipo = p['tipo']?.toString() ?? '';
        return {
          ...p,
          'status': statusStr,
          'nomeAluno': rawNome == 'null' ? '' : rawNome,
          'dataVencimento': p['data_vencimento'] ?? p['dataVencimento'] ?? '',
          'tipo': (rawTipo.isEmpty || rawTipo == 'null') ? 'Mensalidade' : rawTipo,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _resumo = {
            'totalRecebidoMes': recebido,
            'totalPendenteMes': pendente,
            'totalAtrasado': atrasado,
            'alunosInadimplentes': inadimplentesSet.length,
          };
          _cobrancas = cobrancasComStatus.cast<Map<String, dynamic>>();
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

  static final _brl = NumberFormat('#,##0.00', 'pt_BR');
  static final _brlInt = NumberFormat('#,##0', 'pt_BR');

  String _fmtVal(num v) => 'R\$ ${_brl.format(v)}';
  String _fmtInt(num v) => 'R\$ ${_brlInt.format(v)}';

  Color _statusCor(String? s) {
    if (s == 'Pago') return kSuccess;
    if (s == 'Pendente') return kWarning;
    if (s == 'Previsto') return kText2;
    return kDanger;
  }

  Future<void> _criarCobrancaAvulsa() async {
    if (_academiaId == null) return;
    List<Map<String, dynamic>> alunos = [];
    try {
      alunos = await firestoreService.getAlunos(_academiaId!, ativosOnly: true);
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
    // Find aluno name
    final alunoSel = alunos.firstWhere((a) => a['id']?.toString() == alunoId, orElse: () => {});
    final nomeAluno = alunoSel['nome']?.toString() ?? '';
    final tipoStr = tipo == 1 ? 'Mensalidade' : 'Taxa de Matrícula';
    try {
      await firestoreService.addPagamento(_academiaId!, {
        'aluno_id': alunoId,
        'nome_aluno': nomeAluno,
        'tipo': tipoStr,
        'valor': valor,
        'data_vencimento': dataStr,
        'status': 0,
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Erro ao criar cobrança.'),
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
    if (ok != true || !mounted || _academiaId == null) return;
    // Generate individual payment records for all active alunos without existing payment this month
    try {
      final alunos = await firestoreService.getAlunos(_academiaId!, ativosOnly: true);
      final existingIds = _cobrancas.map((c) => c['aluno_id']?.toString() ?? '').toSet();
      int geradas = 0;
      for (final aluno in alunos) {
        final id = aluno['id']?.toString() ?? '';
        if (existingIds.contains(id)) continue;
        final planoValor = (aluno['valor_mensalidade'] as num? ?? aluno['valorMensalidade'] as num? ?? 0).toDouble();
        final vencDia = aluno['dia_vencimento'] as int? ?? 10;
        final dataStr = '$_ano-${_mes.toString().padLeft(2,'0')}-${vencDia.toString().padLeft(2,'0')}';
        await firestoreService.addPagamento(_academiaId!, {
          'aluno_id': id,
          'nome_aluno': aluno['nome']?.toString() ?? '',
          'tipo': 'Mensalidade',
          'valor': planoValor,
          'data_vencimento': dataStr,
          'status': 0,
        });
        geradas++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$geradas cobranças geradas com sucesso!'),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
        ));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Erro ao gerar cobranças.'),
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
            Text(_fmtVal((c['valor'] as num?) ?? 0),
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
    if (ok != true || !mounted || _academiaId == null) return;
    try {
      final now = DateTime.now();
      final dataStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await firestoreService.updatePagamento(_academiaId!, c['id'].toString(), {
        'status': 1,
        'data_pagamento': dataStr,
      });
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Financeiro', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
                              const Spacer(),
                              GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.push('/admin/financeiro/relatorio'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: kSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bar_chart_rounded, color: kText2, size: 14),
                                      const SizedBox(width: 5),
                                      Text('Relatório', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                          _met('Recebido', _fmtInt((r['totalRecebidoMes'] as num?) ?? 0), kSuccess),
                          _met('Pendente', _fmtInt((r['totalPendenteMes'] as num?) ?? 0), kWarning),
                          _met('Atrasado', _fmtInt((r['totalAtrasado'] as num?) ?? 0), kDanger),
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
                        final rawVenc = c['dataVencimento'] ?? c['data_vencimento'];
                        if (rawVenc != null) {
                          try {
                            final dt = DateTime.parse(rawVenc.toString());
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
                                          _fmtVal((c['valor'] as num?) ?? 0),
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
