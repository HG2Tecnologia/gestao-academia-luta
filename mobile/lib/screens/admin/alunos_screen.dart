import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ad_banner.dart';
import '../../core/auth_storage.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';
import '../../core/graduacao_order.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets.dart';

class AdminAlunosScreen extends StatefulWidget {
  /// Quando `true`, a tela é aberta pelo app do professor: lista só os alunos
  /// matriculados nas turmas dele (salvo `acesso_turmas_todas`), esconde o botão
  /// de criar aluno e navega pela rota `/professor/alunos/...`.
  final bool professorMode;
  const AdminAlunosScreen({super.key, this.professorMode = false});

  @override
  State<AdminAlunosScreen> createState() => _AdminAlunosScreenState();
}

class _AdminAlunosScreenState extends State<AdminAlunosScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _alunos = [];
  List<Map<String, dynamic>> _todosAlunos = [];
  bool _loading = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _load('');
    _ctrl.addListener(() => _debounce(_ctrl.text));
  }

  DateTime? _last;
  void _debounce(String q) {
    _last = DateTime.now();
    final snap = _last!;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_last == snap) _filtrar(q);
    });
  }

  void _filtrar(String q) {
    if (!mounted) return;
    if (q.isEmpty) {
      setState(() => _alunos = _todosAlunos);
    } else {
      setState(
        () => _alunos = _todosAlunos
            .where(
              (a) => (a['nome'] as String? ?? '').toLowerCase().contains(
                q.toLowerCase(),
              ),
            )
            .toList(),
      );
    }
  }

  Future<void> _load(String q) async {
    setState(() {
      _loading = true;
      _erro = false;
    });
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;

      final results = await Future.wait([
        firestoreService.getAlunos(academiaId),
        firestoreService.getGraduacoes(academiaId, detalhadas: true),
      ]);

      final alunos = results[0];
      final graduacoes = results[1];
      final faixasAtuaisPorAluno = montarFaixasAtuaisPorAluno(graduacoes);

      var todos = alunos.map((a) {
        final id = a['id']?.toString() ?? '';
        return <String, dynamic>{
          ...a,
          'faixasAtuais': faixasAtuaisPorAluno[id] ?? const {},
        };
      }).toList();

      // Modo professor: restringe aos alunos das turmas dele, salvo se a
      // academia concedeu "ver todas as turmas".
      if (widget.professorMode && !user.temPermissao('acesso_turmas_todas')) {
        final turmasProf = await firestoreService.getTurmas(
          academiaId,
          professorId: user.id,
        );
        final turmaIds = turmasProf
            .map((t) => t['id']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet();
        final matriculas = await firestoreService.getMatriculas(
          academiaId,
          ativasOnly: true,
        );
        final permitidos = matriculas
            .where((m) => turmaIds.contains(m['turma_id']?.toString() ?? ''))
            .map((m) => m['aluno_id']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet();
        todos = todos
            .where((a) => permitidos.contains(a['id']?.toString()))
            .toList();
      }

      if (mounted) {
        setState(() {
          _todosAlunos = todos;
          _alunos = q.isEmpty
              ? todos
              : todos
                    .where(
                      (a) => (a['nome'] as String? ?? '')
                          .toLowerCase()
                          .contains(q.toLowerCase()),
                    )
                    .toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _primaryFaixa(Map<String, dynamic> a) {
    final faixasAtuais = a['faixasAtuais'] as Map<String, dynamic>?;
    if (faixasAtuais == null || faixasAtuais.isEmpty) return null;
    final principalId = a['faixaPrincipalModalidadeId'] as String?;
    if (principalId != null &&
        principalId.isNotEmpty &&
        faixasAtuais.containsKey(principalId)) {
      return faixasAtuais[principalId] as Map<String, dynamic>?;
    }
    return faixasAtuais.values.first as Map<String, dynamic>?;
  }

  Color _finCor(BuildContext context, String? s) {
    if (s == 'Inadimplente') return context.sem.danger;
    if (s == 'Pendente') return context.sem.warning;
    return context.sem.success;
  }

  String _formatFin(BuildContext context, String? s) {
    final l = context.l10n;
    switch (s) {
      case 'EmDia':
        return l.finUpToDate;
      case 'Pendente':
        return l.finPending;
      case 'Inadimplente':
        return l.finOverdue;
      default:
        return s ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      floatingActionButton: widget.professorMode
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await context.push('/admin/alunos/novo');
                _load(_ctrl.text);
              },
              backgroundColor: context.c.primary,
              child: Icon(Icons.add, color: context.c.onPrimary),
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Text(
                    l.navStudents,
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: openAppDrawer,
                    child: Icon(
                      Icons.menu_rounded,
                      color: context.c.onSurface,
                      size: 26,
                    ),
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
                  hintText: l.studentsSearchHint,
                  hintStyle: TextStyle(color: context.c.onSurfaceVariant),
                  prefixIcon: Icon(
                    Icons.search,
                    color: context.c.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: context.c.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                    borderSide: BorderSide(color: context.c.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.c.primary,
                      ),
                    )
                  : _erro
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l.studentsLoadError,
                          style: TextStyle(
                            color: context.sem.danger,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _alunos.isEmpty
                  ? Center(
                      child: Text(
                        l.studentsEmpty,
                        style: TextStyle(color: context.c.onSurfaceVariant),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _load(_ctrl.text),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _alunos.length,
                        itemBuilder: (_, i) {
                          final a = _alunos[i];
                          final ativo = a['ativo'] == true;
                          final fin = a['situacaoFinanceira'] as String?;
                          final statusAtestado = a['statusAtestado'] as int?;
                          final atestadoValidade = a['atestadoValidade'] != null
                              ? DateTime.tryParse(a['atestadoValidade'])
                              : null;
                          final atestadoProblema =
                              statusAtestado == null ||
                              statusAtestado == 0 ||
                              statusAtestado == 2 ||
                              statusAtestado == 3 ||
                              (statusAtestado == 1 &&
                                  atestadoValidade != null &&
                                  atestadoValidade.isBefore(
                                    DateTime.now().add(const Duration(days: 7)),
                                  ));
                          final primary = _primaryFaixa(a);
                          final faixasCount =
                              (a['faixasAtuais'] as Map?)?.length ?? 0;
                          final faixaCor = primary?['faixaCor'] as String?;
                          final faixaCorBarra =
                              primary?['faixaCorBarra'] as String?;
                          final grauAtual =
                              (primary?['grau'] as num?)?.toInt() ?? 0;
                          final maxGrausRaw =
                              (primary?['faixaMaxGraus'] as num?)?.toInt() ?? 4;
                          final maxGraus = maxGrausRaw > 0
                              ? maxGrausRaw
                              : (grauAtual > 0 ? grauAtual : 4);
                          final temGraus =
                              primary?['faixaTemGraus'] == true ||
                              grauAtual > 0;
                          final faixaNome = primary?['faixaNome'] as String?;
                          final foto =
                              a['fotoBase64'] as String? ??
                              a['foto_base64'] as String?;
                          final initials = (a['nome'] as String? ?? '')
                              .trim()
                              .split(RegExp(r'\s+'))
                              .take(2)
                              .map((w) => w.isNotEmpty ? w[0] : '')
                              .join()
                              .toUpperCase();
                          Color parseCor(String? hex) {
                            try {
                              return Color(
                                int.parse((hex ?? '').replaceAll('#', '0xFF')),
                              );
                            } catch (_) {
                              return context.c.primary;
                            }
                          }

                          return GestureDetector(
                            onTap: () async {
                              await context.push(
                                widget.professorMode
                                    ? '/professor/alunos/${a['id']}'
                                    : '/admin/alunos/${a['id']}',
                              );
                              _load(_ctrl.text);
                            },
                            child: Container(
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
                                    radius: 20,
                                    backgroundColor: context.c.primary
                                        .withValues(alpha: 0.15),
                                    backgroundImage:
                                        foto != null && foto.contains(',')
                                        ? MemoryImage(
                                            base64Decode(foto.split(',').last),
                                          )
                                        : null,
                                    child: foto == null || !foto.contains(',')
                                        ? Text(
                                            initials.isEmpty ? '?' : initials,
                                            style: TextStyle(
                                              color: context.sem.goldOnSurface,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a['nome'] ?? '',
                                          style: TextStyle(
                                            color: context.c.onSurface,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (faixaCor != null) ...[
                                              BeltBadge(
                                                cor: parseCor(faixaCor),
                                                corBarra: parseCor(
                                                  faixaCorBarra ?? '#000000',
                                                ),
                                                temGraus: temGraus,
                                                grau: grauAtual,
                                                maxGraus: maxGraus,
                                                height: 14,
                                                minWidth: 32,
                                              ),
                                              if (faixasCount > 1) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: context.c.primary
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '+${faixasCount - 1}',
                                                    style: TextStyle(
                                                      color: context
                                                          .sem
                                                          .goldOnSurface,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(width: 6),
                                            ],
                                            Flexible(
                                              child: Text(
                                                [
                                                      if (faixaNome != null)
                                                        grauAtual > 0
                                                            ? '$faixaNome · ${l.stripeLabel(grauAtual)}'
                                                            : faixaNome,
                                                      if (faixaNome == null)
                                                        l.studentNoBelt,
                                                      (a['turmas'] as List?)
                                                                  ?.isNotEmpty ==
                                                              true
                                                          ? (a['turmas']
                                                                    as List)
                                                                .first
                                                                .toString()
                                                          : null,
                                                    ]
                                                    .where(
                                                      (s) =>
                                                          s != null && s != '',
                                                    )
                                                    .join(' · '),
                                                style: TextStyle(
                                                  color: context
                                                      .c
                                                      .onSurfaceVariant,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ativo
                                              ? context.sem.success.withValues(
                                                  alpha: 0.15,
                                                )
                                              : context.c.onSurfaceVariant
                                                    .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          ativo
                                              ? l.statusActive
                                              : l.statusInactive,
                                          style: TextStyle(
                                            color: ativo
                                                ? context.sem.success
                                                : context.c.onSurfaceVariant,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (fin != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatFin(context, fin),
                                          style: TextStyle(
                                            color: _finCor(context, fin),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      if (atestadoProblema) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.medical_information_rounded,
                                              color: context.sem.warning,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              l.medicalCertificateShort,
                                              style: TextStyle(
                                                color: context.sem.warning,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    color: context.c.onSurfaceVariant,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
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
