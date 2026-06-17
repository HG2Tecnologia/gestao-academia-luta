import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/widgets.dart';

class ProfRankingScreen extends StatefulWidget {
  const ProfRankingScreen({super.key});

  @override
  State<ProfRankingScreen> createState() => _ProfRankingScreenState();
}

class _ProfRankingScreenState extends State<ProfRankingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Geral
  String _periodoGeral = 'mensal';
  List<Map<String, dynamic>> _itemsGeral = [];
  bool _loadingGeral = true;
  bool _erroGeral = false;

  // Personalizados
  List<Map<String, dynamic>> _rankings = [];
  bool _loadingCustom = true;
  bool _erroCustom = false;

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    Future.wait([_loadGeral(), _loadCustomRankings(), _checkRole()]);
  }

  Future<void> _checkRole() async {
    final user = await AuthStorage.getUser();
    if (mounted) setState(() => _isAdmin = user?.perfil == 'Admin' || user?.perfil == 'Dono');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGeral() async {
    if (mounted) setState(() { _loadingGeral = true; _erroGeral = false; });
    try {
      final res = await dio.get('/api/ranking/leaderboard/academia',
          queryParameters: {'periodo': _periodoGeral, 'pagina': 1});
      final body = res.data as Map<String, dynamic>;
      final dados = body['dados'] ?? body;
      final items = (dados is Map ? dados['items'] : null) ?? [];
      if (mounted) setState(() => _itemsGeral = (items as List).cast<Map<String, dynamic>>());
    } catch (_) {
      if (mounted) setState(() => _erroGeral = true);
    } finally {
      if (mounted) setState(() => _loadingGeral = false);
    }
  }

  Future<void> _loadCustomRankings() async {
    if (mounted) setState(() { _loadingCustom = true; _erroCustom = false; });
    try {
      final res = await dio.get('/api/ranking/custom');
      final data = res.data;
      final list = data is List
          ? data.cast<Map<String, dynamic>>()
          : (data is Map ? ((data['dados'] ?? data['itens'] ?? []) as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[]);
      if (mounted) setState(() => _rankings = list);
    } catch (_) {
      if (mounted) setState(() => _erroCustom = true);
    } finally {
      if (mounted) setState(() => _loadingCustom = false);
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

  Widget _geralContent() {
    if (_loadingGeral) return Center(child: CircularProgressIndicator(color: kPrimary));
    if (_erroGeral) return ErroConexao(onRetry: _loadGeral);
    if (_itemsGeral.isEmpty) {
      return ListaVazia(
        icon: Icons.emoji_events_outlined,
        titulo: 'Sem dados para este período',
        subtitulo: 'Alunos aparecem aqui conforme registram presenças.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _itemsGeral.length,
      itemBuilder: (_, i) {
        final item = _itemsGeral[i];
        final pos = (item['posicao'] as num?)?.toInt() ?? (i + 1);
        final nome = item['nomeAluno'] ?? '—';
        final xp = _periodoGeral == 'mensal'
            ? (item['xpPeriodo'] as num?)?.toInt() ?? 0
            : (item['xpTotal'] as num?)?.toInt() ?? 0;
        final nivel = item['nivel']?.toString() ?? '';
        final isTop3 = pos <= 3;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isTop3 ? kPrimary.withOpacity(0.06) : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isTop3 ? kPrimary.withOpacity(0.2) : kBorder),
          ),
          child: Row(children: [
            SizedBox(
              width: 36,
              child: Text(_medalha(pos),
                  style: TextStyle(fontSize: isTop3 ? 20 : 14, fontWeight: FontWeight.w700, color: kText1)),
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor: kPrimary.withOpacity(0.15),
              child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                  style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nome, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
                if (nivel.isNotEmpty)
                  Text(nivel, style: TextStyle(color: kText2, fontSize: 11)),
              ]),
            ),
            Text('$xp XP', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        );
      },
    );
  }

  Widget _customContent() {
    if (_loadingCustom) return Center(child: CircularProgressIndicator(color: kPrimary));
    if (_erroCustom) return ErroConexao(onRetry: _loadCustomRankings);
    if (_rankings.isEmpty) {
      if (_isAdmin) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.leaderboard_outlined, color: kText2, size: 52),
              const SizedBox(height: 14),
              Text('Nenhum ranking personalizado', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Crie um ranking por presença ou pontos.', style: TextStyle(color: kText2, fontSize: 13)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.push('/admin/rankings'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Criar Ranking', style: TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
        );
      }
      return ListaVazia(
        icon: Icons.leaderboard_outlined,
        titulo: 'Nenhum ranking personalizado',
        subtitulo: 'Peça ao administrador que crie rankings personalizados.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadCustomRankings,
      color: kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rankings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _RankingCard(
          ranking: _rankings[i],
          onPontuar: _rankings[i]['incluirPontosManuais'] == true
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
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LancarPontosSheet(rankingId: ranking['id'] as String),
    );
  }

  void _abrirLeaderboard(Map<String, dynamic> ranking) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _LeaderboardScreen(ranking: ranking),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 20, 0),
            child: Row(
              children: [
                GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
                const SizedBox(width: 14),
                Text('Rankings', style: TextStyle(color: kText1, fontSize: 26, fontWeight: FontWeight.w900)),
                const Spacer(),
                if (_isAdmin)
                  TextButton.icon(
                    onPressed: () => context.push('/admin/rankings'),
                    icon: Icon(Icons.settings_rounded, size: 16, color: kPrimary),
                    label: Text('Gerenciar', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  ),
              ],
            ),
          ),

          // TabBar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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

          // Period chips (only for Geral)
          if (_tabController.index == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                _chip('📅 Mensal', _periodoGeral == 'mensal', () {
                  setState(() => _periodoGeral = 'mensal');
                  _loadGeral();
                }),
                const SizedBox(width: 8),
                _chip('🏆 Histórico', _periodoGeral == 'historico', () {
                  setState(() => _periodoGeral = 'historico');
                  _loadGeral();
                }),
              ]),
            ),

          const SizedBox(height: 8),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadGeral,
                  color: kPrimary,
                  child: _geralContent(),
                ),
                _customContent(),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Card de ranking personalizado ───────────────────────────────────────────

