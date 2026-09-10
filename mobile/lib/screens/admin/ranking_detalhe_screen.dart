import 'package:flutter/material.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/firestore_service.dart';
import 'rankings_screen.dart';

class AdminRankingDetalheScreen extends StatefulWidget {
  final String rankingId;
  final Map<String, dynamic>? rankingExtra;

  const AdminRankingDetalheScreen({
    super.key,
    required this.rankingId,
    this.rankingExtra,
  });

  @override
  State<AdminRankingDetalheScreen> createState() =>
      _AdminRankingDetalheScreenState();
}

class _AdminRankingDetalheScreenState extends State<AdminRankingDetalheScreen>
    with SingleTickerProviderStateMixin {
  AppLocalizations get _l => context.l10n;
  late TabController _tabs;

  Map<String, dynamic>? _ranking;
  List<Map<String, dynamic>> _items = [];
  bool _loadingLeaderboard = true;

  List<Map<String, dynamic>> _lancamentos = [];
  bool _loadingLancamentos = true;

  String? _academiaId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _ranking = widget.rankingExtra;
    _loadAcademiaId().then((_) => _loadAll());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAcademiaId() async {
    final user = await AuthStorage.getUser();
    _academiaId = user?.academiaId ?? '';
  }

  Future<void> _loadAll() async {
    if (_academiaId == null || _academiaId!.isEmpty) return;
    await Future.wait([_loadLeaderboard(), _loadLancamentos(), _loadRanking()]);
  }

  Future<void> _loadRanking() async {
    if (_academiaId == null || _academiaId!.isEmpty) return;
    try {
      final list = await firestoreService.getRankingsCustom(_academiaId!);
      final found = list
          .cast<Map<String, dynamic>>()
          .where((r) => r['id']?.toString() == widget.rankingId)
          .firstOrNull;
      if (mounted && found != null) setState(() => _ranking = found);
    } catch (_) {}
  }

  Future<void> _loadLeaderboard() async {
    if (_academiaId == null || _academiaId!.isEmpty) return;
    setState(() => _loadingLeaderboard = true);
    try {
      // Compute leaderboard from lancamentos grouped by alunoId
      final allLancamentos = await firestoreService.getLancamentosPonto(
        _academiaId!,
        widget.rankingId,
      );
      final lancamentos = allLancamentos.cast<Map<String, dynamic>>();

      // Group by aluno_id, sum pontos
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final l in lancamentos) {
        final alunoId =
            l['aluno_id']?.toString() ?? l['alunoId']?.toString() ?? '';
        final nomeAluno =
            l['nome_aluno']?.toString() ?? l['nomeAluno']?.toString() ?? '';
        final pts = (l['pontos'] as num?)?.toInt() ?? 0;
        if (alunoId.isEmpty) continue;
        if (!grouped.containsKey(alunoId)) {
          grouped[alunoId] = {
            'alunoId': alunoId,
            'nomeAluno': nomeAluno,
            'totalPontos': 0,
            'pontosPresencas': 0,
            'pontosManuais': 0,
          };
        }
        grouped[alunoId]!['totalPontos'] =
            (grouped[alunoId]!['totalPontos'] as int) + pts;
        final tipo = l['tipo']?.toString() ?? 'manual';
        if (tipo == 'presenca') {
          grouped[alunoId]!['pontosPresencas'] =
              (grouped[alunoId]!['pontosPresencas'] as int) + pts;
        } else {
          grouped[alunoId]!['pontosManuais'] =
              (grouped[alunoId]!['pontosManuais'] as int) + pts;
        }
      }

      final sorted = grouped.values.toList()
        ..sort(
          (a, b) =>
              (b['totalPontos'] as int).compareTo(a['totalPontos'] as int),
        );
      for (var i = 0; i < sorted.length; i++) {
        sorted[i]['posicao'] = i + 1;
      }

      if (mounted) setState(() => _items = sorted);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingLeaderboard = false);
    }
  }

  Future<void> _loadLancamentos() async {
    if (_academiaId == null || _academiaId!.isEmpty) return;
    setState(() => _loadingLancamentos = true);
    try {
      final list = await firestoreService.getLancamentosPonto(
        _academiaId!,
        widget.rankingId,
      );
      final lancamentos = list.cast<Map<String, dynamic>>();
      lancamentos.sort((a, b) {
        final da = a['data'] ?? a['created_at'] ?? '';
        final db = b['data'] ?? b['created_at'] ?? '';
        return db.toString().compareTo(da.toString());
      });
      if (mounted) setState(() => _lancamentos = lancamentos);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingLancamentos = false);
    }
  }

  void _abrirLancarPontos() async {
    if (_academiaId == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LancarPontosSheet(
        rankingId: widget.rankingId,
        academiaId: _academiaId!,
        onSalvo: _loadAll,
      ),
    );
  }

  void _editarRanking() async {
    if (_ranking == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          CriarRankingSheet(ranking: _ranking, onSalvo: _loadRanking),
    );
  }

  Future<void> _removerLancamento(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.rkRemoveEntryTitle,
          style: TextStyle(color: context.c.onSurface),
        ),
        content: Text(
          _l.rkRemoveEntryBody,
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _l.commonRemove,
              style: TextStyle(color: context.sem.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.deleteLancamentoPonto(_academiaId!, id);
      _loadAll();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final nome = _ranking?['nome'] ?? 'Ranking';
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        elevation: 0,
        title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editarRanking,
            tooltip: _l.commonEdit,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: context.c.primary,
          labelColor: context.c.primary,
          unselectedLabelColor: context.c.onSurfaceVariant,
          tabs: [
            Tab(text: 'Leaderboard'),
            Tab(text: _l.rkEntries),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirLancarPontos,
        backgroundColor: context.c.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _l.rkAddPoints,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildLeaderboard(), _buildLancamentos()],
      ),
    );
  }

  Widget _buildLeaderboard() {
    if (_loadingLeaderboard)
      return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return Center(
        child: Text(
          _l.rkNoParticipantsYet,
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          final pos = item['posicao'] as int? ?? i + 1;
          final total = item['totalPontos'] as int? ?? 0;
          final presencas = item['pontosPresencas'] as int? ?? 0;
          final manuais = item['pontosManuais'] as int? ?? 0;

          final medalColor = pos == 1
              ? const Color(0xFFFFD700)
              : pos == 2
              ? const Color(0xFFC0C0C0)
              : pos == 3
              ? const Color(0xFFCD7F32)
              : context.c.onSurfaceVariant;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.c.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pos <= 3
                    ? medalColor.withOpacity(0.4)
                    : context.c.outline,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '$pos°',
                    style: TextStyle(
                      color: medalColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: context.c.primary.withOpacity(0.15),
                  child: Text(
                    (item['nomeAluno'] as String? ?? '?')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: TextStyle(
                      color: context.c.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nomeAluno'] ?? '',
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          if (presencas > 0)
                            _subTag(
                              _l.rkPtsAttendance(presencas),
                              context.sem.success,
                            ),
                          if (presencas > 0 && manuais > 0)
                            const SizedBox(width: 4),
                          if (manuais > 0)
                            _subTag(
                              _l.rkPtsManual(manuais),
                              context.sem.warning,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$total',
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'pontos',
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _subTag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10)),
  );

  Widget _buildLancamentos() {
    if (_loadingLancamentos)
      return const Center(child: CircularProgressIndicator());
    if (_lancamentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stars_outlined,
              size: 48,
              color: context.c.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 10),
            Text(
              _l.rkNoPointsYet,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              _l.rkUseButtonBelow,
              style: TextStyle(
                color: context.c.onSurfaceVariant.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadLancamentos,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _lancamentos.length,
        itemBuilder: (_, i) {
          final l = _lancamentos[i];
          final nomeAluno = l['nome_aluno'] ?? l['nomeAluno'] ?? '';
          final descricao = l['descricao'] ?? '';
          final nomeReg =
              l['nome_registrado_por'] ?? l['nomeRegistradoPor'] ?? '';
          final data = l['data'] ?? l['created_at'] ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.c.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.c.outline),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.c.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${l['pontos']}',
                    style: TextStyle(
                      color: context.c.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomeAluno,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        descricao,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _l.rkByOn(nomeReg, data),
                        style: TextStyle(
                          color: context.c.onSurfaceVariant.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: context.sem.danger,
                    size: 20,
                  ),
                  onPressed: () =>
                      _removerLancamento(l['id']?.toString() ?? ''),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Sheet de lançamento de pontos ──────────────────────────────────────────

class _LancarPontosSheet extends StatefulWidget {
  final String rankingId;
  final String academiaId;
  final VoidCallback onSalvo;

  const _LancarPontosSheet({
    required this.rankingId,
    required this.academiaId,
    required this.onSalvo,
  });

  @override
  State<_LancarPontosSheet> createState() => _LancarPontosSheetState();
}

class _LancarPontosSheetState extends State<_LancarPontosSheet> {
  AppLocalizations get _l => context.l10n;
  final _formKey = GlobalKey<FormState>();
  final _pontos = TextEditingController();
  final _descricao = TextEditingController();

  List<Map<String, dynamic>> _alunos = [];
  String? _alunoId;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  @override
  void dispose() {
    _pontos.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _carregarAlunos() async {
    try {
      final list = await firestoreService.getAlunos(
        widget.academiaId,
        ativosOnly: true,
      );
      if (mounted) setState(() => _alunos = list.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_alunoId == null) {
      setState(() => _erro = 'Selecione um aluno.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final aluno = _alunos.firstWhere(
        (a) => a['id']?.toString() == _alunoId,
        orElse: () => {},
      );
      final nomeAluno = aluno['nome']?.toString() ?? '';
      final user = await AuthStorage.getUser();

      await firestoreService.addLancamentoPonto(widget.academiaId, {
        'ranking_id': widget.rankingId,
        'aluno_id': _alunoId,
        'nome_aluno': nomeAluno,
        'pontos': int.tryParse(_pontos.text) ?? 0,
        'descricao': _descricao.text.trim(),
        'tipo': 'manual',
        'registrado_por': user?.id ?? '',
        'nome_registrado_por': user?.nome ?? '',
        'data': DateTime.now().toUtc().toIso8601String(),
      });
      widget.onSalvo();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erro = _l.commonGenericError);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _l.rkAddPoints,
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.c.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Seletor de aluno
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: context.c.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.c.outline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _alunoId,
                    dropdownColor: context.c.surfaceContainer,
                    hint: Text(
                      'Selecionar aluno *',
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    isExpanded: true,
                    items: _alunos
                        .map(
                          (a) => DropdownMenuItem<String?>(
                            value: a['id']?.toString(),
                            child: Text(
                              a['nome'] ?? '',
                              style: TextStyle(color: context.c.onSurface),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _alunoId = v),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _pontos,
                keyboardType: TextInputType.number,
                style: TextStyle(color: context.c.onSurface),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return _l.rkEnterPoints;
                  final n = int.tryParse(v);
                  if (n == null || n == 0) return _l.rkMustNotBeZero;
                  return null;
                },
                decoration: _dec(_l.rkPointsHint),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _descricao,
                style: TextStyle(color: context.c.onSurface),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? _l.rkDescribeReason
                    : null,
                decoration: _dec(_l.rkReasonHint2),
              ),

              if (_erro != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.sem.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _erro!,
                    style: TextStyle(color: context.sem.danger, fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.c.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _l.rkConfirmEntry,
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
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
    filled: true,
    fillColor: context.c.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.c.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.c.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.c.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.sem.danger),
    ),
  );
}
