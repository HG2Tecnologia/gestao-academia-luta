import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/widgets.dart';

enum _Periodo { tudo, semana, mes, personalizado }

class AlunoRankingScreen extends StatefulWidget {
  const AlunoRankingScreen({super.key});

  @override
  State<AlunoRankingScreen> createState() => _AlunoRankingScreenState();
}

class _AlunoRankingScreenState extends State<AlunoRankingScreen> {
  String? _meuId;
  bool _iniciando = true;

  List<_RankingTab> _abas = [
    const _RankingTab(label: 'Geral', tipo: 'academia', id: '', nomeCompleto: 'Academia'),
  ];

  // Filtro de período
  _Periodo _periodo = _Periodo.tudo;
  String? _dataInicio;
  String? _dataFim;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    var abas = <_RankingTab>[];
    String? meuId;

    try {
      final user = await AuthStorage.getUser();
      meuId = user?.id;

      final results = await Future.wait([
        _fetchTurmasDoAluno(),
        _fetchCustomRankings(),
      ]);

      final turmas = results[0];
      final customRankings = results[1];

      for (final turma in turmas.take(3)) {
        abas.add(_RankingTab(
          label: turma['nome'] as String? ?? 'Turma',
          tipo: 'turma',
          id: (turma['id'] ?? '') as String,
          nomeCompleto: '${turma['modalidadeNome'] ?? ''} — ${turma['nome'] ?? ''}',
        ));
      }

      final modalidadesVistas = <String>{};
      for (final turma in turmas) {
        final modId = turma['modalidadeId'] as String?;
        if (modId != null && modId.isNotEmpty && modalidadesVistas.add(modId)) {
          abas.add(_RankingTab(
            label: turma['modalidadeNome'] as String? ?? 'Modalidade',
            tipo: 'modalidade',
            id: modId,
            nomeCompleto: turma['modalidadeNome'] as String? ?? 'Modalidade',
          ));
        }
      }

      for (final r in customRankings) {
        abas.add(_RankingTab(
          label: r['nome'] as String? ?? 'Ranking',
          tipo: 'custom',
          id: (r['id'] ?? '') as String,
          nomeCompleto: r['nome'] as String? ?? 'Ranking',
        ));
      }
    } catch (_) {
      abas = [];
    }

    if (abas.isEmpty) {
      abas.add(const _RankingTab(label: 'Geral', tipo: 'academia', id: '', nomeCompleto: 'Academia'));
    }

