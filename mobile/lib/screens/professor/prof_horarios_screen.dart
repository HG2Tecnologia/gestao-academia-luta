import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';

class ProfHorariosScreen extends StatefulWidget {
  const ProfHorariosScreen({super.key});

  @override
  State<ProfHorariosScreen> createState() => _ProfHorariosScreenState();
}

class _ProfHorariosScreenState extends State<ProfHorariosScreen> {
  Map<String, List<Map<String, dynamic>>> _grouped = {};
  bool _loading = true;

  static const _dias = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await dio.get('/api/horarios/meus');
      final body = res.data as Map<String, dynamic>;
      final dados = body['dados'];
      final list = (dados is List ? dados : []).cast<Map<String, dynamic>>();
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final h in list) {
        final dia = h['diaSemana'] as String? ?? '';
        grouped.putIfAbsent(dia, () => []).add(h);
      }
      if (mounted) setState(() => _grouped = grouped);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(String? t) => t?.substring(0, 5) ?? '';

  @override
  Widget build(BuildContext context) {
    final dias = _dias.where((d) => _grouped.containsKey(d)).toList();
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(children: [
                GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
                const SizedBox(width: 14),
                Text('Meus Horários', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: kPrimary))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: kPrimary,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: dias.length,
                      itemBuilder: (_, i) {
                        final dia = dias[i];
                        final horarios = _grouped[dia]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 4),
                              child: Text(dia, style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                            ...horarios.map((h) {
                              final horarioStr = '${_fmt(h['horaInicio'])} - ${_fmt(h['horaFim'])}';
                              final turma = h['nomeTurma'] as String? ?? '';
                              return GestureDetector(
                                onTap: () {
                                  final uri = Uri(
                                    path: '/professor/horarios/${h['id']}/presencas',
                                    queryParameters: {'turma': turma, 'horario': horarioStr},
                                  );
                                  context.push(uri.toString());
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: kSurface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: kPrimary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          horarioStr,
                                          style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(turma, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
                                            if (h['nomeModalidade'] != null)
                                              Text(h['nomeModalidade'], style: TextStyle(color: kText2, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded, color: kText2, size: 18),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
