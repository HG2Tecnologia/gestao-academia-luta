import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';

class AlunoHorariosScreen extends StatefulWidget {
  const AlunoHorariosScreen({super.key});

  @override
  State<AlunoHorariosScreen> createState() => _AlunoHorariosScreenState();
}

class _AlunoHorariosScreenState extends State<AlunoHorariosScreen> {
  Map<String, List<Map<String, dynamic>>> _grouped = {};
  Set<String> _minhasTurmas = {};
  bool _loading = true;
  String? _diaAtivo;

  static const _ordem = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
  static const _abrev = {'Segunda': 'Seg', 'Terça': 'Ter', 'Quarta': 'Qua', 'Quinta': 'Qui', 'Sexta': 'Sex', 'Sábado': 'Sáb', 'Domingo': 'Dom'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        dio.get('/api/horarios'),
        dio.get('/api/alunos/me'),
      ]);
      final hList = results[0].data['dados'];
      final list = (hList is List ? hList : []).cast<Map<String, dynamic>>();
      final turmasAluno = ((results[1].data['dados'] as Map<String, dynamic>?)?['turmas'] as List? ?? []).cast<String>();

      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final h in list) {
        final dia = (h['diaSemanaLabel'] ?? h['diaSemana'])?.toString() ?? '';
        grouped.putIfAbsent(dia, () => []).add(h);
      }

      // Sort each day by time
      for (final k in grouped.keys) {
        grouped[k]!.sort((a, b) =>
            (a['horaInicio'] as String? ?? '').compareTo(b['horaInicio'] as String? ?? ''));
      }

      if (mounted) {
        final dias = _ordem.where((d) => grouped.containsKey(d)).toList();
        setState(() {
          _grouped = grouped;
          _minhasTurmas = turmasAluno.toSet();
          _diaAtivo = _hojeOuPrimeiro(dias);
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _hojeOuPrimeiro(List<String> dias) {
    const hoje = {1: 'Segunda', 2: 'Terça', 3: 'Quarta', 4: 'Quinta', 5: 'Sexta', 6: 'Sábado', 7: 'Domingo'};
    final diaHoje = hoje[DateTime.now().weekday];
    if (diaHoje != null && dias.contains(diaHoje)) return diaHoje;
    return dias.isNotEmpty ? dias.first : '';
  }

  String _fmt(String? t) => t?.length != null && t!.length >= 5 ? t.substring(0, 5) : (t ?? '');

  bool _isHoje(String dia) {
    const hoje = {1: 'Segunda', 2: 'Terça', 3: 'Quarta', 4: 'Quinta', 5: 'Sexta', 6: 'Sábado', 7: 'Domingo'};
    return hoje[DateTime.now().weekday] == dia;
  }

  @override
  Widget build(BuildContext context) {
    final dias = _ordem.where((d) => _grouped.containsKey(d)).toList();
    final horarios = _diaAtivo != null ? (_grouped[_diaAtivo] ?? []) : <Map<String, dynamic>>[];
    final minhas = horarios.where((h) => _minhasTurmas.contains(h['nomeTurma'] as String? ?? '')).toList();
    final outras = horarios.where((h) => !_minhasTurmas.contains(h['nomeTurma'] as String? ?? '')).toList();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 20, 4),
              child: Row(children: [
                GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
                const SizedBox(width: 14),
                Text('Horários', style: TextStyle(color: kText1, fontSize: 26, fontWeight: FontWeight.w900)),
              ]),
            ),

            // ── Day chips ───────────────────────────────
            SizedBox(
              height: 56,
              child: _loading
                  ? const SizedBox()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: dias.length,
                      itemBuilder: (_, i) {
                        final dia = dias[i];
                        final sel = _diaAtivo == dia;
                        final hoje = _isHoje(dia);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _diaAtivo = dia),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: sel ? kPrimary : kSurface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel ? kPrimary : (hoje ? kPrimary.withOpacity(0.4) : kBorder),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _abrev[dia] ?? dia,
                                    style: TextStyle(
                                      color: sel ? Colors.white : (hoje ? kPrimary : kText2),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (hoje && !sel)
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── Content ──────────────────────────────────
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: kPrimary))
                  : horarios.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_busy_rounded, color: kBorder, size: 56),
                              const SizedBox(height: 16),
                              Text('Sem aulas nesse dia',
                                  style: TextStyle(color: kText2, fontSize: 14)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: kPrimary,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            if (minhas.isNotEmpty) ...[
                              _sectionLabel('MINHAS AULAS', kPrimary),
                              ...minhas.map((h) => _horarioCard(h, true)),
                              const SizedBox(height: 8),
                            ],
                            if (outras.isNotEmpty) ...[
                              _sectionLabel('OUTRAS AULAS', kText2),
                              ...outras.map((h) => _horarioCard(h, false)),
                            ],
                          ],
                        ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color cor) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(label,
            style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      );

  Widget _horarioCard(Map<String, dynamic> h, bool isMinha) {
    final nome = h['nomeTurma'] as String? ?? '';
    final prof = h['nomeProfessor'] as String?;
    final inicio = _fmt(h['horaInicio'] as String?);
    final fim = _fmt(h['horaFim'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMinha ? kPrimary.withOpacity(0.4) : kBorder,
          width: isMinha ? 1.5 : 1.0,
        ),
      ),
      child: Opacity(
        opacity: isMinha ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Time block
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isMinha ? kPrimary.withOpacity(0.15) : kBorder.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(inicio,
                        style: TextStyle(
                          color: isMinha ? kPrimary : kText2,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        )),
                    Container(width: 20, height: 1, color: isMinha ? kPrimary.withOpacity(0.4) : kBorder, margin: const EdgeInsets.symmetric(vertical: 3)),
                    Text(fim,
                        style: TextStyle(
                          color: isMinha ? kPrimary.withOpacity(0.7) : kText2.withOpacity(0.6),
                          fontSize: 11,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome,
                        style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
                    if (prof != null) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.person_outline_rounded, size: 13, color: kText2),
                        const SizedBox(width: 4),
                        Flexible(child: Text('Prof. $prof', style: TextStyle(color: kText2, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  ],
                ),
              ),
              if (isMinha)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
