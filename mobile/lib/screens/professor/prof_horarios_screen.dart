import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';

class ProfHorariosScreen extends StatefulWidget {
  const ProfHorariosScreen({super.key});

  @override
  State<ProfHorariosScreen> createState() => _ProfHorariosScreenState();
}

class _ProfHorariosScreenState extends State<ProfHorariosScreen> {
  // Grouped by day name string for display (index 0-6 → name)
  Map<String, List<Map<String, dynamic>>> _grouped = {};
  bool _loading = true;

  // Day names by index (0=Domingo, 1=Segunda, ..., 6=Sábado)
  static const _diaNomes = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
  // Display order (Mon-Sun)
  static const _diasOrdem = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user?.academiaId ?? '';
      final userId = user?.id ?? '';
      if (academiaId.isEmpty) return;

      final list = await firestoreService.getHorarios(academiaId);
      final horarios = list.cast<Map<String, dynamic>>();

      // Filter by professor_id
      final meus = userId.isEmpty
          ? horarios
          : horarios.where((h) {
              final profId = h['professor_id']?.toString() ?? h['professorId']?.toString() ?? '';
              return profId == userId;
            }).toList();

      // Group by day name
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final h in meus) {
        final diaSemanaRaw = h['dia_semana'] ?? h['diaSemana'];
        String diaNome;
        if (diaSemanaRaw is int) {
          diaNome = diaSemanaRaw >= 0 && diaSemanaRaw < _diaNomes.length
              ? _diaNomes[diaSemanaRaw]
              : diaSemanaRaw.toString();
        } else {
          diaNome = diaSemanaRaw?.toString() ?? '';
        }
        if (diaNome.isEmpty) continue;
        grouped.putIfAbsent(diaNome, () => []).add(h);
      }

      // Sort each group by hora_inicio
      for (final key in grouped.keys) {
        grouped[key]!.sort((a, b) {
          final ha = (a['hora_inicio'] ?? a['horaInicio'] ?? '').toString();
          final hb = (b['hora_inicio'] ?? b['horaInicio'] ?? '').toString();
          return ha.compareTo(hb);
        });
      }

      if (mounted) setState(() => _grouped = grouped);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(Map<String, dynamic> h, String field, String fallback) {
    final val = h[field] ?? h[fallback] ?? '';
    final s = val.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  @override
  Widget build(BuildContext context) {
    final dias = _diasOrdem.where((d) => _grouped.containsKey(d)).toList();
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
                  : dias.isEmpty
                      ? Center(child: Text('Nenhum horário encontrado.', style: TextStyle(color: kText2)))
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
                                    final inicio = _fmt(h, 'hora_inicio', 'horaInicio');
                                    final fim = _fmt(h, 'hora_fim', 'horaFim');
                                    final horarioStr = '$inicio - $fim';
                                    final turma = h['nome_turma']?.toString() ?? h['nomeTurma']?.toString() ?? '';
                                    final modalidade = h['nome_modalidade']?.toString() ?? h['nomeModalidade']?.toString();
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
                                                  if (modalidade != null && modalidade.isNotEmpty)
                                                    Text(modalidade, style: TextStyle(color: kText2, fontSize: 12)),
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
