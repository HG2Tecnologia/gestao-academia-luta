import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/widgets.dart';

class AlunoGraduacoesScreen extends StatefulWidget {
  const AlunoGraduacoesScreen({super.key});

  @override
  State<AlunoGraduacoesScreen> createState() => _AlunoGraduacoesScreenState();
}

class _AlunoGraduacoesScreenState extends State<AlunoGraduacoesScreen> {
  List<Map<String, dynamic>> _graduacoes = [];
  Map<String, dynamic>? _faixaAtual;
  bool _loading = true;
  bool _erro = false;
  String? _histModFiltro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = false; });
    try {
      final user = await AuthStorage.getUser();
      if (user == null) return;
      final res = await dio.get('/api/graduacoes', queryParameters: {'alunoId': user.id});
      final dados = res.data['dados'];
      final list = (dados is List ? dados : []).cast<Map<String, dynamic>>();
      // Sort by date descending
      list.sort((a, b) {
        final da = a['dataExame']?.toString() ?? '';
        final db = b['dataExame']?.toString() ?? '';
        return db.compareTo(da);
      });
      // Find current belt (most recent approved)
      final aprovadas = list.where((g) => g['aprovado'] == true).toList();
      if (mounted) setState(() {
        _graduacoes = list;
        _faixaAtual = aprovadas.isNotEmpty ? aprovadas.first : null;
      });
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _effectiveMaxGraus(Map<String, dynamic> g) {
    final mr = (g['faixaMaxGraus'] as num?)?.toInt() ?? 0;
    final gr = (g['grau'] as num?)?.toInt() ?? 0;
    return mr > 0 ? mr : (gr > 0 ? gr : 4);
  }

  List<Widget> _buildHistoricoByMod([String? modFiltro]) {
    final source = modFiltro == null
        ? _graduacoes
        : _graduacoes.where((g) => g['nomeModalidade']?.toString() == modFiltro).toList();

    // Group by modality preserving insertion order (already sorted by date desc)
    final Map<String, List<Map<String, dynamic>>> byMod = {};
    for (final g in source) {
      final mod = g['nomeModalidade']?.toString() ?? 'Sem modalidade';
      byMod.putIfAbsent(mod, () => []).add(g);
    }

    return byMod.entries.map((entry) {
      final items = entry.value;
      return SliverMainAxisGroup(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              entry.key.toUpperCase(),
              style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final g = items[i];
              final aprovado = g['aprovado'] == true;
              final cor = _hexCor(g['corFaixa'] as String?);
              final isFirst = i == 0;
              final isLast = i == items.length - 1;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isFirst)
                            Center(child: Container(width: 2, height: 10, color: kBorder)),
                          Container(
                            width: 14, height: 14,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: aprovado ? cor : kBorder,
                              border: Border.all(color: aprovado ? cor.withOpacity(0.5) : kBorder, width: 2),
                            ),
                          ),
                          if (!isLast)
                            Center(child: Container(width: 2, height: 24, color: kBorder)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: aprovado && isFirst ? cor.withOpacity(0.4) : kBorder),
                          ),
                          child: Row(children: [
                            BeltBadge(
                              cor: cor,
                              corBarra: _hexCor(g['corBarraFaixa'] as String? ?? '#000000'),
                              temGraus: g['faixaTemGraus'] == true || ((g['grau'] as num?)?.toInt() ?? 0) > 0,
                              grau: (g['grau'] as num?)?.toInt() ?? 0,
                              maxGraus: _effectiveMaxGraus(g),
                              height: 14,
                              minWidth: 32,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Flexible(child: Text(g['nomeFaixa'] ?? '', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                                  if (((g['grau'] as num?)?.toInt() ?? 0) > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(color: kPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                      child: Text('${(g['grau'] as num?)?.toInt()}° grau', style: TextStyle(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ]),
                              ]),
                            ),
                            Flexible(
                              flex: 0,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(_fmtData(g['dataExame']?.toString()), style: TextStyle(color: kText2, fontSize: 12)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: (aprovado ? kSuccess : kDanger).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text(aprovado ? 'Aprovado' : 'Reprovado', style: TextStyle(color: aprovado ? kSuccess : kDanger, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            childCount: items.length,
          ),
        ),
      ]);
    }).toList();
  }

  Color _hexCor(String? hex) {
    if (hex == null || hex.isEmpty) return kPrimary;
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); } catch (_) { return kPrimary; }
  }

String _fmtData(String? s) {
    if (s == null) return '';
    try {
      final parts = s.split('-');
      if (parts.length < 3) return s;
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) { return s; }
  }

  AppBar _appBar() => AppBar(
    backgroundColor: kSurface,
    foregroundColor: kText1,
    elevation: 0,
    title: const Text('Histórico de Graduações', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    actions: [IconButton(onPressed: openAppDrawer, icon: Icon(Icons.menu_rounded, color: kText1))],
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(backgroundColor: kBg, appBar: _appBar(), body: Center(child: CircularProgressIndicator(color: kPrimary)));
    if (_erro) return Scaffold(backgroundColor: kBg, appBar: _appBar(), body: SafeArea(child: ErroConexao(onRetry: _load)));

    final faixaAtual = _faixaAtual;
    final corFaixa = _hexCor(faixaAtual?['corFaixa'] as String?);
    final corBarra = _hexCor(faixaAtual?['corBarraFaixa'] as String? ?? '#000000');
    final temGraus = faixaAtual?['faixaTemGraus'] == true || ((faixaAtual?['grau'] as num?)?.toInt() ?? 0) > 0;
    final grauAtual = (faixaAtual?['grau'] as num?)?.toInt() ?? 0;
    final maxGrausRaw = (faixaAtual?['faixaMaxGraus'] as num?)?.toInt() ?? 0;
    final maxGraus = maxGrausRaw > 0 ? maxGrausRaw : (grauAtual > 0 ? grauAtual : 4);
    final accentLight = Color.lerp(corFaixa, Colors.white, 0.3)!;
    final aprovadas = _graduacoes.where((g) => g['aprovado'] == true).toList();

    // Modality filter
    final mods = _graduacoes
        .map((g) => g['nomeModalidade']?.toString() ?? '')
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()..sort();
    final multiMod = mods.length > 1;
    final modSelected = multiMod && mods.contains(_histModFiltro) ? _histModFiltro : null;

    return Scaffold(
      backgroundColor: kBg,
      appBar: _appBar(),
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Graduações', style: TextStyle(color: kText1, fontSize: 26, fontWeight: FontWeight.w900)),
                      Text('Seu histórico de faixas', style: TextStyle(color: kText2, fontSize: 13)),
                    ],
                  ),
                ),
              ),

              // ── Faixa atual ───────────────────────────
              if (faixaAtual != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [corFaixa.withOpacity(0.25), corFaixa.withOpacity(0.08)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: corFaixa.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          // Belt visual
                          BeltBadge(
                            cor: corFaixa,
                            corBarra: corBarra,
                            temGraus: temGraus,
                            grau: grauAtual,
                            maxGraus: maxGraus,
                            height: 22,
                            minWidth: 52,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Faixa atual', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w600)),
                                Text(faixaAtual['nomeFaixa'] ?? '', style: TextStyle(color: accentLight, fontSize: 20, fontWeight: FontWeight.w900)),
                                Row(children: [
                                  if (faixaAtual['nomeModalidade'] != null)
                                    Text(faixaAtual['nomeModalidade'], style: TextStyle(color: kText2, fontSize: 12)),
                                  if (temGraus && grauAtual > 0) ...[
                                    Text(' · ', style: TextStyle(color: kText2, fontSize: 12)),
                                    Text('$grauAtual° grau', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                  ],
                                ]),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${aprovadas.length}', style: TextStyle(color: corFaixa, fontSize: 28, fontWeight: FontWeight.w900)),
                              Text('gradua${aprovadas.length == 1 ? 'ção' : 'ções'}', style: TextStyle(color: kText2, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Dropdown de modalidade ────────────────
              if (multiMod)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: DropdownButtonFormField<String>(
                      value: mods.contains(_histModFiltro) ? _histModFiltro : mods.first,
                      onChanged: (v) { if (v != null) setState(() => _histModFiltro = v); },
                      dropdownColor: kSurface,
                      style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: kBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: kText2),
                      items: mods.map((m) => DropdownMenuItem<String>(
                        value: m,
                        child: Text(m, overflow: TextOverflow.ellipsis, style: TextStyle(color: kText1, fontSize: 13)),
                      )).toList(),
                    ),
                  ),
                ),

              // ── Timeline ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text('HISTÓRICO', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                ),
              ),

              if (_graduacoes.isEmpty)
                SliverToBoxAdapter(
                  child: ListaVazia(
                    icon: Icons.military_tech_outlined,
                    titulo: 'Nenhuma graduação registrada',
                    subtitulo: 'Seu histórico de faixas aparecerá aqui.',
                  ),
                )
              else ..._buildHistoricoByMod(modSelected),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
