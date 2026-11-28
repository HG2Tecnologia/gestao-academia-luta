import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../core/firestore_service.dart';
import '../../core/perfil_switch.dart';
import '../../core/tab_refresh.dart';
import '../admin/widgets/dashboard_widgets.dart';

class ProfDashboardScreen extends StatefulWidget {
  const ProfDashboardScreen({super.key});

  @override
  State<ProfDashboardScreen> createState() => _ProfDashboardScreenState();
}

class _ProfDashboardScreenState extends State<ProfDashboardScreen> {
  bool _loading = true;
  String? _nome;
  String? _fotoBase64;
  List<Map<String, dynamic>> _perfis = [];
  int _totalTurmas = 0;
  int _totalAlunos = 0;
  int _turmasComoAluno = 0;
  List<Map<String, dynamic>> _aulasHoje = [];
  final Set<String> _perms = {};

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
      _perfis = user.perfis;

      _perms.clear();
      for (final k in const [
        'tela_turmas',
        'tela_alunos',
        'tela_horarios',
        'tela_rankings',
      ]) {
        if (user.temPermissao(k)) _perms.add(k);
      }

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
        firestoreService
            .getFuncionario(academiaId, user.id)
            .catchError((_) => null),
      ]);
      final turmas = (results[0] as List).cast<Map<String, dynamic>>();
      final meuDoc = results[3] as Map<String, dynamic>?;
      _fotoBase64 = meuDoc?['fotoBase64'] as String?;
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

  String get _primeiroNome => (_nome ?? '').trim().split(' ').first;

  String _hora(Map<String, dynamic> h, String field, String fallback) {
    final val = (h[field] ?? h[fallback] ?? '').toString();
    return val.length >= 5 ? val.substring(0, 5) : val;
  }

  List<(IconData, String, String, DashTone)> get _acessos => [
    if (_perms.contains('tela_turmas'))
      (
        Icons.groups_rounded,
        context.l10n.navClasses,
        '/professor/turmas',
        DashTone.gold,
      ),
    if (_perms.contains('tela_alunos'))
      (
        Icons.sports_martial_arts,
        context.l10n.navStudents,
        '/professor/alunos',
        DashTone.success,
      ),
    if (_perms.contains('tela_horarios'))
      (
        Icons.schedule_rounded,
        context.l10n.navSchedule,
        '/professor/horarios',
        DashTone.info,
      ),
    if (_perms.contains('tela_rankings'))
      (
        Icons.emoji_events_rounded,
        context.l10n.navRanking,
        '/professor/rankings',
        DashTone.warning,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: context.c.primary))
            : RefreshIndicator(
                onRefresh: _load,
                color: context.c.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        _Avatar(fotoBase64: _fotoBase64, nome: _nome ?? ''),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _primeiroNome.isEmpty
                                    ? 'Olá!'
                                    : context.l10n.apHelloName(_primeiroNome),
                                style: TextStyle(
                                  color: context.c.onSurface,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                context.l10n.profPanelSubtitle,
                                style: TextStyle(
                                  color: context.c.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_perfis.length > 1)
                          PerfilSwitchButton(
                            onPressed: () async {
                              await mostrarTrocarPerfil(context);
                              _load();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DashMetricCard(
                            icon: Icons.groups_rounded,
                            value: '$_totalTurmas',
                            label: context.l10n.navClasses,
                            tone: DashTone.gold,
                            onTap: () => context.go('/professor/turmas'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DashMetricCard(
                            icon: Icons.sports_martial_arts,
                            value: '$_totalAlunos',
                            label: context.l10n.navStudents,
                            tone: DashTone.success,
                            onTap: () => context.go('/professor/alunos'),
                          ),
                        ),
                      ],
                    ),
                    if (_turmasComoAluno > 0) ...[
                      const SizedBox(height: 12),
                      DashCard(
                        tone: DashTone.warning,
                        child: Row(
                          children: [
                            Icon(
                              Icons.emoji_events_rounded,
                              color: context.sem.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.l10n.profAlsoTrainsIn(_turmasComoAluno),
                                style: TextStyle(
                                  color: context.c.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_acessos.isNotEmpty) ...[
                      DashSectionHeader(
                        context.l10n.profQuickAccess,
                        padding: const EdgeInsets.fromLTRB(0, 24, 0, 10),
                      ),
                      Row(
                        children: [
                          for (final a in _acessos)
                            DashQuickAction(
                              icon: a.$1,
                              label: a.$2,
                              tone: a.$4,
                              onTap: () => context.go(a.$3),
                            ),
                        ],
                      ),
                    ],
                    DashSectionHeader(
                      context.l10n.profTodayClasses,
                      padding: const EdgeInsets.fromLTRB(0, 24, 0, 10),
                    ),
                    if (_aulasHoje.isEmpty)
                      DashCard(
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              color: context.c.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.l10n.profNoClassToday,
                              style: TextStyle(
                                color: context.c.onSurfaceVariant,
                                fontSize: 13,
                              ),
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DashCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.c.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _hora(h, 'hora_inicio', 'horaInicio'),
                                    style: TextStyle(
                                      color: context.c.primary,
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
                                      color: context.c.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                          color: context.c.primary,
                          size: 18,
                        ),
                        label: Text(
                          context.l10n.profSeeMyClasses,
                          style: TextStyle(
                            color: context.c.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.c.outline),
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
}

class _Avatar extends StatelessWidget {
  final String? fotoBase64;
  final String nome;
  const _Avatar({this.fotoBase64, required this.nome});

  @override
  Widget build(BuildContext context) {
    final iniciais = nome
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();
    if (fotoBase64 != null && fotoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(fotoBase64!.split(',').last);
        return CircleAvatar(radius: 22, backgroundImage: MemoryImage(bytes));
      } catch (_) {}
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: context.c.primary.withValues(alpha: 0.18),
      child: Text(
        iniciais.isEmpty ? '?' : iniciais,
        style: TextStyle(
          color: context.c.primary,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
