import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';
import '../../core/tab_refresh.dart';

class ProfDashboardScreen extends StatefulWidget {
  const ProfDashboardScreen({super.key});

  @override
  State<ProfDashboardScreen> createState() => _ProfDashboardScreenState();
}

class _ProfDashboardScreenState extends State<ProfDashboardScreen> {
  bool _loading = true;
  String? _nome;
  int _totalTurmas = 0;
  int _totalAlunos = 0;
  int _turmasComoAluno = 0;
  List<Map<String, dynamic>> _aulasHoje = [];

  static const _diaNomes = [
    'Domingo',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
  ];

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
    if (mounted) setState(() => _loading = true);
    try {
      final user = await AuthStorage.getUser();
      if (user == null || user.academiaId == null) return;
      final academiaId = user.academiaId!;
      _nome = user.nome;

      final verTodas = user.temPermissao('acesso_turmas_todas');
      final alunoUsuarioId =
          user.perfis.firstWhere(
                (p) => p['colecao'] == 'usuarios',
                orElse: () => const {},
              )['usuarioId']
              as String?;

      final results = await Future.wait([
        firestoreService.getTurmas(
          academiaId,
          professorId: verTodas ? null : user.id,
        ),
        firestoreService.getMatriculas(academiaId, ativasOnly: true),
        firestoreService.getHorarios(academiaId),
      ]);
      final turmas = (results[0] as List).cast<Map<String, dynamic>>();
      final matriculas = (results[1] as List).cast<Map<String, dynamic>>();
      final horarios = (results[2] as List).cast<Map<String, dynamic>>();

      final turmaIds = turmas.map((t) => t['id']?.toString() ?? '').toSet();
      final totalAlunos = matriculas
          .where((m) => turmaIds.contains(m['turma_id']?.toString() ?? ''))
          .length;
      final turmasComoAluno = alunoUsuarioId == null
          ? 0
          : matriculas
                .where((m) => m['aluno_id']?.toString() == alunoUsuarioId)
                .length;

      final hojeIdx =
          DateTime.now().weekday %
          7; // DateTime: Mon=1..Sun=7 → converte pra 0=Domingo
      final aulasHoje =
          horarios.where((h) {
            final profId =
                h['professor_id']?.toString() ??
                h['professorId']?.toString() ??
                '';
            if (profId != user.id) return false;
            final dia = h['dia_semana'] ?? h['diaSemana'];
            return dia is int && dia == hojeIdx;
          }).toList()..sort((a, b) {
            final ha = (a['hora_inicio'] ?? a['horaInicio'] ?? '').toString();
            final hb = (b['hora_inicio'] ?? b['horaInicio'] ?? '').toString();
            return ha.compareTo(hb);
          });

      if (mounted) {
        setState(() {
          _totalTurmas = turmas.length;
          _totalAlunos = totalAlunos;
          _turmasComoAluno = turmasComoAluno;
          _aulasHoje = aulasHoje;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _hora(Map<String, dynamic> h, String field, String fallback) {
    final val = (h[field] ?? h[fallback] ?? '').toString();
    return val.length >= 5 ? val.substring(0, 5) : val;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: kPrimary))
            : RefreshIndicator(
                onRefresh: _load,
                color: kPrimary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: openAppDrawer,
                          child: Icon(
                            Icons.menu_rounded,
                            color: kText1,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dashboard',
                                style: TextStyle(
                                  color: kText1,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (_nome != null)
                                Text(
                                  _nome!,
                                  style: TextStyle(color: kText2, fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Turmas',
                            '$_totalTurmas',
                            Icons.groups_rounded,
                            kPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            'Alunos',
                            '$_totalAlunos',
                            Icons.sports_martial_arts,
                            kSuccess,
                          ),
                        ),
                      ],
                    ),
                    if (_turmasComoAluno > 0) ...[
                      const SizedBox(height: 10),
                      _statCard(
                        'Você também treina em $_turmasComoAluno turma(s)',
                        '',
                        Icons.emoji_events_rounded,
                        kWarning,
                        wide: true,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Aulas de hoje',
                      style: TextStyle(
                        color: kText2,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_aulasHoje.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              color: kText2,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Nenhuma aula hoje.',
                              style: TextStyle(color: kText2, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._aulasHoje.map((h) {
                        final turma =
                            h['nome_turma']?.toString() ??
                            h['nomeTurma']?.toString() ??
                            '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _hora(h, 'hora_inicio', 'horaInicio'),
                                  style: TextStyle(
                                    color: kPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  turma,
                                  style: TextStyle(
                                    color: kText1,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/professor/turmas'),
                        icon: Icon(
                          Icons.groups_rounded,
                          color: kPrimary,
                          size: 18,
                        ),
                        label: Text(
                          'Ver minhas turmas',
                          style: TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: kBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color cor, {
    bool wide = false,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder),
    ),
    child: wide
        ? Row(
            children: [
              Icon(icon, color: cor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: kText1,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: cor, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: kText1,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: TextStyle(color: kText2, fontSize: 12)),
            ],
          ),
  );
}
