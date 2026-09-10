import 'package:flutter/material.dart';
import '../../core/theme/context_ext.dart';
import '../../core/firestore_service.dart';
import 'prof_presenca_screen.dart';

class ProfTurmaDetalheScreen extends StatefulWidget {
  final Map<String, dynamic> turma;
  final String academiaId;

  const ProfTurmaDetalheScreen({
    super.key,
    required this.turma,
    required this.academiaId,
  });

  @override
  State<ProfTurmaDetalheScreen> createState() => _ProfTurmaDetalheScreenState();
}

class _ProfTurmaDetalheScreenState extends State<ProfTurmaDetalheScreen> {
  List<Map<String, dynamic>> _alunos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final turmaId = widget.turma['id'].toString();
      final matriculas = await firestoreService.getMatriculas(
        widget.academiaId,
        turmaId: turmaId,
        ativasOnly: true,
      );
      final alunos = <Map<String, dynamic>>[];
      for (final m in matriculas) {
        final alunoId = m['aluno_id'] as String? ?? '';
        if (alunoId.isEmpty) continue;
        final aluno = await firestoreService.getAluno(
          widget.academiaId,
          alunoId,
        );
        if (aluno != null) alunos.add(aluno);
      }
      alunos.sort(
        (a, b) =>
            (a['nome'] as String? ?? '').compareTo(b['nome'] as String? ?? ''),
      );
      if (mounted) setState(() => _alunos = alunos);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final turma = widget.turma;
    final nomeTurma = turma['nome']?.toString() ?? '';
    final modalidade =
        (turma['nomeModalidade'] ?? turma['modalidade_nome'] ?? '').toString();
    final total = turma['totalAlunos'] ?? _alunos.length;
    final capacidade =
        turma['capacidadeMaxima'] ?? turma['capacidade_maxima'] ?? 0;

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: context.c.onSurface,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      nomeTurma,
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.c.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.c.outline),
                ),
                child: Row(
                  children: [
                    if (modalidade.isNotEmpty) ...[
                      Icon(
                        Icons.sports_martial_arts_rounded,
                        color: context.c.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          modalidade,
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.c.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$total / $capacidade alunos',
                        style: TextStyle(
                          color: context.c.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Text(
                context.l10n.tdEnrolledStudents,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.c.primary,
                      ),
                    )
                  : _alunos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_off_rounded,
                            color: context.c.onSurfaceVariant,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.profNoStudentsEnrolled,
                            style: TextStyle(
                              color: context.c.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: context.c.primary,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _alunos.length,
                        itemBuilder: (_, i) {
                          final a = _alunos[i];
                          final nome = (a['nome'] as String? ?? '');
                          final initials = nome
                              .trim()
                              .split(RegExp(r'\s+'))
                              .take(2)
                              .map((w) => w.isNotEmpty ? w[0] : '')
                              .join()
                              .toUpperCase();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.c.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.c.outline),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: context.c.primary.withAlpha(
                                    30,
                                  ),
                                  child: Text(
                                    initials.isEmpty ? '?' : initials,
                                    style: TextStyle(
                                      color: context.c.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    nome,
                                    style: TextStyle(
                                      color: context.c.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),

            // Botão registrar presença
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfPresencaScreen()),
                ),
                icon: Icon(Icons.fact_check_rounded),
                label: Text(
                  context.l10n.takeAttendance,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.c.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
