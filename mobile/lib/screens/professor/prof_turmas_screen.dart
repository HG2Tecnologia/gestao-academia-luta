import 'package:flutter/material.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';
import '../../core/tab_refresh.dart';
import 'prof_turma_detalhe_screen.dart';

class ProfTurmasScreen extends StatefulWidget {
  const ProfTurmasScreen({super.key});

  @override
  State<ProfTurmasScreen> createState() => _ProfTurmasScreenState();
}

class _ProfTurmasScreenState extends State<ProfTurmasScreen> {
  List<Map<String, dynamic>> _turmas = [];
  bool _loading = true;
  String? _erro;
  String? _academiaId;

  @override
  void initState() {
    super.initState();
    perfilTrocadoNotifier.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    perfilTrocadoNotifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _erro = null; });
    try {
      final user = await AuthStorage.getUser();
      if (user == null) return;
      _academiaId = user.academiaId;

      // Com a permissão "acesso_turmas_todas" o professor/secretaria vê todas
      // as turmas da academia, não só as que ele é o professor titular.
      final verTodas = user.temPermissao('acesso_turmas_todas');

      // Carrega turmas e matrículas em paralelo para calcular totalAlunos
      final results = await Future.wait([
        firestoreService.getTurmas(user.academiaId!, professorId: verTodas ? null : user.id),
        firestoreService.getMatriculas(user.academiaId!, ativasOnly: true),
      ]);
      final turmasList = (results[0] as List).cast<Map<String, dynamic>>();
      final matriculas = (results[1] as List).cast<Map<String, dynamic>>();

      final countPorTurma = <String, int>{};
      for (final m in matriculas) {
        final tid = m['turma_id']?.toString() ?? '';
        if (tid.isNotEmpty) countPorTurma[tid] = (countPorTurma[tid] ?? 0) + 1;
      }

      // Se essa mesma pessoa também tem um perfil de Aluno (multi-perfil),
      // marca em quais turmas ela está matriculada como aluno também.
      final alunoUsuarioId = user.perfis
          .firstWhere((p) => p['colecao'] == 'usuarios', orElse: () => const {})['usuarioId']
          as String?;
      final turmasComoAluno = <String>{};
      if (alunoUsuarioId != null) {
        for (final m in matriculas) {
          if (m['aluno_id']?.toString() == alunoUsuarioId) {
            turmasComoAluno.add(m['turma_id']?.toString() ?? '');
          }
        }
      }

      final enriched = turmasList.map((t) {
        final id = t['id']?.toString() ?? '';
        return <String, dynamic>{
          ...t,
          'totalAlunos': countPorTurma[id] ?? 0,
          'souProfessor': t['professorId'] == user.id,
          'souAluno': turmasComoAluno.contains(id),
        };
      }).toList();

      if (mounted) setState(() => _turmas = enriched);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Minhas Turmas', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: kPrimary))
                  : _erro != null
                      ? Center(child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_erro!, style: TextStyle(color: kDanger, fontSize: 13), textAlign: TextAlign.center),
                        ))
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: kPrimary,
                          child: _turmas.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 80),
                                    Icon(Icons.groups_outlined, color: kText2, size: 56),
                                    const SizedBox(height: 16),
                                    Text('Nenhuma turma atribuída',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    Text('O administrador ainda não vinculou\nvocê a nenhuma turma.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: kText2, fontSize: 13, height: 1.5)),
                                  ],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _turmas.length,
                                  itemBuilder: (_, i) {
                                    final t = _turmas[i];
                                    return GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProfTurmaDetalheScreen(
                                            turma: t,
                                            academiaId: _academiaId!,
                                          ),
                                        ),
                                      ),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: kSurface,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: kBorder),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(children: [
                                                    Expanded(child: Text(t['nome'] ?? '', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700))),
                                                    if (t['souProfessor'] == true) _papelBadge('Professor', kPrimary),
                                                    if (t['souAluno'] == true) ...[
                                                      const SizedBox(width: 6),
                                                      _papelBadge('Aluno', kSuccess),
                                                    ],
                                                  ]),
                                                  if ((t['nomeModalidade'] ?? t['modalidade_nome']) != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 3),
                                                      child: Text(
                                                        (t['nomeModalidade'] ?? t['modalidade_nome'] ?? '').toString(),
                                                        style: TextStyle(color: kText2, fontSize: 13),
                                                      ),
                                                    ),
                                                  const SizedBox(height: 8),
                                                  Row(children: [
                                                    Text('${t['totalAlunos'] ?? 0}',
                                                        style: TextStyle(color: kPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                                                    Text(' / ${t['capacidadeMaxima'] ?? t['capacidade_maxima'] ?? 0} alunos',
                                                        style: TextStyle(color: kText2, fontSize: 13)),
                                                  ]),
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.chevron_right_rounded, color: kText2),
                                          ],
                                        ),
                                      ),
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

  Widget _papelBadge(String label, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: cor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w700)),
      );
}
