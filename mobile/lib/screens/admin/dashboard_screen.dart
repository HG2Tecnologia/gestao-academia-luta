import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ad_banner.dart';
import '../../core/auth_storage.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';
import '../../core/paywall_modal.dart';
import '../../core/plan_service.dart';
import '../../core/tab_refresh.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets.dart';
import 'widgets/dashboard_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _dash;
  List<Map<String, dynamic>> _frequencia = [];
  List<Map<String, dynamic>> _aniversariantes = [];
  List<Map<String, dynamic>> _proximosGraduacao = [];
  List<Map<String, dynamic>> _noticias = [];
  List<Map<String, dynamic>> _alertasEvasao = [];
  StoredUser? _user;
  bool _loading = true;
  bool _erro = false;
  String? _erroMsg;
  bool _temModalidades = false;
  bool _temPlanos = false;
  bool _temProfessores = false;

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
    setState(() {
      _loading = true;
      _erro = false;
    });
    final user = await AuthStorage.getUser();
    final academiaId = user?.academiaId ?? '';
    if (academiaId.isEmpty) {
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
          _erro = true;
        });
      }
      return;
    }
    try {
      final results = await Future.wait([
        firestoreService.getDashboardResumo(academiaId),
        firestoreService.getModalidades(academiaId),
        firestoreService.getPlanos(academiaId),
        firestoreService.getFuncionarios(academiaId),
        firestoreService.getPresencas(academiaId),
        firestoreService.getAlunos(academiaId),
        firestoreService.getAptosGraduacao(academiaId),
        firestoreService.getNoticias(academiaId, publicadasOnly: true),
        firestoreService.getTurmas(academiaId),
      ]);

      final dashData = results[0] as Map<String, dynamic>? ?? {};
      final modalidades = (results[1] as List).cast<Map<String, dynamic>>();
      final planos = (results[2] as List).cast<Map<String, dynamic>>();
      final funcionarios = (results[3] as List).cast<Map<String, dynamic>>();
      final presencas = (results[4] as List).cast<Map<String, dynamic>>();
      final alunos = (results[5] as List).cast<Map<String, dynamic>>();
      final aptosGrad = (results[6] as List).cast<Map<String, dynamic>>();
      final noticiasList = (results[7] as List).cast<Map<String, dynamic>>();
      final turmasList = (results[8] as List).cast<Map<String, dynamic>>();
      final turmasAtivasCount = turmasList
          .where((t) => t['ativo'] == true)
          .length;

      final hoje = DateTime.now();
      final mesAtual = hoje.month;
      final aniversariantes =
          alunos
              .map((a) {
                final nasc =
                    a['data_nascimento'] as String? ??
                    a['dataNascimento'] as String? ??
                    '';
                if (nasc.isEmpty) return null;
                DateTime? dt;
                try {
                  dt = DateTime.parse(nasc);
                } catch (_) {
                  return null;
                }
                if (dt.month != mesAtual) return null;
                final nascStr =
                    a['data_nascimento'] as String? ??
                    a['dataNascimento'] as String? ??
                    '';
                final dia = nascStr.isNotEmpty
                    ? (DateTime.tryParse(nascStr)?.day ?? 0)
                    : 0;
                return {
                  'nome': a['nome'] ?? '',
                  'diaNascimento': dia,
                  'alunoId': a['id'] ?? '',
                };
              })
              .whereType<Map<String, dynamic>>()
              .toList()
            ..sort(
              (x, y) => ((x['diaNascimento'] as int?) ?? 0).compareTo(
                (y['diaNascimento'] as int?) ?? 0,
              ),
            );

      final freqMap = <String, int>{};
      for (var i = 6; i >= 0; i--) {
        final d = hoje.subtract(Duration(days: i));
        final key =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        freqMap[key] = 0;
      }
      for (final p in presencas) {
        final data =
            p['data'] as String? ?? p['data_presenca'] as String? ?? '';
        if (data.isEmpty) continue;
        final key = data.length >= 10 ? data.substring(0, 10) : data;
        if (freqMap.containsKey(key)) freqMap[key] = (freqMap[key] ?? 0) + 1;
      }
      final frequencia = freqMap.entries
          .map((e) => {'data': e.key, 'total': e.value})
          .toList();

      var presencasHoje = 0;
      final keyHoje =
          '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      presencasHoje = freqMap[keyHoje] ?? 0;

      final totalAlunos =
          dashData['totalAlunos'] ??
          alunos.where((a) => a['ativo'] == true).length;
      final turmasAtivas = dashData['turmasAtivas'] ?? turmasAtivasCount;
      final alunosInadimplentes = dashData['alunosInadimplentes'];

      final dash = {
        'totalAlunos': totalAlunos,
        'turmasAtivas': turmasAtivas,
        'presencasHoje': presencasHoje,
        'alunosInadimplentes': alunosInadimplentes,
      };

      final profs = funcionarios.where((f) {
        final cargo = f['cargo']?.toString().toLowerCase() ?? '';
        final perfil = f['perfil']?.toString().toLowerCase() ?? '';
        return cargo.contains('professor') || perfil.contains('professor');
      }).toList();

      final proximosGrad =
          aptosGrad
              .where((a) => (a['nomeAluno'] as String? ?? '').isNotEmpty)
              .toList()
            ..sort((a, b) {
              final pa = (b['percentual'] as num?)?.toDouble() ?? 0;
              final pb = (a['percentual'] as num?)?.toDouble() ?? 0;
              return pb.compareTo(pa);
            });

      final ultimaPresencaPorAluno = <String, DateTime>{};
      for (final p in presencas) {
        final aId = p['aluno_id']?.toString() ?? '';
        if (aId.isEmpty) continue;
        final data =
            p['data'] as String? ?? p['data_presenca'] as String? ?? '';
        final dt = DateTime.tryParse(data);
        if (dt == null) continue;
        final atual = ultimaPresencaPorAluno[aId];
        if (atual == null || dt.isAfter(atual)) {
          ultimaPresencaPorAluno[aId] = dt;
        }
      }
      final alertas = <Map<String, dynamic>>[];
      for (final aluno in alunos.where((a) => a['ativo'] == true)) {
        final aId = aluno['id']?.toString() ?? '';
        final ultima = ultimaPresencaPorAluno[aId];
        if (ultima == null) continue;
        final dias = hoje.difference(ultima).inDays;
        if (dias >= 7) {
          alertas.add({
            'nome': aluno['nome'] ?? '',
            'id': aId,
            'diasSemPresenca': dias,
            'nivelAlerta': dias >= 14 ? 'red' : 'yellow',
          });
        }
      }
      alertas.sort(
        (a, b) => ((b['diasSemPresenca'] as int?) ?? 0).compareTo(
          (a['diasSemPresenca'] as int?) ?? 0,
        ),
      );

      final noticiasMapped =
          noticiasList
              .map(
                (n) => {
                  ...n,
                  'publicadaEm': n['publicada_em'] ?? n['publicadaEm'],
                },
              )
              .toList()
            ..sort((a, b) {
              final da = a['publicada_em'] ?? a['publicadaEm'] ?? '';
              final db = b['publicada_em'] ?? b['publicadaEm'] ?? '';
              return db.toString().compareTo(da.toString());
            });

      if (mounted) {
        setState(() {
          _user = user;
          _dash = dash;
          _frequencia = frequencia;
          _aniversariantes = aniversariantes.cast<Map<String, dynamic>>();
          _proximosGraduacao = proximosGrad;
          _noticias = noticiasMapped;
          _alertasEvasao = alertas;
          _temModalidades = modalidades.isNotEmpty;
          _temPlanos = planos.isNotEmpty;
          _temProfessores = profs.isNotEmpty;
          _loading = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('[Dashboard._load] ERRO: $e');
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
          _erro = true;
          _erroMsg = e.toString();
        });
      }
    }
  }

  bool get _setupCompleto {
    final d = _dash ?? {};
    return _temModalidades &&
        _temPlanos &&
        _temProfessores &&
        ((d['turmasAtivas'] as num?)?.toInt() ?? 0) > 0 &&
        ((d['totalAlunos'] as num?)?.toInt() ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_erro && _dash == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ErroConexao(
                onRetry: () {
                  setState(() {
                    _loading = true;
                    _erro = false;
                    _erroMsg = null;
                  });
                  _load();
                },
              ),
              if (_erroMsg != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _erroMsg!,
                    style: TextStyle(color: context.sem.danger, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.c.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildPlanStatus()),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else ...[
              if (!_setupCompleto)
                SliverToBoxAdapter(child: _buildOnboarding()),
              SliverToBoxAdapter(child: _buildMetrics()),
              SliverToBoxAdapter(child: _buildQuickActions()),
              if (_alertasEvasao.isNotEmpty)
                SliverToBoxAdapter(child: _buildAlertaEvasao()),
              if (_aniversariantes.isNotEmpty)
                SliverToBoxAdapter(child: _buildAniversariantes()),
              SliverToBoxAdapter(child: _buildProximosGraduacao()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: WeeklyFrequencyChart(dados: _frequencia),
                ),
              ),
              if (_noticias.isNotEmpty)
                SliverToBoxAdapter(child: _buildNoticias()),
              const SliverToBoxAdapter(child: AdBannerWidget()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  // ─── PLANO STATUS ────────────────────────────────────────────────────────────

  Widget _buildPlanStatus() {
    final l = context.l10n;
    final plan = PlanService.instance;
    if (plan.isPro) return const SizedBox.shrink();

    Future<void> openPaywall() async {
      final ok = await mostrarPaywall(context);
      if (ok == true && mounted) {
        await PlanService.instance.refresh();
        setState(() {});
      }
    }

    if (plan.isInTrial) {
      final days = plan.daysLeftInTrial;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: GestureDetector(
          onTap: openPaywall,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.isDark
                      ? const Color(0xFF1A1200)
                      : context.sem.goldContainer,
                  context.c.primary.withValues(alpha: 0.35),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.c.primary.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  color: context.sem.goldOnSurface,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.dashTrialActive,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        days <= 1
                            ? l.dashTrialLastDay
                            : l.dashTrialDaysLeft(days),
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.c.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l.dashSeePlans,
                    style: TextStyle(
                      color: context.c.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Plano gratuito (trial expirado)
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: openPaywall,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.c.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.sem.warning.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.sem.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: context.sem.warning,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.dashFreePlan,
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l.dashFreePlanLimits,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.c.primary,
                      context.c.primary.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.dashSubscribePro,
                  style: TextStyle(
                    color: context.c.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final l = context.l10n;
    final nome = _user?.nome ?? '';
    final primeiroNome = nome.split(' ').first;
    final initials = nome.isNotEmpty
        ? nome
              .trim()
              .split(' ')
              .where((p) => p.isNotEmpty)
              .take(2)
              .map((p) => p[0].toUpperCase())
              .join()
        : 'A';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDark
              ? const [Color(0xFF1A1200), Color(0xFF0A0A0A)]
              : [context.sem.goldContainer, context.c.surface],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 24),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.c.primary,
                      context.c.primary.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: context.c.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primeiroNome.isEmpty
                          ? l.dashHello
                          : l.dashHelloName(primeiroNome),
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.dashYourAcademyToday,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
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
      ),
    );
  }

  // ─── MÉTRICAS ─────────────────────────────────────────────────────────────────

  Widget _buildMetrics() {
    final l = context.l10n;
    final d = _dash ?? {};
    final alunos = '${d['totalAlunos'] ?? '—'}';
    final turmas = '${d['turmasAtivas'] ?? '—'}';
    final presencas = '${d['presencasHoje'] ?? '—'}';
    final inadimplentes = '${d['alunosInadimplentes'] ?? '—'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DashMetricCard(
                  icon: Icons.sports_martial_arts_rounded,
                  value: alunos,
                  label: l.dashActiveStudents,
                  tone: DashTone.gold,
                  onTap: () => context.go('/admin/alunos'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashMetricCard(
                  icon: Icons.groups_rounded,
                  value: turmas,
                  label: l.dashActiveClasses,
                  tone: DashTone.info,
                  onTap: () => context.go('/admin/turmas'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DashMetricCard(
                  icon: Icons.check_circle_rounded,
                  value: presencas,
                  label: l.dashAttendanceToday,
                  tone: DashTone.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashMetricCard(
                  icon: Icons.warning_amber_rounded,
                  value: inadimplentes,
                  label: l.dashOverdueAccounts,
                  tone: DashTone.danger,
                  onTap: () => context.go('/admin/financeiro'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── AÇÕES RÁPIDAS ────────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashSectionHeader(l.dashQuickActions),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DashQuickAction(
                icon: Icons.person_add_rounded,
                label: l.dashNewStudent,
                tone: DashTone.gold,
                onTap: () => context.push('/admin/alunos/novo'),
              ),
              DashQuickAction(
                icon: Icons.groups_rounded,
                label: l.dashNewClass,
                tone: DashTone.info,
                onTap: () => context.push('/admin/turmas'),
              ),
              DashQuickAction(
                icon: Icons.qr_code_scanner_rounded,
                label: l.dashMarkAttendance,
                tone: DashTone.success,
                onTap: () async {
                  if (PlanService.instance.showAds) {
                    final ok = await mostrarPaywall(context);
                    if (ok) {
                      PlanService.instance.refresh();
                      setState(() {});
                    }
                    return;
                  }
                  if (mounted) context.push('/scan-qr');
                },
              ),
              DashQuickAction(
                icon: Icons.account_balance_wallet_rounded,
                label: l.navBilling,
                tone: DashTone.warning,
                onTap: () => context.go('/admin/financeiro'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── ONBOARDING ───────────────────────────────────────────────────────────────

  Widget _buildOnboarding() {
    final l = context.l10n;
    final d = _dash ?? {};
    final temTurma = ((d['turmasAtivas'] as num?)?.toInt() ?? 0) > 0;
    final temAluno = ((d['totalAlunos'] as num?)?.toInt() ?? 0) > 0;
    final academiaId = _user?.academiaId ?? '';

    final passos = [
      _OnboardingStep(
        titulo: l.dashStepModality,
        descricao: l.dashStepModalityDesc,
        feito: _temModalidades,
        icon: Icons.sports_martial_arts_rounded,
        onTap: () async {
          final ok = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _ModalidadeSheet(academiaId: academiaId),
          );
          if (ok == true) _load();
        },
      ),
      _OnboardingStep(
        titulo: l.dashStepPlan,
        descricao: l.dashStepPlanDesc,
        feito: _temPlanos,
        icon: Icons.monetization_on_rounded,
        onTap: () async {
          final ok = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _PlanoSheet(academiaId: academiaId),
          );
          if (ok == true) _load();
        },
      ),
      _OnboardingStep(
        titulo: l.dashStepInstructor,
        descricao: l.dashStepInstructorDesc,
        feito: _temProfessores,
        icon: Icons.school_rounded,
        onTap: () async {
          await context.push('/admin/equipe/novo');
          _load();
        },
      ),
      _OnboardingStep(
        titulo: l.dashStepClass,
        descricao: l.dashStepClassDesc,
        feito: temTurma,
        icon: Icons.groups_rounded,
        onTap: () => context.push('/admin/turmas'),
      ),
      _OnboardingStep(
        titulo: l.dashStepFirstStudent,
        descricao: l.dashStepFirstStudentDesc,
        feito: temAluno,
        icon: Icons.person_add_rounded,
        onTap: () => context.push('/admin/alunos/novo'),
      ),
    ];

    final feitos = passos.where((p) => p.feito).length;
    final progresso = feitos / passos.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: context.c.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.c.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: context.c.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.c.primary,
                          context.c.primary.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      color: context.c.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.dashGettingStarted,
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          l.dashGettingStartedSubtitle,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.c.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$feitos/${passos.length}',
                      style: TextStyle(
                        color: context.sem.goldOnSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progresso,
                  backgroundColor: context.c.outline.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(context.c.primary),
                  minHeight: 4,
                ),
              ),
            ),
            Divider(height: 1, color: context.c.outlineVariant),
            ...passos.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final anterior = i > 0 ? passos[i - 1] : null;
              final bloqueado = !p.feito && anterior != null && !anterior.feito;
              final isLast = i == passos.length - 1;
              return _buildPassoTile(p, bloqueado, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPassoTile(_OnboardingStep p, bool bloqueado, bool isLast) {
    final feitoColor = context.sem.success;
    final lockColor = context.c.onSurfaceVariant;
    final goldColor = context.c.primary;
    return InkWell(
      onTap: (p.feito || bloqueado) ? null : p.onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(20))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: p.feito
                    ? feitoColor.withValues(alpha: 0.12)
                    : bloqueado
                    ? context.c.outline.withValues(alpha: 0.2)
                    : goldColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: p.feito
                      ? feitoColor.withValues(alpha: 0.4)
                      : bloqueado
                      ? context.c.outline.withValues(alpha: 0.4)
                      : goldColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                p.feito ? Icons.check_rounded : p.icon,
                size: 18,
                color: p.feito
                    ? feitoColor
                    : bloqueado
                    ? lockColor
                    : context.sem.goldOnSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.titulo,
                    style: TextStyle(
                      color: (p.feito || bloqueado)
                          ? context.c.onSurfaceVariant
                          : context.c.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: p.feito ? TextDecoration.lineThrough : null,
                      decorationColor: context.c.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    p.descricao,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!p.feito && !bloqueado)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: context.sem.goldOnSurface,
                ),
              ),
            if (bloqueado)
              Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: lockColor.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  // ─── ALERTA DE EVASÃO ────────────────────────────────────────────────────────

  Widget _buildAlertaEvasao() {
    final l = context.l10n;
    final temVermelho = _alertasEvasao.any((a) => a['nivelAlerta'] == 'red');
    final tone = temVermelho ? DashTone.danger : DashTone.warning;
    final total = _alertasEvasao.length;
    final visiveis = _alertasEvasao.take(5).toList();
    final subtitulo = temVermelho
        ? l.dashWatchRedSubtitle(total)
        : l.dashWatchYellowSubtitle(total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: DashCard(
        tone: tone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashCardHeader(
              icon: Icons.person_off_rounded,
              title: l.dashAttendanceWatch,
              subtitle: subtitulo,
              tone: tone,
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tone.color(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total',
                  style: TextStyle(
                    color: tone.color(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...visiveis.map((a) {
              final nome = a['nome']?.toString() ?? '';
              final alunoId = a['id']?.toString() ?? '';
              final dias = (a['diasSemPresenca'] as int?) ?? 0;
              final isRed = a['nivelAlerta'] == 'red';
              final cor = isRed ? context.sem.danger : context.sem.warning;
              final initials = nome
                  .trim()
                  .split(RegExp(r'\s+'))
                  .take(2)
                  .map((w) => w.isNotEmpty ? w[0] : '')
                  .join()
                  .toUpperCase();

              return GestureDetector(
                onTap: alunoId.isNotEmpty
                    ? () => context.push('/admin/alunos/$alunoId')
                    : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: cor.withValues(alpha: 0.15),
                        child: Text(
                          initials.isEmpty ? '?' : initials,
                          style: TextStyle(
                            color: cor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nome,
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l.dashDaysCount(dias),
                          style: TextStyle(
                            color: cor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.c.onSurfaceVariant,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (total > 0)
              GestureDetector(
                onTap: () => context.push('/admin/evasao'),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Center(
                    child: Text(
                      total > visiveis.length
                          ? l.dashSeeAllStudents(total)
                          : l.dashOpenListWhatsapp,
                      style: TextStyle(
                        color: context.sem.goldOnSurface,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── ANIVERSARIANTES ─────────────────────────────────────────────────────────

  Widget _buildAniversariantes() {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.c.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.sem.warning.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.sem.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.cake_rounded,
                    color: context.sem.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.dashBirthdays,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l.dashThisMonth,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/admin/dashboard/aniversariantes'),
                  child: Text(
                    l.commonSeeAll,
                    style: TextStyle(
                      color: context.sem.goldOnSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._aniversariantes.take(5).map((a) {
              final nome = a['nome']?.toString() ?? '';
              final dia = a['diaNascimento'] as int? ?? 0;
              final mes = DateTime.now().month;
              final dataLabel = dia > 0
                  ? '${dia.toString().padLeft(2, '0')}/${mes.toString().padLeft(2, '0')}'
                  : '';
              final initials = nome
                  .trim()
                  .split(RegExp(r'\s+'))
                  .take(2)
                  .map((w) => w.isNotEmpty ? w[0] : '')
                  .join()
                  .toUpperCase();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.c.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.c.outline),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: context.sem.warning.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        initials.isEmpty ? '?' : initials,
                        style: TextStyle(
                          color: context.sem.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        nome,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      dataLabel,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── PRÓXIMOS DE GRADUAR ──────────────────────────────────────────────────────

  Widget _buildProximosGraduacao() {
    final l = context.l10n;
    final totalGrad = _proximosGraduacao.length;
    final visiveis = _proximosGraduacao.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: DashCard(
        tone: DashTone.gold,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashCardHeader(
              icon: Icons.military_tech_rounded,
              title: l.dashNearingPromotion,
              subtitle: l.dashNearingPromotionSubtitle,
              tone: DashTone.gold,
            ),
            const SizedBox(height: 12),
            if (_proximosGraduacao.isEmpty)
              Row(
                children: [
                  Text(
                    '0',
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.dashNoOneNearingPromotion,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              ...visiveis.map((a) {
                final nome = a['nomeAluno']?.toString() ?? '';
                final modalidade = a['nomeModalidade']?.toString() ?? '';
                final total = (a['totalPresencas'] as num?)?.toInt() ?? 0;
                final necessario =
                    (a['presencasNecessarias'] as num?)?.toInt() ?? 1;
                final jaApto = a['jaApto'] == true;
                final pct = (a['percentual'] as num?)?.toInt() ?? 0;
                final alunoId = a['alunoId']?.toString() ?? '';
                final initials = nome
                    .trim()
                    .split(RegExp(r'\s+'))
                    .take(2)
                    .map((w) => w.isNotEmpty ? w[0] : '')
                    .join()
                    .toUpperCase();

                return GestureDetector(
                  onTap: alunoId.isNotEmpty
                      ? () => context.push('/admin/alunos/$alunoId')
                      : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: jaApto
                          ? context.sem.success.withValues(alpha: 0.05)
                          : context.c.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: jaApto
                            ? context.sem.success.withValues(alpha: 0.3)
                            : context.c.outline,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              (jaApto ? context.sem.success : context.c.primary)
                                  .withValues(alpha: 0.15),
                          child: Text(
                            initials.isEmpty ? '?' : initials,
                            style: TextStyle(
                              color: jaApto
                                  ? context.sem.success
                                  : context.sem.goldOnSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nome,
                                style: TextStyle(
                                  color: context.c.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                modalidade,
                                style: TextStyle(
                                  color: context.c.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l.dashClassesProgress(total, necessario),
                              style: TextStyle(
                                color: jaApto
                                    ? context.sem.success
                                    : context.c.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (jaApto)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.sem.success.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l.dashEligible,
                                  style: TextStyle(
                                    color: context.sem.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else
                              Text(
                                '$pct%',
                                style: TextStyle(
                                  color: context.sem.goldOnSurface,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (totalGrad > visiveis.length)
                GestureDetector(
                  onTap: () => context.go('/admin/alunos'),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Center(
                      child: Text(
                        l.dashSeeAllStudents(totalGrad),
                        style: TextStyle(
                          color: context.sem.goldOnSurface,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── NOTÍCIAS ────────────────────────────────────────────────────────────────

  Widget _buildNoticias() {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashSectionHeader(
          l.dashLatestNews,
          trailingLabel: l.commonSeeAllFem,
          onTrailingTap: () => context.push('/admin/noticias'),
        ),
        ..._noticias.take(2).map((n) {
          final titulo = n['titulo'] as String? ?? '';
          final resumo = n['resumo'] as String? ?? '';
          final publicadaEm =
              n['publicadaEm'] as String? ?? n['publicada_em'] as String?;
          String dataLabel = '';
          if (publicadaEm != null) {
            try {
              final dt = DateTime.parse(publicadaEm).toLocal();
              dataLabel =
                  '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
            } catch (_) {}
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: GestureDetector(
              onTap: () => context.push('/admin/noticias'),
              behavior: HitTestBehavior.opaque,
              child: DashCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: context.c.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.campaign_rounded,
                        color: context.sem.goldOnSurface,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  titulo,
                                  style: TextStyle(
                                    color: context.c.onSurface,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (dataLabel.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  dataLabel,
                                  style: TextStyle(
                                    color: context.c.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (resumo.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              resumo,
                              style: TextStyle(
                                color: context.c.onSurfaceVariant,
                                fontSize: 11.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.c.onSurfaceVariant,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Onboarding model ─────────────────────────────────────────────────────────

class _OnboardingStep {
  final String titulo;
  final String descricao;
  final bool feito;
  final IconData icon;
  final VoidCallback onTap;

  const _OnboardingStep({
    required this.titulo,
    required this.descricao,
    required this.feito,
    required this.icon,
    required this.onTap,
  });
}

// ─── Bottom sheet: criar modalidade ──────────────────────────────────────────

class _ModalidadeSheet extends StatefulWidget {
  final String academiaId;
  const _ModalidadeSheet({required this.academiaId});

  @override
  State<_ModalidadeSheet> createState() => _ModalidadeSheetState();
}

class _ModalidadeSheetState extends State<_ModalidadeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final erroMsg = context.l10n.commonSaveError;
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await firestoreService.addModalidade(widget.academiaId, {
        'nome': _nomeCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'descricao': _descCtrl.text.trim(),
        'ativo': true,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _erro = erroMsg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.c.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.dashNewModalityTitle,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              l.dashNewModalityHint,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeCtrl,
              autofocus: true,
              style: TextStyle(color: context.c.onSurface),
              decoration: _dec(
                l.dashModalityNameField,
                Icons.sports_martial_arts_rounded,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.commonRequiredField
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              style: TextStyle(color: context.c.onSurface),
              decoration: _dec(
                l.commonDescriptionOptional,
                Icons.notes_rounded,
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(
                _erro!,
                style: TextStyle(color: context.sem.danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _salvar,
              style: FilledButton.styleFrom(
                backgroundColor: context.c.primary,
                foregroundColor: context.c.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.c.onPrimary,
                      ),
                    )
                  : Text(
                      l.dashCreateModality,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: context.c.onSurfaceVariant),
    prefixIcon: Icon(icon, color: context.c.onSurfaceVariant, size: 20),
    filled: true,
    fillColor: context.c.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.sem.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.sem.danger),
    ),
  );
}

// ─── Bottom sheet: criar plano ────────────────────────────────────────────────

class _PlanoSheet extends StatefulWidget {
  final String academiaId;
  const _PlanoSheet({required this.academiaId});

  @override
  State<_PlanoSheet> createState() => _PlanoSheetState();
}

class _PlanoSheetState extends State<_PlanoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _valorCtrl.dispose();
    _matriculaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final erroMsg = context.l10n.commonSaveError;
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0;
      final matricula = double.tryParse(
        _matriculaCtrl.text.replaceAll(',', '.'),
      );
      await firestoreService.addPlano(widget.academiaId, {
        'nome': _nomeCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'descricao': _descCtrl.text.trim(),
        'valor_mensal': valor,
        if (matricula != null && matricula > 0) 'taxa_matricula': matricula,
        'ativo': true,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _erro = erroMsg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.c.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.dashNewPlanTitle,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              l.dashNewPlanSubtitle,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeCtrl,
              autofocus: true,
              style: TextStyle(color: context.c.onSurface),
              decoration: _dec(l.dashPlanNameField, Icons.label_rounded),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.commonRequiredField
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(color: context.c.onSurface),
              decoration: _dec(
                l.dashPlanMonthlyValueField,
                Icons.monetization_on_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l.commonRequiredField;
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n <= 0) return l.commonEnterValidValue;
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _matriculaCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(color: context.c.onSurface),
              decoration: _dec(
                l.dashPlanEnrollmentFeeField,
                Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              style: TextStyle(color: context.c.onSurface),
              decoration: _dec(
                l.commonDescriptionOptional,
                Icons.notes_rounded,
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(
                _erro!,
                style: TextStyle(color: context.sem.danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _salvar,
              style: FilledButton.styleFrom(
                backgroundColor: context.c.primary,
                foregroundColor: context.c.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.c.onPrimary,
                      ),
                    )
                  : Text(
                      l.dashCreatePlan,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: context.c.onSurfaceVariant),
    prefixIcon: Icon(icon, color: context.c.onSurfaceVariant, size: 20),
    filled: true,
    fillColor: context.c.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.sem.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.sem.danger),
    ),
  );
}
