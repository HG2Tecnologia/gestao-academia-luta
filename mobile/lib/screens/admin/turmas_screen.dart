import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ad_banner.dart';
import '../../core/auth_storage.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';

/// Abreviação do dia da semana (índice 0 = domingo) no idioma ativo.
String _dowAbbr(int d, AppLocalizations l) {
  switch (d) {
    case 0:
      return l.dowSun;
    case 1:
      return l.dowMon;
    case 2:
      return l.dowTue;
    case 3:
      return l.dowWed;
    case 4:
      return l.dowThu;
    case 5:
      return l.dowFri;
    case 6:
      return l.dowSat;
    default:
      return '?';
  }
}

/// Rótulo traduzido para o nível da turma. O valor persistido continua sendo a
/// string em português (dado), só a exibição muda com o idioma.
String nivelLabel(String? nivel, AppLocalizations l) {
  switch (nivel) {
    case 'Iniciante':
      return l.levelBeginner;
    case 'Intermediário':
      return l.levelIntermediate;
    case 'Avançado':
      return l.levelAdvanced;
    case 'Todos os níveis':
      return l.levelAll;
    default:
      return nivel ?? '';
  }
}

String _fmtHora(dynamic h) {
  final s = h?.toString() ?? '';
  return s.length >= 5 ? s.substring(0, 5) : s;
}

/// Resumo compacto dos horários de uma turma para exibir no card.
/// - mesmo horário em todos os dias -> "Seg • Qua • Sex" + "20:00 – 21:30"
/// - horários diferentes (até 3)    -> "Seg • 20:00 / Qua • 19:30 / ..." (linha1)
/// - muitos horários                -> "Seg • Qua • Sex" + "N horários"
({String linha1, String linha2}) resumoHorarios(
  List<Map<String, dynamic>> horarios,
  AppLocalizations l,
) {
  if (horarios.isEmpty) return (linha1: l.noSchedule, linha2: '');

  int diaIdx(Map<String, dynamic> m) =>
      (m['diaSemana'] ?? m['dia_semana'] as num?)?.toInt() ?? 0;
  String dia(Map<String, dynamic> m) => _dowAbbr(diaIdx(m), l);

  String ini(Map<String, dynamic> m) =>
      _fmtHora(m['horaInicio'] ?? m['hora_inicio']);
  String fim(Map<String, dynamic> m) => _fmtHora(m['horaFim'] ?? m['hora_fim']);

  final ordenados = [...horarios]
    ..sort((a, b) => diaIdx(a).compareTo(diaIdx(b)));
  final dias = ordenados.map(dia).join(' • ');
  final horasUnicas = ordenados.map((m) => '${ini(m)}|${fim(m)}').toSet();

  if (horasUnicas.length == 1) {
    final i = ini(ordenados.first);
    final f = fim(ordenados.first);
    return (linha1: dias, linha2: f.isEmpty ? i : '$i – $f');
  }
  if (ordenados.length <= 3) {
    return (
      linha1: ordenados.map((m) => '${dia(m)} • ${ini(m)}').join('\n'),
      linha2: '',
    );
  }
  return (linha1: dias, linha2: l.scheduleCount(ordenados.length));
}

class AdminTurmasScreen extends StatefulWidget {
  const AdminTurmasScreen({super.key});

  @override
  State<AdminTurmasScreen> createState() => _AdminTurmasScreenState();
}

