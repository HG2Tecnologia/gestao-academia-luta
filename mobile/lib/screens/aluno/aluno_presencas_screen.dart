import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/widgets.dart';

class AlunoPresencasScreen extends StatefulWidget {
  const AlunoPresencasScreen({super.key});

  @override
  State<AlunoPresencasScreen> createState() => _AlunoPresencasScreenState();
}

class _AlunoPresencasScreenState extends State<AlunoPresencasScreen> {
  List<Map<String, dynamic>> _presencas = [];
  bool _loading = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await dio.get('/api/alunos/me');
      final alunoId = (me.data['dados'] as Map<String, dynamic>?)?['id'] ?? '';
      final hoje = DateTime.now();
      final ate = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      final deDate = hoje.subtract(const Duration(days: 365 * 3));
      final de = '${deDate.year}-${deDate.month.toString().padLeft(2, '0')}-${deDate.day.toString().padLeft(2, '0')}';
      final res = await dio.get('/api/presencas', queryParameters: {'alunoId': alunoId, 'de': de, 'ate': ate});
      final dados = res.data['dados'];
      final list = dados is List ? dados : (dados is Map ? dados['items'] as List? ?? [] : []);
      if (mounted) setState(() => _presencas = list.cast<Map<String, dynamic>>());
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime? _parseDate(String? s) {
    if (s == null) return null;
    try { return DateTime.parse(s); } catch (_) { return null; }
  }

  String _fmtDate(String? s) {
    final dt = _parseDate(s);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _mesAno(DateTime dt) {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${meses[dt.month - 1]} ${dt.year}';
  }

  // Group by month-year
  Map<String, List<Map<String, dynamic>>> _grouped() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final p in _presencas) {
      final dt = _parseDate(p['data']?.toString());
      final key = dt != null ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}' : 'outros';
      map.putIfAbsent(key, () => []).add(p);
    }
    // Sort descending
    final sorted = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sorted);
  }

  int _mesAtual() {
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return _grouped()[key]?.length ?? 0;
  }

  int _streak() {
    if (_presencas.isEmpty) return 0;
    final datas = _presencas
        .map((p) => _parseDate(p['data']?.toString()))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (datas.isEmpty) return 0;
    int streak = 1;
    for (var i = 1; i < datas.length; i++) {
      final diff = datas[i - 1].difference(datas[i]).inDays;
      if (diff <= 7) { // within a week = still on streak
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(backgroundColor: kBg, body: Center(child: CircularProgressIndicator(color: kPrimary)));
    }
    if (_erro && _presencas.isEmpty) {
      return Scaffold(backgroundColor: kBg, body: SafeArea(child: ErroConexao(onRetry: () { setState(() { _loading = true; _erro = false; }); _load(); })));
    }

    final grouped = _grouped();
    final groups = grouped.entries.toList();
    final total = _presencas.length;
    final esteMes = _mesAtual();
    final streakSemanas = _streak();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
                      const SizedBox(width: 14),
                      Text('Presenças', style: TextStyle(color: kText1, fontSize: 26, fontWeight: FontWeight.w900)),
                    ]),
                    const SizedBox(height: 4),
                    Text('Seu histórico de treinos',
                        style: TextStyle(color: kText2, fontSize: 13)),
                  ],
                ),
              ),
            ),

            // ── Stats row ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(
                  children: [
                    _bigStat('$total', 'Total de treinos', kPrimary, Icons.check_circle_rounded),
                    const SizedBox(width: 10),
                    _bigStat('$esteMes', 'Este mês', kSuccess, Icons.calendar_today_rounded),
                    const SizedBox(width: 10),
                    _bigStat('$streakSemanas', 'Semanas ativas', kWarning, Icons.local_fire_department_rounded),
                  ],
                ),
              ),
            ),

            // ── Section title ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text('HISTÓRICO',
                    style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              ),
            ),

            // ── Grouped list ──────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, gi) {
                  final entry = groups[gi];
                  final key = entry.key;
                  final items = entry.value;
                  final firstDate = _parseDate(items.first['data']?.toString());
                  final label = firstDate != null ? _mesAno(firstDate) : key;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Row(
                          children: [
                            Text(label,
                                style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${items.length}',
                                  style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                      // Presence items
                      ...items.map((p) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: kSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: kSuccess.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.check_rounded, color: kSuccess, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p['nomeTurma'] ?? p['turma'] ?? '—',
                                            style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
                                        if ((p['horaCheckin'] as String?) != null)
                                          Text(p['horaCheckin'].toString().substring(0, 5),
                                              style: TextStyle(color: kText2, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Text(_fmtDate(p['data']?.toString()),
                                      style: TextStyle(color: kText2, fontSize: 12)),
                                ],
                              ),
                            ),
                          )),
                      if (gi < groups.length - 1) const SizedBox(height: 8),
                    ],
                  );
                },
                childCount: groups.length,
              ),
            ),

            if (_presencas.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(children: [
                      Icon(Icons.sports_martial_arts_rounded, color: kBorder, size: 64),
                      const SizedBox(height: 16),
                      Text('Nenhuma presença registrada ainda',
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

  Widget _bigStat(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: kText2, fontSize: 10),
                maxLines: 2),
          ],
        ),
      ),
    );
  }
}