class _RankingCard extends StatelessWidget {
  final Map<String, dynamic> ranking;
  final VoidCallback? onPontuar;
  final VoidCallback onVerLeaderboard;

  const _RankingCard({
    required this.ranking,
    required this.onPontuar,
    required this.onVerLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final incPresencas = ranking['incluirPresencas'] as bool? ?? false;
    final incManuais = ranking['incluirPontosManuais'] as bool? ?? false;
    final ativo = ranking['ativo'] as bool? ?? true;

    return Opacity(
      opacity: ativo ? 1.0 : 0.5,
      child: InkWell(
        onTap: onVerLeaderboard,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(ranking['nome'] as String? ?? '',
                    style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              if (!ativo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: kDanger.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text('Inativo', style: TextStyle(color: kDanger, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              Icon(Icons.chevron_right_rounded, color: kText2),
            ]),
            if ((ranking['descricao'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(ranking['descricao'] as String,
                  style: TextStyle(color: kText2, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 6, children: [
              if (incPresencas) _tagChip('Presenças ×${ranking['pesoPresencas'] ?? 1}', kPrimary),
              if (incManuais) _tagChip('Manual ×${ranking['pesoManuais'] ?? 1}', kSuccess),
              if (ranking['dataInicio'] != null || ranking['dataFim'] != null)
                _tagChip('📅 Com período', kWarning),
            ]),
            if (onPontuar != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPontuar,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Lançar pontos'),
                  style: FilledButton.styleFrom(
                    backgroundColor: kSuccess.withOpacity(0.15),
                    foregroundColor: kSuccess,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _tagChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// ─── Leaderboard de ranking personalizado ────────────────────────────────────

class _LeaderboardScreen extends StatefulWidget {
  final Map<String, dynamic> ranking;
  const _LeaderboardScreen({required this.ranking});

  @override
  State<_LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<_LeaderboardScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = false; });
    try {
      final res = await dio.get('/api/ranking/custom/${widget.ranking['id']}/leaderboard');
      final body = res.data as Map<String, dynamic>;
      final dados = body['dados'] ?? body;
      final list = dados is Map ? dados['items'] ?? [] : (dados is List ? dados : []);
      if (mounted) setState(() => _items = (list as List).cast<Map<String, dynamic>>());
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incManuais = widget.ranking['incluirPontosManuais'] as bool? ?? false;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        elevation: 0,
        title: Text(widget.ranking['nome'] as String? ?? 'Ranking',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (incManuais)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Lançar pontos',
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: kSurface,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => _LancarPontosSheet(rankingId: widget.ranking['id'] as String),
                );
                _load();
              },
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kPrimary))
          : _erro
              ? ErroConexao(onRetry: _load)
              : _items.isEmpty
                  ? ListaVazia(
                      icon: Icons.emoji_events_outlined,
                      titulo: 'Sem participantes',
                      subtitulo: 'Ninguém pontuou neste ranking ainda.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: kPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          final pos = (item['posicao'] as num?)?.toInt() ?? (i + 1);
                          final nome = item['nomeAluno'] as String? ?? '—';
                          final pontos = (item['totalPontos'] as num?)?.toInt() ?? 0;
                          final isTop3 = pos <= 3;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isTop3 ? kPrimary.withOpacity(0.08) : kSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isTop3 ? kPrimary.withOpacity(0.25) : kBorder),
                              ),
                              child: Row(children: [
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    pos == 1 ? '🥇' : pos == 2 ? '🥈' : pos == 3 ? '🥉' : '#$pos',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: isTop3 ? 18 : 13,
                                        fontWeight: FontWeight.w800,
                                        color: kText2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: kPrimary.withOpacity(0.15),
                                  child: Text(
                                    nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                                    style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(nome,
                                      style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
                                ),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('$pontos',
                                      style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w800)),
                                  Text('pontos', style: TextStyle(color: kText2, fontSize: 10)),
                                ]),
                              ]),
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
  const _LancarPontosSheet({required this.rankingId});

  @override
  State<_LancarPontosSheet> createState() => _LancarPontosSheetState();
}

class _LancarPontosSheetState extends State<_LancarPontosSheet> {
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
      final res = await dio.get('/api/alunos', queryParameters: {'pagina': 1, 'tamanhoPagina': 200});
      final body = res.data as Map<String, dynamic>;
      final dados = body['dados'] ?? body;
      final itens = dados is Map ? (dados['itens'] ?? dados['items'] ?? []) : (dados is List ? dados : []);
      if (mounted) setState(() => _alunos = (itens as List).cast<Map<String, dynamic>>());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingAlunos = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _alunoId == null) return;
    setState(() => _saving = true);
    try {
      await dio.post('/api/ranking/custom/${widget.rankingId}/pontuar', data: {
        'alunoId': _alunoId,
        'pontos': int.tryParse(_pontosCtrl.text) ?? 1,
        'descricao': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      });
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.response?.data?['mensagem'] ?? 'Erro ao lançar pontos'),
          backgroundColor: kDanger,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDec({String? hint}) => InputDecoration(
    filled: true,
    fillColor: kBg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    hintText: hint,
    hintStyle: TextStyle(color: kText2),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Lançar pontos', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          Text('Aluno', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _loadingAlunos
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  value: _alunoId,
                  dropdownColor: kSurface,
                  decoration: _inputDec(hint: 'Selecione o aluno'),
                  style: TextStyle(color: kText1, fontSize: 14),
                  items: _alunos.map((a) => DropdownMenuItem<String>(
                    value: a['id'] as String?,
                    child: Text(a['nome'] as String? ?? '—'),
                  )).toList(),
                  onChanged: (v) => setState(() => _alunoId = v),
                  validator: (v) => v == null ? 'Selecione um aluno' : null,
                ),
          const SizedBox(height: 14),

          Text('Pontos', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _pontosCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: kText1),
            decoration: _inputDec(),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 1) return 'Valor inválido';
              return null;
            },
          ),
          const SizedBox(height: 14),

          Text('Motivo (opcional)', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descCtrl,
            style: TextStyle(color: kText1),
            decoration: _inputDec(hint: 'Ex: Vitória no campeonato'),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _salvar,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}
