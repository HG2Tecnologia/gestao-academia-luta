import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ad_banner.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/paywall_modal.dart';
import '../../core/plan_service.dart';
import '../../core/widgets.dart';

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
  StoredUser? _user;
  bool _loading = true;
  bool _erro = false;
  bool _temModalidades = false;
  bool _temPlanos = false;
  bool _temProfessores = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var user = await AuthStorage.getUser();
    try {
      final futures = await Future.wait([
        dio.get('/api/dashboard/resumo'),
        dio.get('/api/dashboard/frequencia', queryParameters: {'dias': 7}),
        dio.get('/api/modalidades'),
        dio.get('/api/planos'),
        dio.get('/api/funcionarios', queryParameters: {'perfil': 'Professor'}),
        if (user?.nome.isEmpty ?? true) dio.get('/api/usuarios/me') else Future.value(null),
      ]);

      final body = futures[0]!.data as Map<String, dynamic>;
      final freqBody = futures[1]!.data as Map<String, dynamic>;
      final modalidadesData = futures[2]!.data as Map<String, dynamic>;
      final planosData = futures[3]!.data as Map<String, dynamic>;
      final professoresData = futures[4]!.data as Map<String, dynamic>;
      final modalidadesList = modalidadesData['dados'] as List? ?? [];
      final planosList = planosData['dados'] as List? ?? [];
      final professoresList = professoresData['dados'] as List? ?? [];

      if ((user?.nome.isEmpty ?? true) && futures.length > 5 && futures[5] != null) {
        final meData = futures[5]!.data as Map<String, dynamic>;
        final dados = meData['dados'] as Map<String, dynamic>?;
        if (dados != null && user != null) {
          user = StoredUser(
            id: user.id,
            nome: dados['nome'] as String? ?? user.nome,
            email: user.email,
            perfil: user.perfil,
            academiaId: user.academiaId,
          );
          await AuthStorage.save(await AuthStorage.getToken() ?? '', user);
        } else if (dados != null) {
          user = StoredUser(
            id: dados['id']?.toString() ?? '',
            nome: dados['nome'] as String? ?? '',
            email: dados['email'] as String? ?? '',
            perfil: dados['perfil'] as String? ?? '',
          );
        }
      }

      List<Map<String, dynamic>> aniversariantes = [];
      List<Map<String, dynamic>> proximosGraduacao = [];
      try {
        final anivRes = await dio.get('/api/alunos/aniversariantes');
        aniversariantes = ((anivRes.data['dados'] as List?) ?? []).cast<Map<String, dynamic>>();
      } catch (_) {}
      try {
        final proxRes = await dio.get('/api/dashboard/proximos-graduacao');
        proximosGraduacao = ((proxRes.data['dados'] as List?) ?? []).cast<Map<String, dynamic>>();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _user = user;
          _dash = body['dados'] as Map<String, dynamic>?;
          _frequencia = (freqBody['dados'] as List? ?? []).cast<Map<String, dynamic>>();
          _aniversariantes = aniversariantes;
          _proximosGraduacao = proximosGraduacao;
          _temModalidades = modalidadesList.isNotEmpty;
          _temPlanos = planosList.isNotEmpty;
          _temProfessores = professoresList.isNotEmpty;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _user = user; _loading = false; _erro = true; });
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
        backgroundColor: kBg,
        body: SafeArea(child: ErroConexao(onRetry: () { setState(() { _loading = true; _erro = false; }); _load(); })),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
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
              if (_aniversariantes.isNotEmpty)
                SliverToBoxAdapter(child: _buildAniversariantes()),
              if (_proximosGraduacao.isNotEmpty)
                SliverToBoxAdapter(child: _buildProximosGraduacao()),
              if (_frequencia.isNotEmpty)
                SliverToBoxAdapter(child: _buildFrequenciaChart()),
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
                colors: [const Color(0xFF1A0F3C), kPrimary.withOpacity(0.35)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimary.withOpacity(0.45)),
            ),
            child: Row(children: [
              Icon(Icons.hourglass_top_rounded, color: kPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Trial gratuito ativo', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(days <= 1 ? 'Último dia do trial!' : '$days dias restantes', style: TextStyle(color: kText2, fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)),
                child: const Text('Ver planos', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
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
            color: kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kWarning.withOpacity(0.55)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: kWarning.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.lock_outline_rounded, color: kWarning, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Plano Gratuito', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700)),
              Text('Limite: 3 turmas · 10 alunos/turma · anúncios', style: TextStyle(color: kText2, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kPrimary, const Color(0xFF9B6DFF)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Assinar PRO', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final nome = _user?.nome ?? '';
    final primeiroNome = nome.split(' ').first;
    final initials = nome.isNotEmpty
        ? nome.trim().split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join()
        : 'A';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0F3C), Color(0xFF0F172A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 24),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary, const Color(0xFF9B6DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    primeiroNome.isEmpty ? 'Olá!' : 'Olá, $primeiroNome!',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.1),
                  ),
                  const SizedBox(height: 2),
                  Text('Visão geral da academia', style: TextStyle(color: kText2, fontSize: 12)),
                ]),
              ),
              // Actions
              _HeaderIconButton(
                icon: Icons.settings_rounded,
                color: kText2,
                onTap: () => context.push('/admin/dashboard/configuracoes'),
                tooltip: 'Configurações',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── MÉTRICAS ─────────────────────────────────────────────────────────────────

  Widget _buildMetrics() {
    final d = _dash ?? {};
    final alunos = '${d['totalAlunos'] ?? '—'}';
    final turmas = '${d['turmasAtivas'] ?? '—'}';
    final presencas = '${d['presencasHoje'] ?? '—'}';
    final inadimplentes = '${d['alunosInadimplentes'] ?? '—'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(children: [
        // Linha principal — 2 cards grandes
        Row(children: [
          Expanded(child: _MetricCard(
            label: 'Alunos ativos',
            value: alunos,
            icon: Icons.sports_martial_arts_rounded,
            gradient: [const Color(0xFF6C3FFF), const Color(0xFF4F28C8)],
          )),
          const SizedBox(width: 12),
          Expanded(child: _MetricCard(
            label: 'Turmas ativas',
            value: turmas,
            icon: Icons.groups_rounded,
            gradient: [const Color(0xFF0EA5E9), const Color(0xFF0369A1)],
          )),
        ]),
        const SizedBox(height: 12),
        // Linha secundária — 2 cards compactos
        Row(children: [
          Expanded(child: _MetricCardSmall(
            label: 'Presenças hoje',
            value: presencas,
            icon: Icons.check_circle_rounded,
            color: kSuccess,
          )),
          const SizedBox(width: 12),
          Expanded(child: _MetricCardSmall(
            label: 'Inadimplentes',
            value: inadimplentes,
            icon: Icons.warning_amber_rounded,
            color: kDanger,
          )),
        ]),
      ]),
    );
  }

  // ─── AÇÕES RÁPIDAS ────────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      (label: 'Novo aluno', icon: Icons.person_add_rounded, color: kPrimary, onTap: () => context.push('/admin/alunos/novo')),
      (label: 'Nova turma', icon: Icons.groups_rounded, color: const Color(0xFF0EA5E9), onTap: () => context.push('/admin/turmas')),
      (label: 'Presenças', icon: Icons.qr_code_scanner_rounded, color: kSuccess, onTap: () async {
        if (PlanService.instance.showAds) {
          final ok = await mostrarPaywall(context);
          if (ok) { PlanService.instance.refresh(); setState(() {}); }
          return;
        }
        if (mounted) context.push('/scan-qr');
      }),
      (label: 'Financeiro', icon: Icons.account_balance_wallet_rounded, color: kWarning, onTap: () => context.go('/admin/financeiro')),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ações rápidas', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions.map((a) => _QuickActionButton(
            label: a.label,
            icon: a.icon,
            color: a.color,
            onTap: a.onTap,
          )).toList(),
        ),
      ]),
    );
  }

  // ─── ONBOARDING ───────────────────────────────────────────────────────────────

  Widget _buildOnboarding() {
    final d = _dash ?? {};
    final temTurma = ((d['turmasAtivas'] as num?)?.toInt() ?? 0) > 0;
    final temAluno = ((d['totalAlunos'] as num?)?.toInt() ?? 0) > 0;

    final passos = [
      _OnboardingStep(
        titulo: 'Crie uma modalidade',
        descricao: 'Ex: Jiu-Jitsu, Muay Thai, Boxe.',
        feito: _temModalidades,
        icon: Icons.sports_martial_arts_rounded,
        onTap: () async {
          final ok = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _ModalidadeSheet(),
          );
          if (ok == true) _load();
        },
      ),
      _OnboardingStep(
        titulo: 'Crie um plano de mensalidade',
        descricao: 'Defina valores e periodicidade.',
        feito: _temPlanos,
        icon: Icons.monetization_on_rounded,
        onTap: () async {
          final ok = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _PlanoSheet(),
          );
          if (ok == true) _load();
        },
      ),
      _OnboardingStep(
        titulo: 'Cadastre um professor',
        descricao: 'Turmas precisam de um professor responsável.',
        feito: _temProfessores,
        icon: Icons.school_rounded,
        onTap: () async {
          await context.push('/admin/equipe/novo');
          _load();
        },
      ),
      _OnboardingStep(
        titulo: 'Monte uma turma',
        descricao: 'Agrupe alunos por modalidade e horário.',
        feito: temTurma,
        icon: Icons.groups_rounded,
        onTap: () => context.push('/admin/turmas'),
      ),
      _OnboardingStep(
        titulo: 'Cadastre seu primeiro aluno',
        descricao: 'Adicione alunos e matricule nas turmas.',
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
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPrimary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: kPrimary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header do card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kPrimary, const Color(0xFF9B6DFF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Primeiros passos', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w800)),
                Text('Configure sua academia em ordem', style: TextStyle(color: kText2, fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$feitos/${passos.length}', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          // Barra de progresso
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progresso,
                backgroundColor: kBorder.withOpacity(0.4),
                valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                minHeight: 4,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2D3748)),
          // Passos
          ...passos.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final anterior = i > 0 ? passos[i - 1] : null;
            final bloqueado = !p.feito && anterior != null && !anterior.feito;
            final isLast = i == passos.length - 1;
            return _buildPassoTile(p, bloqueado, isLast);
          }),
        ]),
      ),
    );
  }

  Widget _buildPassoTile(_OnboardingStep p, bool bloqueado, bool isLast) {
    return InkWell(
      onTap: (p.feito || bloqueado) ? null : p.onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(20))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          // Step indicator
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.feito
                  ? kSuccess.withOpacity(0.12)
                  : bloqueado
                      ? kBorder.withOpacity(0.2)
                      : kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: p.feito
                    ? kSuccess.withOpacity(0.4)
                    : bloqueado
                        ? kBorder.withOpacity(0.4)
                        : kPrimary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              p.feito ? Icons.check_rounded : p.icon,
              size: 18,
              color: p.feito ? kSuccess : bloqueado ? kText2 : kPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              p.titulo,
              style: TextStyle(
                color: p.feito ? kText2 : bloqueado ? kText2 : kText1,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: p.feito ? TextDecoration.lineThrough : null,
                decorationColor: kText2,
              ),
            ),
            const SizedBox(height: 1),
            Text(p.descricao, style: TextStyle(color: kText2, fontSize: 11)),
          ])),
          if (!p.feito && !bloqueado)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.arrow_forward_rounded, size: 15, color: kPrimary),
            ),
          if (bloqueado)
            Icon(Icons.lock_outline_rounded, size: 15, color: kText2.withOpacity(0.5)),
        ]),
      ),
    );
  }

  // ─── ANIVERSARIANTES ─────────────────────────────────────────────────────────

  Widget _buildAniversariantes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kWarning.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: kWarning.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.cake_rounded, color: kWarning, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Aniversariantes', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('Este mês', style: TextStyle(color: kText2, fontSize: 11)),
            ])),
            GestureDetector(
              onTap: () => context.push('/admin/dashboard/aniversariantes'),
              child: Text('Ver todos', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          ..._aniversariantes.take(5).map((a) {
            final nome = a['nome']?.toString() ?? '';
            final dia = a['diaNascimento'] as int? ?? 0;
            final mes = DateTime.now().month;
            final dataLabel = dia > 0
                ? '${dia.toString().padLeft(2, '0')}/${mes.toString().padLeft(2, '0')}'
                : '';
            final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
              child: Row(children: [
                CircleAvatar(radius: 16, backgroundColor: kWarning.withOpacity(0.15),
                  child: Text(initials.isEmpty ? '?' : initials, style: TextStyle(color: kWarning, fontSize: 11, fontWeight: FontWeight.w800))),
                const SizedBox(width: 10),
                Expanded(child: Text(nome, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600))),
                Text(dataLabel, style: TextStyle(color: kText2, fontSize: 12)),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  // ─── PRÓXIMOS DE GRADUAR ──────────────────────────────────────────────────────

  Widget _buildProximosGraduacao() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPrimary.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.military_tech_rounded, color: kPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Próximos de graduar', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('Alunos próximos do mínimo de aulas', style: TextStyle(color: kText2, fontSize: 11)),
            ])),
          ]),
          const SizedBox(height: 12),
          ..._proximosGraduacao.take(8).map((a) {
            final nome = a['nomeAluno']?.toString() ?? '';
            final modalidade = a['nomeModalidade']?.toString() ?? '';
            final total = (a['totalPresencas'] as num?)?.toInt() ?? 0;
            final necessario = (a['presencasNecessarias'] as num?)?.toInt() ?? 1;
            final jaApto = a['jaApto'] == true;
            final pct = (a['percentual'] as num?)?.toInt() ?? 0;
            final alunoId = a['alunoId']?.toString() ?? '';
            final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

            return GestureDetector(
              onTap: alunoId.isNotEmpty ? () => context.push('/admin/alunos/$alunoId') : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: jaApto ? kSuccess.withOpacity(0.05) : kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: jaApto ? kSuccess.withOpacity(0.3) : kBorder),
                ),
                child: Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: (jaApto ? kSuccess : kPrimary).withOpacity(0.15),
                    child: Text(initials.isEmpty ? '?' : initials, style: TextStyle(color: jaApto ? kSuccess : kPrimary, fontSize: 11, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nome, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(modalidade, style: TextStyle(color: kText2, fontSize: 11)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$total/$necessario aulas', style: TextStyle(color: jaApto ? kSuccess : kText2, fontSize: 12, fontWeight: FontWeight.w700)),
                    if (jaApto)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: kSuccess.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text('Apto!', style: TextStyle(color: kSuccess, fontSize: 10, fontWeight: FontWeight.w700)),
                      )
                    else
                      Text('$pct%', style: TextStyle(color: kPrimary, fontSize: 11)),
                  ]),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }

  // ─── GRÁFICO DE FREQUÊNCIA ────────────────────────────────────────────────────

  Widget _buildFrequenciaChart() {
    final maxVal = _frequencia.fold<int>(1, (m, e) {
      final v = (e['total'] as num?)?.toInt() ?? 0;
      return v > m ? v : m;
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder.withOpacity(0.5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Frequência semanal', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('Últimos 7 dias', style: TextStyle(color: kText2, fontSize: 11)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kSuccess.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(Icons.trending_up_rounded, color: kSuccess, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_frequencia.fold(0, (s, e) => s + ((e['total'] as num?)?.toInt() ?? 0))} total',
                  style: TextStyle(color: kSuccess, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _frequencia.asMap().entries.map((entry) {
                final item = entry.value;
                final val = (item['total'] as num?)?.toInt() ?? 0;
                final ratio = maxVal > 0 ? val / maxVal : 0.0;
                final data = (item['data'] as String? ?? '').split('-');
                final dia = data.length == 3 ? data[2] : '?';
                final mes = data.length == 3 ? data[1] : '';
                final isMax = val == maxVal && val > 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text(
                            '$val',
                            style: TextStyle(
                              color: isMax ? kPrimary : kText2,
                              fontSize: 10,
                              fontWeight: isMax ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        const SizedBox(height: 3),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: ratio.clamp(0.04, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isMax
                                      ? [kPrimary, kPrimary.withOpacity(0.6)]
                                      : [kPrimary.withOpacity(0.5), kPrimary.withOpacity(0.2)],
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('$dia', style: TextStyle(color: kText1, fontSize: 10, fontWeight: FontWeight.w600)),
                        Text(mes.isNotEmpty ? '/$mes' : '', style: TextStyle(color: kText2, fontSize: 8)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _HeaderIconButton({required this.icon, required this.color, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _MetricCard({required this.label, required this.value, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.white.withOpacity(0.85), size: 24),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _MetricCardSmall extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCardSmall({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
          Text(label, style: TextStyle(color: kText2, fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: kText2, fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
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
    setState(() { _loading = true; _erro = null; });
    try {
      final res = await dio.post('/api/modalidades', data: {
        'nome': _nomeCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty) 'descricao': _descCtrl.text.trim(),
      });
      final body = res.data as Map<String, dynamic>;
      if (body['sucesso'] == true) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() => _erro = body['mensagem'] ?? 'Erro ao salvar.');
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['mensagem'] ?? e.response!.data.toString())
          : 'Erro ${e.response?.statusCode ?? "de conexão"}.';
      setState(() => _erro = msg);
    } catch (e) {
      setState(() => _erro = 'Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: kSurface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Nova modalidade', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
          Text('Ex: Jiu-Jitsu, Muay Thai, Boxe, Luta Livre', style: TextStyle(color: kText2, fontSize: 12)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nomeCtrl,
            autofocus: true,
            style: TextStyle(color: kText1),
            decoration: _dec('Nome da modalidade', Icons.sports_martial_arts_rounded),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descCtrl,
            style: TextStyle(color: kText1),
            decoration: _dec('Descrição (opcional)', Icons.notes_rounded),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 10),
            Text(_erro!, style: TextStyle(color: kDanger, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _salvar,
            style: FilledButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Criar modalidade', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: kText2),
    prefixIcon: Icon(icon, color: kText2, size: 20),
    filled: true,
    fillColor: kBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
  );
}

// ─── Bottom sheet: criar plano ────────────────────────────────────────────────

class _PlanoSheet extends StatefulWidget {
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
    setState(() { _loading = true; _erro = null; });
    try {
      final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0;
      final matricula = double.tryParse(_matriculaCtrl.text.replaceAll(',', '.'));
      final res = await dio.post('/api/planos', data: {
        'nome': _nomeCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty) 'descricao': _descCtrl.text.trim(),
        'valorMensal': valor,
        if (matricula != null && matricula > 0) 'taxaMatricula': matricula,
      });
      final body = res.data as Map<String, dynamic>;
      if (body['sucesso'] == true) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() => _erro = body['mensagem'] ?? 'Erro ao salvar.');
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['mensagem'] ?? e.response!.data.toString())
          : 'Erro ${e.response?.statusCode ?? "de conexão"}.';
      setState(() => _erro = msg);
    } catch (e) {
      setState(() => _erro = 'Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: kSurface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Novo plano de mensalidade', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
          Text('Defina o valor que seus alunos pagarão.', style: TextStyle(color: kText2, fontSize: 12)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nomeCtrl,
            autofocus: true,
            style: TextStyle(color: kText1),
            decoration: _dec('Nome do plano (ex: Mensal, Trimestral)', Icons.label_rounded),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _valorCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: kText1),
            decoration: _dec('Valor mensal (R\$)', Icons.monetization_on_rounded),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Obrigatório';
              final n = double.tryParse(v.replaceAll(',', '.'));
              if (n == null || n <= 0) return 'Informe um valor válido';
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _matriculaCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: kText1),
            decoration: _dec('Taxa de matrícula (opcional)', Icons.receipt_long_rounded),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descCtrl,
            style: TextStyle(color: kText1),
            decoration: _dec('Descrição (opcional)', Icons.notes_rounded),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 10),
            Text(_erro!, style: TextStyle(color: kDanger, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _salvar,
            style: FilledButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Criar plano', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: kText2),
    prefixIcon: Icon(icon, color: kText2, size: 20),
    filled: true,
    fillColor: kBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
  );
}
