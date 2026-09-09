import 'package:flutter/material.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';
import '../../core/frequencia_treino.dart';
import '../../core/widgets.dart';

enum _Filtro { total, presencas, faltas }

class AlunoPresencasScreen extends StatefulWidget {
  /// 'presencas' | 'faltas' | 'total' — de onde veio o toque na Home.
  final String? filtroInicial;

  const AlunoPresencasScreen({super.key, this.filtroInicial});

  @override
  State<AlunoPresencasScreen> createState() => _AlunoPresencasScreenState();
}

class _AlunoPresencasScreenState extends State<AlunoPresencasScreen> {
  List<Map<String, dynamic>> _presencas = [];
  // Sessões esperadas sem presença registrada.
  List<Map<String, dynamic>> _faltas = [];
  int _totalTreinos = 0;
  bool _loading = true;
  bool _erro = false;
  // Inicializado inline (não `late`) para sobreviver a hot reload.
  _Filtro _filtro = _Filtro.total;

  @override
  void initState() {
    super.initState();
    _filtro = switch (widget.filtroInicial) {
      'presencas' => _Filtro.presencas,
      'faltas' => _Filtro.faltas,
      _ => _Filtro.total,
    };
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await AuthStorage.getUser();
      if (user == null) {
        if (mounted) {
          setState(() {
            _erro = true;
            _loading = false;
          });
        }
        return;
      }
      final academiaId = user.academiaId!;

      final results = await Future.wait([
        firestoreService.getPresencas(academiaId, alunoId: user.id),
        firestoreService.getTurmas(academiaId),
        firestoreService.getMatriculas(
          academiaId,
          alunoId: user.id,
          ativasOnly: true,
        ),
        firestoreService.getMeusHorarios(academiaId, user.id),
      ]);

      final presencas = (results[0] as List).cast<Map<String, dynamic>>();
      final turmas = (results[1] as List).cast<Map<String, dynamic>>();
      final matriculas = (results[2] as List).cast<Map<String, dynamic>>();
      final horarios = (results[3] as List).cast<Map<String, dynamic>>();

      final turmaNome = {
        for (final t in turmas)
          t['id'].toString(): (t['nome']?.toString() ?? ''),
      };

      final resumo = calcularFrequencia(
        presencas: presencas,
        matriculas: matriculas,
        horarios: horarios,
        turmaNome: turmaNome,
      );

      if (mounted) {
        setState(() {
          _presencas = resumo.presencas;
          _faltas = resumo.faltas;
          _totalTreinos = resumo.totalTreinos;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime? _parseDate(String? s) {
    if (s == null) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  String _fmtDate(String? s) {
    final dt = _parseDate(s);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _mesAno(DateTime dt) {
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${meses[dt.month - 1]} ${dt.year}';
  }

  List<Map<String, dynamic>> get _itensFiltrados {
    final lista = switch (_filtro) {
      _Filtro.presencas => [..._presencas],
      _Filtro.faltas => [..._faltas],
      _Filtro.total => [..._presencas, ..._faltas],
    };
    lista.sort((a, b) {
      final da = _parseDate(a['data']?.toString()) ?? DateTime(1900);
      final db = _parseDate(b['data']?.toString()) ?? DateTime(1900);
      return db.compareTo(da);
    });
    return lista;
  }

  Map<String, List<Map<String, dynamic>>> _grouped(
    List<Map<String, dynamic>> itens,
  ) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final p in itens) {
      final dt = _parseDate(p['data']?.toString());
      final key = dt != null
          ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
          : 'outros';
      map.putIfAbsent(key, () => []).add(p);
    }
    final sorted = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sorted);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }
    if (_erro && _presencas.isEmpty && _faltas.isEmpty) {
      return Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: ErroConexao(
            onRetry: () {
              setState(() {
                _loading = true;
                _erro = false;
              });
              _load();
            },
          ),
        ),
      );
    }

    final itens = _itensFiltrados;
    final groups = _grouped(itens).entries.toList();

    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: kText1,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Presenças',
                            style: TextStyle(
                              color: kText1,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seu histórico de treinos',
                        style: TextStyle(color: kText2, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Cards de estatística / filtro ─────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      _statCard(
                        valor: _totalTreinos,
                        label: 'Total de treinos',
                        cor: kPrimary,
                        icone: Icons.fitness_center_rounded,
                        filtro: _Filtro.total,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        valor: _presencas.length,
                        label: 'Presenças',
                        cor: kSuccess,
                        icone: Icons.check_circle_rounded,
                        filtro: _Filtro.presencas,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        valor: _faltas.length,
                        label: 'Faltas',
                        cor: kDanger,
                        icone: Icons.cancel_rounded,
                        filtro: _Filtro.faltas,
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    switch (_filtro) {
                      _Filtro.presencas => 'DIAS COM PRESENÇA',
                      _Filtro.faltas => 'DIAS SEM PRESENÇA',
                      _Filtro.total => 'HISTÓRICO',
                    },
                    style: TextStyle(
                      color: kText2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate((_, gi) {
                  final entry = groups[gi];
                  final items = entry.value;
                  final firstDate = _parseDate(items.first['data']?.toString());
                  final label = firstDate != null
                      ? _mesAno(firstDate)
                      : entry.key;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Row(
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: kPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${items.length}',
                                style: TextStyle(
                                  color: kPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...items.map(_itemTile),
                      if (gi < groups.length - 1) const SizedBox(height: 8),
                    ],
                  );
                }, childCount: groups.length),
              ),

              if (itens.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(
                            _filtro == _Filtro.faltas
                                ? Icons.emoji_events_rounded
                                : Icons.sports_martial_arts_rounded,
                            color: kBorder,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            switch (_filtro) {
                              _Filtro.faltas =>
                                'Nenhuma falta registrada. Mandou bem!',
                              _Filtro.presencas =>
                                'Nenhuma presença registrada ainda',
                              _Filtro.total => 'Nada por aqui ainda',
                            },
                            style: TextStyle(color: kText2, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemTile(Map<String, dynamic> p) {
    final falta = p['tipo'] == 'falta';
    final cor = falta ? kDanger : kSuccess;
    final hora = (p['horaCheckin'] as String?);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                falta ? Icons.close_rounded : Icons.check_rounded,
                color: cor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['nomeTurma']?.toString().isNotEmpty == true
                        ? p['nomeTurma'].toString()
                        : (p['turma']?.toString() ?? '—'),
                    style: TextStyle(
                      color: kText1,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    falta
                        ? 'Falta'
                        : (hora != null && hora.length >= 5
                              ? hora.substring(0, 5)
                              : 'Presente'),
                    style: TextStyle(
                      color: falta ? kDanger : kText2,
                      fontSize: 12,
                      fontWeight: falta ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _fmtDate(p['data']?.toString()),
              style: TextStyle(color: kText2, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required int valor,
    required String label,
    required Color cor,
    required IconData icone,
    required _Filtro filtro,
  }) {
    final selecionado = _filtro == filtro;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filtro = filtro),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: selecionado ? 0.20 : 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selecionado ? cor : cor.withValues(alpha: 0.30),
              width: selecionado ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icone, color: cor, size: 20),
                  const Spacer(),
                  Text(
                    '$valor',
                    style: TextStyle(
                      color: cor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: kText1,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
