import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';
import '../../core/widgets.dart';

class AlunoRankingScreen extends StatefulWidget {
  const AlunoRankingScreen({super.key});

  @override
  State<AlunoRankingScreen> createState() => _AlunoRankingScreenState();
}

class _AlunoRankingScreenState extends State<AlunoRankingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Geral
  List<Map<String, dynamic>> _itemsGeral = [];
  bool _loadingGeral = true;
  bool _erroGeral = false;
  String? _meuId;

  // Personalizados
  List<Map<String, dynamic>> _customRankings = [];
  Map<String, dynamic>? _customSelecionado;
  List<Map<String, dynamic>> _itemsCustom = [];
  bool _loadingCustom = true;
  bool _loadingCustomLb = false;
  bool _erroCustom = false;

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final user = await AuthStorage.getUser();
    if (mounted) {
      setState(() {
        _meuId = user?.id;
        _academiaId = user?.academiaId;
      });
    }
    if (user?.academiaId != null) {
      await Future.wait([
        _loadGeral(),
        _loadCustomRankings(),
      ]);
    }
  }

  Future<void> _loadGeral() async {
    if (_academiaId == null) return;
    if (mounted) setState(() { _loadingGeral = true; _erroGeral = false; });
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
    if (mounted) setState(() { _loadingCustom = true; _erroCustom = false; });
    try {
      final list = await firestoreService.getRankingsCustom(_academiaId!);
      final visiveis = list.where((r) => r['visivelParaAluno'] == true && r['ativo'] == true).toList();
      if (mounted) {
        setState(() => _customRankings = visiveis);
        if (visiveis.isNotEmpty) _selecionarCustom(visiveis.first);
      }
    } catch (_) {
      if (mounted) setState(() => _erroCustom = true);
    } finally {
      if (mounted) setState(() => _loadingCustom = false);
    }
  }

  Future<void> _selecionarCustom(Map<String, dynamic> r) async {
    if (_academiaId == null) return;
    setState(() { _customSelecionado = r; _loadingCustomLb = true; _itemsCustom = []; });
    try {
      final items = await firestoreService.getLancamentosPonto(_academiaId!, r['id'] as String);
      if (mounted) setState(() => _itemsCustom = items);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingCustomLb = false);
    }
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kPrimary : kSurface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? kPrimary : kBorder),
        ),
        child: Text(label,
            style: TextStyle(color: selected ? Colors.white : kText2, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _medalha(int pos) {
    if (pos == 1) return '🥇';
    if (pos == 2) return '🥈';
    if (pos == 3) return '🥉';
    return '#$pos';
  }

  Widget _leaderboardGeralContent() {
    if (_loadingGeral) return Center(child: CircularProgressIndicator(color: kPrimary));
    if (_erroGeral) return ErroConexao(onRetry: _loadGeral);
    if (_itemsGeral.isEmpty) {
      return ListaVazia(
        icon: Icons.emoji_events_outlined,
        titulo: 'Sem dados para este período',
        subtitulo: 'Treine mais para aparecer no ranking!',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _itemsGeral.length,
      itemBuilder: (_, i) {
        final item = _itemsGeral[i];
        final pos = (item['posicao'] as num?)?.toInt() ?? (i + 1);
        final ehEu = item['id'] == _meuId;
        final nome = item['nome'] as String? ?? '—';
        final xp = (item['xp_total'] as num?)?.toInt() ?? 0;
        final nivel = item['nivel']?.toString() ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: ehEu ? kPrimary.withOpacity(0.08) : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ehEu ? kPrimary.withOpacity(0.4) : kBorder),
          ),
          child: Row(children: [
            SizedBox(
              width: 36,
              child: Text(_medalha(pos),
                  style: TextStyle(fontSize: pos <= 3 ? 20 : 14, fontWeight: FontWeight.w700, color: kText1)),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nome, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
                if (nivel.isNotEmpty)
                  Text(nivel, style: TextStyle(color: kText2, fontSize: 11)),
              ]),
            ),
            Text('$xp XP', style: TextStyle(color: ehEu ? kPrimary : kText1, fontSize: 14, fontWeight: FontWeight.w700)),
            if (ehEu) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text('Você', style: TextStyle(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
        );
      },
    );
  }

  Widget _customContent() {
    if (_loadingCustom) return Center(child: CircularProgressIndicator(color: kPrimary));
    if (_erroCustom) return ErroConexao(onRetry: _loadCustomRankings);
    if (_customRankings.isEmpty) {
      return ListaVazia(
        icon: Icons.leaderboard_outlined,
        titulo: 'Sem rankings personalizados',
        subtitulo: 'A academia ainda não criou rankings personalizados visiveis.',
      );
    }

    return Column(children: [
      // Seletor de ranking
      SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          itemCount: _customRankings.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final r = _customRankings[i];
            final sel = _customSelecionado?['id'] == r['id'];
            return GestureDetector(
              onTap: () => _selecionarCustom(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? kPrimary : kSurface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: sel ? kPrimary : kBorder),
                ),
                child: Text(r['nome'] ?? '—',
                    style: TextStyle(color: sel ? Colors.white : kText2, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 4),
      Expanded(child: _customLeaderboard()),
    ]);
  }

  Widget _customLeaderboard() {
    if (_loadingCustomLb) return Center(child: CircularProgressIndicator(color: kPrimary));
    if (_itemsCustom.isEmpty) {
      return ListaVazia(
        icon: Icons.emoji_events_outlined,
        titulo: 'Nenhum participante',
        subtitulo: 'Este ranking ainda não tem dados.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _itemsCustom.length,
      itemBuilder: (_, i) {
        final item = _itemsCustom[i];
        final pos = i + 1;
        final ehEu = item['aluno_id'] == _meuId;
        final pontos = (item['pontos'] as num?)?.toInt() ?? 0;
        final nome = item['nomeAluno'] as String? ?? '—';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: ehEu ? kPrimary.withOpacity(0.08) : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ehEu ? kPrimary.withOpacity(0.4) : kBorder),
          ),
          child: Row(children: [
            SizedBox(
              width: 36,
              child: Text(_medalha(pos),
                  style: TextStyle(fontSize: pos <= 3 ? 20 : 14, fontWeight: FontWeight.w700, color: kText1)),
            ),
            Expanded(
              child: Text(nome, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            Text('$pontos pts', style: TextStyle(color: ehEu ? kPrimary : kText1, fontSize: 14, fontWeight: FontWeight.w700)),
            if (ehEu) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text('Você', style: TextStyle(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 12, 0),
            child: Row(children: [
              GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Rankings',
                    style: TextStyle(color: kText1, fontSize: 26, fontWeight: FontWeight.w900)),
              ),
              IconButton(
                onPressed: () => context.push('/aluno/ranking/conquistas'),
                icon: const Icon(Icons.military_tech_rounded, color: Color(0xFFFFD700), size: 30),
                tooltip: 'Conquistas',
              ),
            ]),
          ),

          // TabBar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: kText2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Ranking Geral'),
                Tab(text: 'Personalizados'),
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
                  color: kPrimary,
                  child: _leaderboardGeralContent(),
                ),
                RefreshIndicator(
                  onRefresh: _loadCustomRankings,
                  color: kPrimary,
                  child: _customContent(),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