    if (mounted) {
      setState(() {
        _meuId = meuId;
        _abas = abas;
        _iniciando = false;
      });
    }
  }

  Widget _periodoChip(String label, _Periodo p) {
    final selected = _periodo == p;
    return GestureDetector(
      onTap: () => _selecionarPeriodo(p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kPrimary.withOpacity(0.2) : kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? kPrimary : kBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? kPrimary : kText2,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _selecionarPeriodo(_Periodo p) async {
    final now = DateTime.now();
    if (p == _Periodo.personalizado) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(now.year + 1),
        initialDateRange: _dataInicio != null && _dataFim != null
            ? DateTimeRange(
                start: DateTime.parse(_dataInicio!),
                end: DateTime.parse(_dataFim!))
            : null,
        builder: (ctx, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(primary: kPrimary, surface: kSurface),
          ),
          child: child!,
        ),
      );
      if (range == null) return;
      setState(() {
        _periodo = _Periodo.personalizado;
        _dataInicio = _fmtDate(range.start);
        _dataFim = _fmtDate(range.end);
      });
      return;
    }

    setState(() {
      _periodo = p;
      switch (p) {
        case _Periodo.tudo:
          _dataInicio = null;
          _dataFim = null;
        case _Periodo.semana:
          final inicio = now.subtract(Duration(days: now.weekday - 1));
          _dataInicio = _fmtDate(DateTime(inicio.year, inicio.month, inicio.day));
          _dataFim = _fmtDate(now);
        case _Periodo.mes:
          _dataInicio = _fmtDate(DateTime(now.year, now.month, 1));
          _dataFim = _fmtDate(now);
        case _Periodo.personalizado:
          break;
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchTurmasDoAluno() async {
    try {
      final res = await dio.get('/api/turmas');
      final body = res.data as Map<String, dynamic>;
      final dados = body['dados'];
      final list = dados is List ? dados : (dados is Map ? (dados['itens'] as List? ?? []) : []);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCustomRankings() async {
    try {
      final res = await dio.get('/api/ranking/custom');
      final data = res.data;
      final list = data is List
          ? data.cast<Map<String, dynamic>>()
          : (data is Map ? ((data['dados'] ?? data['itens'] ?? []) as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[]);
      return list
          .where((r) => r['visivelParaAluno'] == true && r['ativo'] == true)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_iniciando) {
      return Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    return DefaultTabController(
      length: _abas.length,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                Expanded(
                  child: Text('Ranking',
                      style: TextStyle(color: kText1, fontSize: 26, fontWeight: FontWeight.w900)),
                ),
                IconButton(
                  onPressed: () => context.push('/aluno/ranking/conquistas'),
                  icon: const Icon(Icons.military_tech_rounded, color: Color(0xFFFFD700), size: 32),
                  tooltip: 'Minhas conquistas',
                ),
              ]),
            ),
            const SizedBox(height: 12),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: kPrimary,
              labelColor: kPrimary,
              unselectedLabelColor: kText2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: _abas.map((a) => Tab(text: a.label)).toList(),
            ),
            // Seletor de período
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _periodoChip('Tudo', _Periodo.tudo),
                  const SizedBox(width: 6),
                  _periodoChip('Esta semana', _Periodo.semana),
                  const SizedBox(width: 6),
                  _periodoChip('Este mês', _Periodo.mes),
                  const SizedBox(width: 6),
                  _periodoChip(
                    _periodo == _Periodo.personalizado && _dataInicio != null
                        ? '${DateFormat('dd/MM').format(DateTime.parse(_dataInicio!))} → ${_dataFim != null ? DateFormat('dd/MM').format(DateTime.parse(_dataFim!)) : '...'}'
                        : 'Personalizado',
                    _Periodo.personalizado,
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: _abas.map((a) => _RankingTabView(
                  aba: a,
                  meuId: _meuId,
                  dataInicio: _dataInicio,
                  dataFim: _dataFim,
                )).toList(),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Modelo de aba ────────────────────────────────────────────────────────────

class _RankingTab {
  final String label;
  final String tipo; // 'turma' | 'modalidade' | 'academia' | 'custom'
  final String id;
  final String nomeCompleto;

  const _RankingTab({
    required this.label,
    required this.tipo,
    required this.id,
    required this.nomeCompleto,
  });
}

// ─── Conteúdo de cada aba ────────────────────────────────────────────────────

class _RankingTabView extends StatefulWidget {
  final _RankingTab aba;
  final String? meuId;
  final String? dataInicio;
  final String? dataFim;

  const _RankingTabView({
    required this.aba,
    required this.meuId,
    this.dataInicio,
    this.dataFim,
  });

  @override
  State<_RankingTabView> createState() => _RankingTabViewState();
}

class _RankingTabViewState extends State<_RankingTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _RankingTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataInicio != widget.dataInicio || oldWidget.dataFim != widget.dataFim) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = false; });
    try {
      final aba = widget.aba;
      Response res;

      // Filtro de data só se aplica a turma/modalidade/academia — custom usa datas configuradas no servidor
      final params = <String, dynamic>{};
      if (aba.tipo != 'custom') {
        if (widget.dataInicio != null) params['dataInicio'] = widget.dataInicio;
        if (widget.dataFim != null) params['dataFim'] = widget.dataFim;
      }

      switch (aba.tipo) {
        case 'turma':
          res = await dio.get('/api/ranking/leaderboard/presencas/turma/${aba.id}',
              queryParameters: params.isEmpty ? null : params);
          break;
        case 'modalidade':
          res = await dio.get('/api/ranking/leaderboard/presencas/modalidade/${aba.id}',
              queryParameters: params.isEmpty ? null : params);
          break;
        case 'custom':
          res = await dio.get('/api/ranking/custom/${aba.id}/leaderboard');
          break;
        default:
          res = await dio.get('/api/ranking/leaderboard/academia',
              queryParameters: params.isEmpty ? null : params);
      }
      final body = res.data as Map<String, dynamic>;
      final dados = body['dados'] ?? body;
      final list = (dados is Map ? dados['items'] : null) ?? (dados is List ? dados : []);
      if (mounted) setState(() => _items = (list as List).cast<Map<String, dynamic>>());
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _ehEu(Map<String, dynamic> r) =>
      r['alunoId'] == widget.meuId || r['id'] == widget.meuId;

  String _nome(Map<String, dynamic> r) => r['nomeAluno'] ?? r['nome'] ?? '—';

  int _pontos(Map<String, dynamic> r) {
    if (widget.aba.tipo == 'custom') {
      return (r['totalPontos'] as num?)?.toInt() ?? 0;
    }
    return (r['totalPresencas'] as num?)?.toInt()
        ?? (r['xpTotal'] as num?)?.toInt()
        ?? (r['xpPeriodo'] as num?)?.toInt()
        ?? 0;
  }

  String _labelPontos() {
    if (widget.aba.tipo == 'custom') return 'pontos';
    return 'presenças';
  }

  int get _myPos {
    for (var i = 0; i < _items.length; i++) {
      if (_ehEu(_items[i])) return i + 1;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return Center(child: CircularProgressIndicator(color: kPrimary));
    if (_erro) return ErroConexao(onRetry: _load);
    if (_items.isEmpty) {
      return ListaVazia(
        icon: Icons.emoji_events_outlined,
        titulo: 'Ranking ainda não disponível',
        subtitulo: 'Registre presenças para aparecer aqui.',
      );
    }

    final pos = _myPos;
    final top3 = _items.take(3).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: kPrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Minha posição
          if (pos > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimary.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(Icons.person_pin_rounded, color: kPrimary, size: 20),
                const SizedBox(width: 8),
                Text('Você está em ${pos.ordinal()} lugar neste ranking',
                    style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),

          // Pódio top 3
          if (top3.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _Podium(
                top3: top3,
                meuId: widget.meuId,
                ehEu: _ehEu,
                pontos: _pontos,
                labelPontos: _labelPontos(),
              ),
            ),

          Text('CLASSIFICAÇÃO', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 10),

          // Lista completa
          ..._items.asMap().entries.map((e) {
            final r = e.value;
            final posItem = (r['posicao'] as num?)?.toInt() ?? (e.key + 1);
            final eu = _ehEu(r);
            final pts = _pontos(r);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: eu ? kPrimary.withOpacity(0.12) : kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: eu ? kPrimary.withOpacity(0.4) : kBorder),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 32,
                    child: Text('#$posItem',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: eu ? kPrimary : kText2,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: kPrimary.withOpacity(0.15),
                    child: Text(
                      _nome(r).isNotEmpty ? _nome(r)[0].toUpperCase() : '?',
                      style: TextStyle(color: kPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _nome(r) + (eu ? ' (você)' : ''),
                      style: TextStyle(
                          color: eu ? kPrimary : kText1,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$pts',
                        style: TextStyle(
                            color: eu ? kPrimary : kText1,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    Text(_labelPontos(), style: TextStyle(color: kText2, fontSize: 10)),
                  ]),
                ]),
              ),
            );
          }),

          // Pontos manuais detalhados no ranking custom
          if (widget.aba.tipo == 'custom') ...[
            const SizedBox(height: 8),
            Center(
              child: Text('Pontos = presenças × peso + pontos manuais × peso',
                  style: TextStyle(color: kText2.withOpacity(0.5), fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Pódio ───────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<Map<String, dynamic>> top3;
  final String? meuId;
  final bool Function(Map<String, dynamic>) ehEu;
  final int Function(Map<String, dynamic>) pontos;
  final String labelPontos;

  const _Podium({
    required this.top3,
    required this.meuId,
    required this.ehEu,
    required this.pontos,
    required this.labelPontos,
  });

  String _nome(Map<String, dynamic> r) => r['nomeAluno'] ?? r['nome'] ?? '—';

  @override
  Widget build(BuildContext context) {
    final p1 = top3.isNotEmpty ? top3[0] : null;
    final p2 = top3.length > 1 ? top3[1] : null;
    final p3 = top3.length > 2 ? top3[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: p2 != null ? _item(p2, 2, 80, const Color(0xFFC0C0C0)) : const SizedBox()),
        const SizedBox(width: 8),
        Expanded(child: p1 != null ? _item(p1, 1, 110, const Color(0xFFFFD700)) : const SizedBox()),
        const SizedBox(width: 8),
        Expanded(child: p3 != null ? _item(p3, 3, 60, const Color(0xFFCD7F32)) : const SizedBox()),
      ],
    );
  }

  Widget _item(Map<String, dynamic> r, int pos, double h, Color medalColor) {
    final eu = ehEu(r);
    final nome = _nome(r);
    final primeiroNome = nome.split(' ').first;
    final pts = pontos(r);

    return Column(children: [
      if (pos == 1)
        Icon(Icons.emoji_events_rounded, color: medalColor, size: 28)
      else
        const SizedBox(height: 28),
      const SizedBox(height: 4),
      Stack(children: [
        CircleAvatar(
          radius: pos == 1 ? 30 : 24,
          backgroundColor: kPrimary.withOpacity(0.2),
          child: Text(
            nome.isNotEmpty ? nome[0].toUpperCase() : '?',
            style: TextStyle(
                color: eu ? kPrimary : kText1,
                fontSize: pos == 1 ? 22 : 18,
                fontWeight: FontWeight.w900),
          ),
        ),
        if (eu)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: kBg, width: 2),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 6),
      Text(primeiroNome,
          style: TextStyle(
              color: eu ? kPrimary : kText1,
              fontSize: pos == 1 ? 13 : 12,
              fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center),
      Text('$pts $labelPontos', style: TextStyle(color: kText2, fontSize: 11)),
      const SizedBox(height: 4),
      Container(
        height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [medalColor.withOpacity(0.3), medalColor.withOpacity(0.1)],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          border: Border.all(color: medalColor.withOpacity(0.4)),
        ),
        child: Center(
          child: Text('$pos', style: TextStyle(color: medalColor, fontSize: 28, fontWeight: FontWeight.w900)),
        ),
      ),
    ]);
  }
}

extension on int {
  String ordinal() {
    if (this == 1) return '1º';
    if (this == 2) return '2º';
    if (this == 3) return '3º';
    return '${this}º';
  }
}