class _AdminTurmasScreenState extends State<AdminTurmasScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _turmas = [];
  List<Map<String, dynamic>> _filtradas = [];
  Map<String, List<Map<String, dynamic>>> _horariosPorTurma = {};
  bool _loading = true;
  bool _erro = false;
  String? _academiaId;

  @override
  void initState() {
    super.initState();
    _load();
    _ctrl.addListener(_filtrar);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = false;
    });
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId ?? '';
      if (_academiaId!.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final results = await Future.wait([
        firestoreService.getTurmas(_academiaId!),
        firestoreService.getMatriculas(_academiaId!, ativasOnly: true),
        firestoreService.getHorarios(_academiaId!),
      ]);
      // Turmas excluídas (soft delete) somem das listagens operacionais —
      // o histórico continua íntegro, só não aparecem mais aqui.
      final turmasList = (results[0] as List)
          .cast<Map<String, dynamic>>()
          .where((t) => t['deleted_at'] == null)
          .toList();
      final matriculas = (results[1] as List).cast<Map<String, dynamic>>();
      final horarios = (results[2] as List).cast<Map<String, dynamic>>();

      final countPorTurma = <String, int>{};
      for (final m in matriculas) {
        final tid = m['turma_id']?.toString() ?? '';
        if (tid.isNotEmpty) countPorTurma[tid] = (countPorTurma[tid] ?? 0) + 1;
      }

      final horariosPorTurma = <String, List<Map<String, dynamic>>>{};
      for (final h in horarios) {
        final tid = (h['turma_id'] ?? h['turmaId'])?.toString() ?? '';
        if (tid.isEmpty) continue;
        horariosPorTurma.putIfAbsent(tid, () => []).add(h);
      }

      final enriched = turmasList.map((t) {
        final id = t['id']?.toString() ?? '';
        return <String, dynamic>{...t, 'totalAlunos': countPorTurma[id] ?? 0};
      }).toList();

      if (mounted) {
        setState(() {
          _turmas = enriched;
          _horariosPorTurma = horariosPorTurma;
          _filtrar();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirForm({Map<String, dynamic>? turma}) async {
    if (_academiaId == null) return;
    final criou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TurmaFormSheet(academiaId: _academiaId!, turma: turma),
    );
    if (criou == true) _load();
  }

  Future<void> _abrirDetalhe(
    Map<String, dynamic> t, {
    bool chamada = false,
  }) async {
    final id = t['id'];
    await context.push(
      '/admin/turmas/$id${chamada ? '?tab=presenca' : ''}',
      extra: t,
    );
    // A tela de detalhe pode excluir/editar a turma — recarrega ao voltar.
    if (mounted) _load();
  }

  void _filtrar() {
    final q = _ctrl.text.trim().toLowerCase();
    setState(() {
      _filtradas = q.isEmpty
          ? List.from(_turmas)
          : _turmas.where((t) {
              final nome = (t['nome'] as String? ?? '').toLowerCase();
              final mod =
                  (t['modalidadeNome'] ?? t['nome_modalidade'] as String? ?? '')
                      .toLowerCase();
              final prof =
                  (t['professorNome'] ?? t['nome_professor'] as String? ?? '')
                      .toLowerCase();
              return nome.contains(q) || mod.contains(q) || prof.contains(q);
            }).toList();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final poucasTurmas = _turmas.length <= 1;
    return Scaffold(
      floatingActionButton: (_loading || _turmas.isEmpty)
          ? null
          : FloatingActionButton(
              onPressed: () => _abrirForm(),
              backgroundColor: context.c.primary,
              child: Icon(Icons.add_rounded, color: context.c.onPrimary),
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.navClasses,
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.classesSubtitle,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: openAppDrawer,
                    icon: Icon(
                      Icons.menu_rounded,
                      color: context.c.onSurface,
                      size: 26,
                    ),
                    tooltip: l.commonMenu,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: context.c.onSurface),
                decoration: InputDecoration(
                  hintText: l.classesSearchHint,
                  hintStyle: TextStyle(color: context.c.onSurfaceVariant),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.c.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: context.c.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.c.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.c.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.c.primary),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Material(
                color: context.c.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => context.push('/admin/turmas/relatorio'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 18,
                          color: context.c.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.attendanceReport,
                            style: TextStyle(
                              color: context.c.onSurface,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: context.c.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
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
                  : _erro
                  ? _EstadoErro(onRetry: _load)
                  : _turmas.isEmpty
                  ? _EstadoVazio(onCriar: () => _abrirForm())
                  : _filtradas.isEmpty
                  ? Center(
                      child: Text(
                        l.classesEmpty,
                        style: TextStyle(color: context.c.onSurfaceVariant),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _filtradas.length + (poucasTurmas ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _filtradas.length) {
                            return _BlocoMaisTurmas(
                              onCriar: () => _abrirForm(),
                            );
                          }
                          final t = _filtradas[i];
                          return _ClassCard(
                            turma: t,
                            horarios:
                                _horariosPorTurma[t['id']?.toString()] ??
                                const [],
                            onChamada: () => _abrirDetalhe(t, chamada: true),
                            onDetalhes: () => _abrirDetalhe(t),
                            onEditar: () => _abrirForm(turma: t),
                          );
                        },
                      ),
                    ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}

// ── Card da turma ────────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.turma,
    required this.horarios,
    required this.onChamada,
    required this.onDetalhes,
    required this.onEditar,
  });

  final Map<String, dynamic> turma;
  final List<Map<String, dynamic>> horarios;
  final VoidCallback onChamada;
  final VoidCallback onDetalhes;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = turma;
    final ativa = t['ativo'] == true;
    final total = (t['totalAlunos'] as num?)?.toInt() ?? 0;
    final cap =
        (t['capacidadeMaxima'] ?? t['capacidade_maxima'] as num?)?.toString() ??
        '—';
    final modalidade = (t['modalidadeNome'] ?? t['nome_modalidade'] ?? '')
        .toString();
    final nivel = (t['nivel'] ?? '').toString();
    final prof = (t['professorNome'] ?? t['nome_professor'] ?? '').toString();
    final sub = [
      modalidade,
      nivelLabel(nivel.isEmpty ? null : nivel, l),
    ].where((s) => s.isNotEmpty).join(' · ');
    final r = resumoHorarios(horarios, l);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.c.outline),
      ),
      clipBehavior: Clip.antiAlias,
      // Card inteiro clicável (não só o botão "Ver detalhes") — o botão de
      // chamada e o lápis de editar continuam com o próprio toque, o
      // InkWell só pega o resto da área do card.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDetalhes,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        t['nome']?.toString() ?? '',
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (ativa
                                    ? context.sem.success
                                    : context.c.onSurfaceVariant)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ativa ? l.classStatusActive : l.classStatusInactive,
                        style: TextStyle(
                          color: ativa
                              ? context.sem.success
                              : context.c.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (prof.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    l.classInstructorPrefix(prof),
                    style: TextStyle(
                      color: context.sem.goldOnSurface,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 18,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          color: context.c.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$total',
                                style: TextStyle(
                                  color: context.sem.goldOnSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: l.classCapacitySuffix(cap),
                                style: TextStyle(
                                  color: context.c.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: context.c.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.linha1,
                                  style: TextStyle(
                                    color: context.c.onSurface,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (r.linha2.isNotEmpty)
                                  Text(
                                    r.linha2,
                                    style: TextStyle(
                                      color: context.c.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: onChamada,
                          icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                          label: Text(
                            l.takeAttendance,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.c.primary,
                            foregroundColor: context.c.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: onDetalhes,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.c.onSurface,
                            side: BorderSide(color: context.c.outline),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  l.viewDetails,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      onPressed: onEditar,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.edit_rounded,
                        color: context.c.onSurfaceVariant,
                        size: 18,
                      ),
                      tooltip: l.editClass,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Estados auxiliares ───────────────────────────────────────────────────────

class _BlocoMaisTurmas extends StatelessWidget {
  const _BlocoMaisTurmas({required this.onCriar});
  final VoidCallback onCriar;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.c.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.c.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups_rounded, color: context.c.primary),
          ),
          const SizedBox(height: 12),
          Text(
            l.classesMoreTitle,
            style: TextStyle(
              color: context.c.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l.classesMoreSubtitle,
            style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCriar,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l.dashNewClass),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.c.primary,
              side: BorderSide(color: context.c.primary.withValues(alpha: 0.5)),
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({required this.onCriar});
  final VoidCallback onCriar;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_rounded,
              color: context.c.onSurfaceVariant,
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              l.classesEmptyState,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onCriar,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l.classesCreateFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.c.primary,
                foregroundColor: context.c.onPrimary,
                elevation: 0,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoErro extends StatelessWidget {
  const _EstadoErro({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: context.sem.danger, size: 44),
            const SizedBox(height: 14),
            Text(
              l.classesLoadError,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l.commonRetry),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.c.primary,
                minimumSize: const Size(0, 46),
                side: BorderSide(
                  color: context.c.primary.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formulário de Turma ──────────────────────────────────────────────────────

class TurmaFormSheet extends StatefulWidget {
  const TurmaFormSheet({required this.academiaId, this.turma});
  final String academiaId;
  final Map<String, dynamic>? turma;

  @override
  State<TurmaFormSheet> createState() => TurmaFormSheetState();
}

class TurmaFormSheetState extends State<TurmaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _capCtrl = TextEditingController();

  List<Map<String, dynamic>> _modalidades = [];
  List<Map<String, dynamic>> _professores = [];

  String? _modalidadeId;
  String? _professorId;
  String? _nivel;
  bool _ativo = true;
  bool _loading = true;
  bool _salvando = false;

  /// Valores persistidos (dados). A exibição usa [nivelLabel].
  static const _niveis = [
    'Iniciante',
    'Intermediário',
    'Avançado',
    'Todos os níveis',
  ];

  bool get _editando => widget.turma != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      final t = widget.turma!;
      _nomeCtrl.text = t['nome'] as String? ?? '';
      _capCtrl.text = (t['capacidadeMaxima'] ?? t['capacidade_maxima'] ?? '')
          .toString();
      _nivel = t['nivel'] as String?;
      _ativo = t['ativo'] == true;
    }
    _loadDados();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDados() async {
    try {
      final results = await Future.wait([
        firestoreService.getModalidades(widget.academiaId),
        firestoreService.getFuncionarios(widget.academiaId),
      ]);

      final mods = results[0].cast<Map<String, dynamic>>();
      final funcs = results[1].cast<Map<String, dynamic>>();
      final profs = funcs.where((f) {
        final cargo = f['cargo']?.toString().toLowerCase() ?? '';
        final perfil = f['perfil']?.toString().toLowerCase() ?? '';
        return cargo.contains('professor') || perfil.contains('professor');
      }).toList();

      if (mounted) {
        setState(() {
          _modalidades = mods;
          _professores = profs;

          if (_editando) {
            final t = widget.turma!;
            final modNome =
                (t['modalidadeNome'] ?? t['nome_modalidade'])?.toString() ?? '';
            final modId = t['modalidadeId']?.toString();
            final modIdExiste = mods.any((m) => m['id']?.toString() == modId);
            String? modIdPorNome;
            if (!modIdExiste) {
              try {
                modIdPorNome = mods
                    .firstWhere(
                      (m) => m['nome']?.toString() == modNome,
                      orElse: () => {},
                    )['id']
                    ?.toString();
              } catch (_) {}
            }
            _modalidadeId = modIdExiste ? modId : modIdPorNome;

            final profNome =
                (t['professorNome'] ?? t['nome_professor'])?.toString() ?? '';
            final profId = t['professorId']?.toString();
            _professorId =
                profId ??
                profs
                    .firstWhere(
                      (p) =>
                          p['nome']?.toString() == profNome ||
                          p['nomeUsuario']?.toString() == profNome,
                      orElse: () => {},
                    )['usuarioId']
                    ?.toString() ??
                profs
                    .firstWhere(
                      (p) => p['nome']?.toString() == profNome,
                      orElse: () => {},
                    )['id']
                    ?.toString();
          }

          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final erroMsg = _editando
        ? context.l10n.classEditError
        : context.l10n.classCreateError;
    setState(() => _salvando = true);
    try {
      final body = {
        'nome': _nomeCtrl.text.trim(),
        'modalidadeId': _modalidadeId,
        if (_professorId != null && _professorId!.isNotEmpty)
          'professorId': _professorId,
        'capacidadeMaxima': int.tryParse(_capCtrl.text.trim()) ?? 30,
        if (_nivel != null) 'nivel': _nivel,
        'ativo': _ativo,
      };

      if (_editando) {
        await firestoreService.updateTurma(
          widget.academiaId,
          widget.turma!['id'].toString(),
          body,
        );
      } else {
        await firestoreService.addTurma(widget.academiaId, body);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erroMsg),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.c.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                _editando ? l.editClassTitle : l.newClassTitle,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_salvando)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: _salvar,
                  style: TextButton.styleFrom(
                    backgroundColor: context.c.primary.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l.commonSave,
                    style: TextStyle(
                      color: context.sem.goldOnSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            )
          else
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(
                    _nomeCtrl,
                    l.classNameField,
                    Icons.groups_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.commonRequiredField
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _modalidadeId,
                    decoration: _inputDecoration(
                      l.modality,
                      Icons.sports_martial_arts_rounded,
                    ),
                    dropdownColor: context.c.surfaceContainer,
                    style: TextStyle(color: context.c.onSurface, fontSize: 15),
                    items:
                        (_editando
                                ? _modalidades
                                : _modalidades
                                      .where((m) => m['ativo'] == true)
                                      .toList())
                            .map(
                              (m) => DropdownMenuItem(
                                value: m['id']?.toString(),
                                child: Text(
                                  m['nome']?.toString() ?? '',
                                  style: TextStyle(color: context.c.onSurface),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _modalidadeId = v),
                    validator: (v) => v == null ? l.sdSelectModality : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _niveis.contains(_nivel) ? _nivel : null,
                    decoration: _inputDecoration(
                      l.level,
                      Icons.bar_chart_rounded,
                    ),
                    dropdownColor: context.c.surfaceContainer,
                    style: TextStyle(color: context.c.onSurface, fontSize: 15),
                    items: _niveis
                        .map(
                          (n) => DropdownMenuItem(
                            value: n,
                            child: Text(
                              nivelLabel(n, l),
                              style: TextStyle(color: context.c.onSurface),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _nivel = v),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value:
                        _professores.any(
                          (p) =>
                              (p['usuarioId'] ?? p['id'])?.toString() ==
                              _professorId,
                        )
                        ? _professorId
                        : null,
                    decoration: _inputDecoration(
                      l.instructorOptional,
                      Icons.person_rounded,
                    ),
                    dropdownColor: context.c.surfaceContainer,
                    style: TextStyle(color: context.c.onSurface, fontSize: 15),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          l.noInstructor,
                          style: TextStyle(color: context.c.onSurfaceVariant),
                        ),
                      ),
                      ..._professores.map((p) {
                        final id = (p['usuarioId'] ?? p['id'])?.toString();
                        final nome =
                            p['nome']?.toString() ??
                            p['nomeUsuario']?.toString() ??
                            '';
                        return DropdownMenuItem(
                          value: id,
                          child: Text(
                            nome,
                            style: TextStyle(color: context.c.onSurface),
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) => setState(() => _professorId = v),
                  ),
                  const SizedBox(height: 14),
                  _field(
                    _capCtrl,
                    l.maxCapacity,
                    Icons.people_rounded,
                    keyboard: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l.commonRequiredField;
                      }
                      if (int.tryParse(v.trim()) == null) {
                        return l.invalidNumber;
                      }
                      return null;
                    },
                  ),
                  if (_editando) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.c.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.c.outline),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.toggle_on_rounded,
                            color: context.c.onSurfaceVariant,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.classActiveToggle,
                              style: TextStyle(color: context.c.onSurface),
                            ),
                          ),
                          Switch(
                            value: _ativo,
                            onChanged: (v) => setState(() => _ativo = v),
                            activeThumbColor: context.c.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: keyboard,
    validator: validator,
    style: TextStyle(color: context.c.onSurface, fontSize: 15),
    decoration: _inputDecoration(label, icon),
  );

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.c.onSurfaceVariant, fontSize: 13),
        prefixIcon: Icon(icon, color: context.c.onSurfaceVariant, size: 18),
        filled: true,
        fillColor: context.c.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.c.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.c.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.c.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.sem.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.sem.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );
}
