import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

class AdminRelatorioPresencasScreen extends StatefulWidget {
  const AdminRelatorioPresencasScreen({super.key});

  @override
  State<AdminRelatorioPresencasScreen> createState() => _AdminRelatorioPresencasScreenState();
}

class _AdminRelatorioPresencasScreenState extends State<AdminRelatorioPresencasScreen> {
  List<Map<String, dynamic>> _turmas = [];
  String? _turmaId;
  Map<String, dynamic>? _relatorio;
  bool _loadingTurmas = true;
  bool _loading = false;
  bool _erro = false;

  DateTime _de = DateTime.now().subtract(const Duration(days: 30));
  DateTime _ate = DateTime.now();

  static const _presets = [
    ('Últimos 30 dias', 30),
    ('Últimos 60 dias', 60),
    ('Últimos 90 dias', 90),
  ];

  @override
  void initState() {
    super.initState();
    _loadTurmas();
  }

  Future<void> _loadTurmas() async {
    try {
      final res = await dio.get('/api/turmas');
      final raw = res.data['dados'];
      final list = raw is List ? raw : (raw as Map?)?['itens'] as List? ?? [];
      final turmas = list.cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _turmas = turmas;
        _turmaId = turmas.isNotEmpty ? turmas.first['id']?.toString() : null;
        _loadingTurmas = false;
      });
      if (_turmaId != null) _loadRelatorio();
    } catch (_) {
      if (mounted) setState(() { _loadingTurmas = false; });
    }
  }

  Future<void> _loadRelatorio() async {
    if (_turmaId == null) return;
    setState(() { _loading = true; _erro = false; });
    final fmt = DateFormat('yyyy-MM-dd');
    try {
      final res = await dio.get('/api/presencas/relatorio', queryParameters: {
        'turmaId': _turmaId,
        'de': fmt.format(_de),
        'ate': fmt.format(_ate),
      });
      final dados = res.data['dados'] as Map<String, dynamic>?;
      if (mounted) setState(() { _relatorio = dados; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _erro = true; _loading = false; });
    }
  }

  void _aplicarPreset(int dias) {
    setState(() {
      _ate = DateTime.now();
      _de = _ate.subtract(Duration(days: dias));
    });
    _loadRelatorio();
  }

  Future<void> _selecionarPeriodo() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _de, end: _ate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: kPrimary,
            surface: kSurface,
            onSurface: kText1,
          ),
        ),
        child: child!,
      ),
    );
    if (range == null) return;
    setState(() { _de = range.start; _ate = range.end; });
    _loadRelatorio();
  }

  List<Map<String, dynamic>> get _alunos {
    final raw = _relatorio?['alunos'];
    if (raw == null) return [];
    final list = (raw as List).cast<Map<String, dynamic>>();
    list.sort((a, b) => ((b['percentual'] as num?) ?? 0).compareTo((a['percentual'] as num?) ?? 0));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy');
    final totalAulas = _relatorio?['totalAulas'] as int? ?? 0;
    final media = (_relatorio?['mediaFrequencia'] as num? ?? 0).toDouble();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kText1, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Relatório de Presenças', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: _loadingTurmas
          ? const Center(child: CircularProgressIndicator())
          : _turmas.isEmpty
              ? Center(child: Text('Nenhuma turma encontrada', style: TextStyle(color: kText2)))
              : Column(
                  children: [
                    Container(
                      color: kSurface,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: kBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kPrimary.withOpacity(0.5)),
                            ),
                            child: DropdownButton<String>(
                              value: _turmaId,
                              isExpanded: true,
                              dropdownColor: kSurface,
                              underline: const SizedBox(),
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: kPrimary),
                              style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                              items: _turmas.map((t) {
                                final id = t['id']?.toString();
                                return DropdownMenuItem<String>(
                                  value: id,
                                  child: Text(t['nome']?.toString() ?? '', style: TextStyle(color: kText1, fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (id) {
                                setState(() => _turmaId = id);
                                _loadRelatorio();
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ..._presets.map((p) => _PresetChip(
                                label: p.$1,
                                onTap: () => _aplicarPreset(p.$2),
                              )),
                              GestureDetector(
                                onTap: _selecionarPeriodo,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: kBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.date_range_rounded, color: kText2, size: 14),
                                      const SizedBox(width: 4),
                                      Text('${fmt.format(_de)} – ${fmt.format(_ate)}',
                                          style: TextStyle(color: kText2, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _erro
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline_rounded, color: kDanger, size: 52),
                                      const SizedBox(height: 14),
                                      Text('Não foi possível carregar', style: TextStyle(color: kText2)),
                                      const SizedBox(height: 18),
                                      OutlinedButton.icon(
                                        onPressed: _loadRelatorio,
                                        icon: const Icon(Icons.refresh_rounded),
                                        label: const Text('Tentar novamente'),
                                        style: OutlinedButton.styleFrom(foregroundColor: kPrimary),
                                      ),
                                    ],
                                  ),
                                )
                              : _relatorio == null
                                  ? const SizedBox()
                                  : ListView(
                                      padding: const EdgeInsets.all(16),
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: _StatCard(
                                              label: 'Total de Aulas',
                                              value: '$totalAulas',
                                              icon: Icons.calendar_month_rounded,
                                              color: kPrimary,
                                            )),
                                            const SizedBox(width: 12),
                                            Expanded(child: _StatCard(
                                              label: 'Média de Freq.',
                                              value: '${media.toStringAsFixed(1)}%',
                                              icon: Icons.bar_chart_rounded,
                                              color: _corFreq(media),
                                            )),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Text('Frequência por Aluno (${_alunos.length})',
                                            style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 12),
                                        if (_alunos.isEmpty)
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
                                            child: Center(child: Text('Nenhuma presença registrada no período', style: TextStyle(color: kText2))),
                                          )
                                        else
                                          ..._alunos.map((a) => _AlunoFreqCard(aluno: a, totalAulas: totalAulas)),
                                      ],
                                    ),
                    ),
                  ],
                ),
    );
  }

  Color _corFreq(double pct) {
    if (pct >= 75) return kSuccess;
    if (pct >= 50) return kWarning;
    return kDanger;
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(color: kText1, fontWeight: FontWeight.w900, fontSize: 22)),
            Text(label, style: TextStyle(color: kText2, fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}

class _AlunoFreqCard extends StatelessWidget {
  const _AlunoFreqCard({required this.aluno, required this.totalAulas});
  final Map<String, dynamic> aluno;
  final int totalAulas;

  Color _cor(double pct) {
    if (pct >= 75) return kSuccess;
    if (pct >= 50) return kWarning;
    return kDanger;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (aluno['percentual'] as num? ?? 0).toDouble();
    final presencas = aluno['presencas'] as int? ?? 0;
    final faltas = aluno['faltas'] as int? ?? 0;
    final cor = _cor(pct);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  aluno['nomeAluno']?.toString() ?? '',
                  style: TextStyle(color: kText1, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(color: cor, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: kBorder,
              valueColor: AlwaysStoppedAnimation<Color>(cor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 13, color: kSuccess),
              const SizedBox(width: 4),
              Text('$presencas presenças', style: TextStyle(color: kText2, fontSize: 11)),
              const SizedBox(width: 12),
              Icon(Icons.cancel_outlined, size: 13, color: kDanger),
              const SizedBox(width: 4),
              Text('$faltas faltas', style: TextStyle(color: kText2, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
