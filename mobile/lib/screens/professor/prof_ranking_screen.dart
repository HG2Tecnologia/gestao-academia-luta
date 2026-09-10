import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';
import '../../core/widgets.dart';

class ProfRankingScreen extends StatefulWidget {
  const ProfRankingScreen({super.key});

  @override
  State<ProfRankingScreen> createState() => _ProfRankingScreenState();
}

class _ProfRankingScreenState extends State<ProfRankingScreen>
    with SingleTickerProviderStateMixin {
  AppLocalizations get _l => context.l10n;
  late final TabController _tabController;

  // Geral
  List<Map<String, dynamic>> _itemsGeral = [];
  bool _loadingGeral = true;
  bool _erroGeral = false;

  // Personalizados
  List<Map<String, dynamic>> _rankings = [];
  bool _loadingCustom = true;
  bool _erroCustom = false;

  bool _isAdmin = false;
  String? _academiaId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _init();
  }

  Future<void> _init() async {
    final user = await AuthStorage.getUser();
    if (mounted) {
      setState(() {
        _isAdmin = user?.perfil == 'Admin' || user?.perfil == 'Dono';
        _academiaId = user?.academiaId;
      });
    }
    if (user?.academiaId != null) {
      await Future.wait([_loadGeral(), _loadCustomRankings()]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGeral() async {
    if (_academiaId == null) return;
    if (mounted)
      setState(() {
        _loadingGeral = true;
        _erroGeral = false;
      });
    try {
      final items = await firestoreService.getLeaderboard(_academiaId!);
      if (mounted) setState(() => _itemsGeral = items);
    } catch (_) {
      if (mounted) setState(() => _erroGeral = true);
    } finally {
      if (mounted) setState(() => _loadingGeral = false);
    }
  }

  Future<void> _loadCustomRankings() async {
    if (_academiaId == null) return;
    if (mounted)
      setState(() {
        _loadingCustom = true;
        _erroCustom = false;
      });
    try {
      final list = await firestoreService.getRankingsCustom(_academiaId!);
      if (mounted) setState(() => _rankings = list);
    } catch (_) {
      if (mounted) setState(() => _erroCustom = true);
    } finally {
      if (mounted) setState(() => _loadingCustom = false);
    }
  }

  String _medalha(int pos) {
    if (pos == 1) return '🥇';
    if (pos == 2) return '🥈';
    if (pos == 3) return '🥉';
    return '#$pos';
  }

  Widget _geralContent() {
    if (_loadingGeral)
      return Center(child: CircularProgressIndicator(color: context.c.primary));
    if (_erroGeral) return ErroConexao(onRetry: _loadGeral);
    if (_itemsGeral.isEmpty) {
      return ListaVazia(
        icon: Icons.emoji_events_outlined,
        titulo: _l.rkNoData,
        subtitulo: _l.rkStudentsAppearHere,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _itemsGeral.length,
      itemBuilder: (_, i) {
        final item = _itemsGeral[i];
        final pos = (item['posicao'] as num?)?.toInt() ?? (i + 1);
        final nome =
            item['nome'] as String? ?? item['nomeAluno'] as String? ?? '—';
        final xp = (item['xp_total'] as num?)?.toInt() ?? 0;
        final nivel = item['nivel']?.toString() ?? '';
        final isTop3 = pos <= 3;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isTop3
                ? context.c.primary.withOpacity(0.06)
                : context.c.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTop3
                  ? context.c.primary.withOpacity(0.2)
                  : context.c.outline,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  _medalha(pos),
                  style: TextStyle(
                    fontSize: isTop3 ? 20 : 14,
                    fontWeight: FontWeight.w700,
                    color: context.c.onSurface,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: context.c.primary.withOpacity(0.15),
                child: Text(
                  nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: context.c.primary,
                    fontSize: 13,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (nivel.isNotEmpty)
                      Text(
                        nivel,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '$xp XP',
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _customContent() {
    if (_loadingCustom)
      return Center(child: CircularProgressIndicator(color: context.c.primary));
    if (_erroCustom) return ErroConexao(onRetry: _loadCustomRankings);
    if (_rankings.isEmpty) {
      if (_isAdmin) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.leaderboard_outlined,
                color: context.c.onSurfaceVariant,
                size: 52,
              ),
              const SizedBox(height: 14),
              Text(
                _l.rkNoCustom,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _l.rkCreateHint,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.push('/admin/rankings'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  _l.rkCreate,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.c.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return ListaVazia(
        icon: Icons.leaderboard_outlined,
        titulo: _l.rkNoCustom,
        subtitulo: _l.rkAskAdmin,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadCustomRankings,
      color: context.c.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rankings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _RankingCard(
          ranking: _rankings[i],
          academiaId: _academiaId ?? '',
          onPontuar:
              _rankings[i]['incluirPontosManuais'] == true ||
                  _rankings[i]['incluir_pontos_manuais'] == true
              ? () async {
                  await _abrirLancarPontos(_rankings[i]);
                  _loadCustomRankings();
                }
              : null,
          onVerLeaderboard: () => _abrirLeaderboard(_rankings[i]),
        ),
      ),
    );
  }

  Future<void> _abrirLancarPontos(Map<String, dynamic> ranking) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LancarPontosSheet(
        rankingId: ranking['id'] as String,
        academiaId: _academiaId ?? '',
      ),
    );
  }

  void _abrirLeaderboard(Map<String, dynamic> ranking) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _LeaderboardScreen(ranking: ranking, academiaId: _academiaId ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: openAppDrawer,
                    child: Icon(
                      Icons.menu_rounded,
                      color: context.c.onSurface,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Rankings',
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  if (_isAdmin)
                    TextButton.icon(
                      onPressed: () => context.push('/admin/rankings'),
                      icon: Icon(
                        Icons.settings_rounded,
                        size: 16,
                        color: context.c.primary,
                      ),
                      label: Text(
                        _l.rkManage,
                        style: TextStyle(
                          color: context.c.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // TabBar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              decoration: BoxDecoration(
                color: context.c.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.c.outline),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: context.c.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: context.c.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: _l.rkGeneralRanking),
                  Tab(text: _l.rkCustomTab),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    onRefresh: _loadGeral,
                    color: context.c.primary,
                    child: _geralContent(),
                  ),
                  _customContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card de ranking personalizado ───────────────────────────────────────────

class _RankingCard extends StatelessWidget {
  final Map<String, dynamic> ranking;
  final String academiaId;
  final VoidCallback? onPontuar;
  final VoidCallback onVerLeaderboard;

  const _RankingCard({
    required this.ranking,
    required this.academiaId,
    required this.onPontuar,
    required this.onVerLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final incPresencas =
        ranking['incluirPresencas'] as bool? ??
        ranking['incluir_presencas'] as bool? ??
        false;
    final incManuais =
        ranking['incluirPontosManuais'] as bool? ??
        ranking['incluir_pontos_manuais'] as bool? ??
        false;
    final ativo = ranking['ativo'] as bool? ?? true;

    return Opacity(
      opacity: ativo ? 1.0 : 0.5,
      child: InkWell(
        onTap: onVerLeaderboard,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.c.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.c.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ranking['nome'] as String? ?? '',
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!ativo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.sem.danger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.l10n.statusInactive,
                        style: TextStyle(
                          color: context.sem.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.c.onSurfaceVariant,
                  ),
                ],
              ),
              if ((ranking['descricao'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  ranking['descricao'] as String,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  if (incPresencas)
                    _tagChip(
                      context.l10n.rkWeightAttendance(
                        ranking['pesoPresencas'] ??
                            ranking['peso_presencas'] ??
                            1,
                      ),
                      context.c.primary,
                    ),
                  if (incManuais)
                    _tagChip(
                      context.l10n.rkWeightManual(
                        ranking['pesoManuais'] ?? ranking['peso_manuais'] ?? 1,
                      ),
                      context.sem.success,
                    ),
                  if (ranking['dataInicio'] != null ||
                      ranking['data_inicio'] != null ||
                      ranking['dataFim'] != null ||
                      ranking['data_fim'] != null)
                    _tagChip(context.l10n.rkWithPeriod, context.sem.warning),
                ],
              ),
              if (onPontuar != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onPontuar,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 16,
                    ),
                    label: Text(context.l10n.rkAddPoints),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.sem.success.withOpacity(0.15),
                      foregroundColor: context.sem.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

// ─── Leaderboard de ranking personalizado ────────────────────────────────────

class _LeaderboardScreen extends StatefulWidget {
  final Map<String, dynamic> ranking;
  final String academiaId;
  const _LeaderboardScreen({required this.ranking, required this.academiaId});

  @override
  State<_LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<_LeaderboardScreen> {
  AppLocalizations get _l => context.l10n;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = false;
    });
    try {
      final items = await firestoreService.getLancamentosPonto(
        widget.academiaId,
        widget.ranking['id'] as String,
      );
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incManuais =
        widget.ranking['incluirPontosManuais'] as bool? ??
        widget.ranking['incluir_pontos_manuais'] as bool? ??
        false;

    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        elevation: 0,
        title: Text(
          widget.ranking['nome'] as String? ?? 'Ranking',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (incManuais)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: _l.rkAddPoints,
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: context.c.surfaceContainer,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) => _LancarPontosSheet(
                    rankingId: widget.ranking['id'] as String,
                    academiaId: widget.academiaId,
                  ),
                );
                _load();
              },
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.c.primary))
          : _erro
          ? ErroConexao(onRetry: _load)
          : _items.isEmpty
          ? ListaVazia(
              icon: Icons.emoji_events_outlined,
              titulo: _l.rkNoParticipants,
              subtitulo: _l.rkNobodyScored,
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: context.c.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  final pos = i + 1;
                  final nome =
                      item['nomeAluno'] as String? ??
                      item['aluno_id'] as String? ??
                      '—';
                  final pontos =
                      (item['pontos'] as num?)?.toInt() ??
                      (item['totalPontos'] as num?)?.toInt() ??
                      0;
                  final isTop3 = pos <= 3;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isTop3
                            ? context.c.primary.withOpacity(0.08)
                            : context.c.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTop3
                              ? context.c.primary.withOpacity(0.25)
                              : context.c.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              pos == 1
                                  ? '🥇'
                                  : pos == 2
                                  ? '🥈'
                                  : pos == 3
                                  ? '🥉'
                                  : '#$pos',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTop3 ? 18 : 13,
                                fontWeight: FontWeight.w800,
                                color: context.c.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: context.c.primary.withOpacity(
                              0.15,
                            ),
                            child: Text(
                              nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: context.c.primary,
                                fontSize: 13,
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$pontos',
                                style: TextStyle(
                                  color: context.c.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'pontos',
                                style: TextStyle(
                                  color: context.c.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ─── Sheet: Lançar pontos ────────────────────────────────────────────────────

class _LancarPontosSheet extends StatefulWidget {
  final String rankingId;
  final String academiaId;
  const _LancarPontosSheet({required this.rankingId, required this.academiaId});

  @override
  State<_LancarPontosSheet> createState() => _LancarPontosSheetState();
}

class _LancarPontosSheetState extends State<_LancarPontosSheet> {
  AppLocalizations get _l => context.l10n;
  final _formKey = GlobalKey<FormState>();
  final _pontosCtrl = TextEditingController(text: '1');
  final _descCtrl = TextEditingController();
  String? _alunoId;
  bool _saving = false;
  List<Map<String, dynamic>> _alunos = [];
  bool _loadingAlunos = true;

  @override
  void initState() {
    super.initState();
    _loadAlunos();
  }

  @override
  void dispose() {
    _pontosCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAlunos() async {
    try {
      final list = await firestoreService.getAlunos(
        widget.academiaId,
        ativosOnly: true,
      );
      if (mounted) setState(() => _alunos = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingAlunos = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _alunoId == null) return;
    setState(() => _saving = true);
    try {
      await firestoreService.addLancamentoPonto(widget.academiaId, {
        'aluno_id': _alunoId,
        'ranking_id': widget.rankingId,
        'pontos': int.tryParse(_pontosCtrl.text) ?? 1,
        'descricao': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'academia_id': widget.academiaId,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.rkAddPointsError),
            backgroundColor: context.sem.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDec({String? hint}) => InputDecoration(
    filled: true,
    fillColor: context.c.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.c.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.c.outline),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    hintText: hint,
    hintStyle: TextStyle(color: context.c.onSurfaceVariant),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              _l.rkAddPoints,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Aluno',
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _loadingAlunos
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _alunoId,
                    dropdownColor: context.c.surfaceContainer,
                    decoration: _inputDec(hint: _l.fiSelectStudent),
                    style: TextStyle(color: context.c.onSurface, fontSize: 14),
                    items: _alunos
                        .map(
                          (a) => DropdownMenuItem<String>(
                            value: a['id'] as String?,
                            child: Text(a['nome'] as String? ?? '—'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _alunoId = v),
                    validator: (v) => v == null ? _l.fiSelectStudent : null,
                  ),
            const SizedBox(height: 14),

            Text(
              _l.sdPoints,
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _pontosCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.c.onSurface),
              decoration: _inputDec(),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return _l.rkInvalidValue;
                return null;
              },
            ),
            const SizedBox(height: 14),

            Text(
              _l.rkReasonOptional,
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              style: TextStyle(color: context.c.onSurface),
              decoration: _inputDec(hint: _l.rkReasonHint1),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _salvar,
                style: FilledButton.styleFrom(
                  backgroundColor: context.c.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _l.commonConfirm,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
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
