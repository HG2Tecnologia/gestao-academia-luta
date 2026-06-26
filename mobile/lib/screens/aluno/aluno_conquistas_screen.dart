import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';

class AlunoConquistasScreen extends StatefulWidget {
  const AlunoConquistasScreen({super.key});

  @override
  State<AlunoConquistasScreen> createState() => _AlunoConquistasScreenState();
}

class _AlunoConquistasScreenState extends State<AlunoConquistasScreen> {
  Map<String, dynamic>? _perfil;
  List<Map<String, dynamic>> _conquistas = [];
  bool _loading = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _erro = false; });
    try {
      final user = await AuthStorage.getUser();
      if (user == null) { if (mounted) setState(() { _loading = false; _erro = true; }); return; }

      final results = await Future.wait([
        dio.get('/api/ranking/perfil/${user.id}'),
        dio.get('/api/ranking/conquistas/${user.id}'),
      ]);

      final perfilData = results[0].data as Map<String, dynamic>;
      final conquistasData = results[1].data as Map<String, dynamic>;

      // Marcar conquistas novas como vistas
      final naoVistas = (conquistasData['dados'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .where((c) => c['desbloqueada'] == true && c['vistaPeloAluno'] == false)
          .map((c) => c['id'] as String)
          .toList();
      if (naoVistas.isNotEmpty) {
        try {
          await dio.post('/api/ranking/conquistas/marcar-vistas', data: {'ids': naoVistas});
        } catch (_) {}
      }

      if (mounted) setState(() {
        _perfil = perfilData['dados'] as Map<String, dynamic>?;
        _conquistas = (conquistasData['dados'] as List? ?? []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _erro = true; });
    }
  }

  AppBar _appBar() => AppBar(
    backgroundColor: kSurface,
    foregroundColor: kText1,
    elevation: 0,
    title: const Text('Conquistas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    actions: [IconButton(onPressed: openAppDrawer, icon: Icon(Icons.menu_rounded, color: kText1))],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _appBar(),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: kPrimary))
            : _erro
                ? _buildErro()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: kPrimary,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverToBoxAdapter(child: _buildXpBar()),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Text('Conquistas', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        if (_conquistas.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text('Nenhuma conquista ainda.', style: TextStyle(color: kText2), textAlign: TextAlign.center),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _ConquistaCard(c: _conquistas[i]),
                                childCount: _conquistas.length,
                              ),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErro() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline, color: kDanger, size: 40),
      const SizedBox(height: 12),
      Text('Erro ao carregar', style: TextStyle(color: kText2)),
      const SizedBox(height: 16),
      TextButton(onPressed: _load, child: Text('Tentar novamente', style: TextStyle(color: kPrimary))),
    ]),
  );

  Widget _buildHeader() {
    final p = _perfil ?? {};
    final nivel = p['nivel'] as String? ?? '—';
    final posGlobal = p['posicaoGlobal'] as int? ?? 0;
    final sequencia = p['sequenciaAtual'] as int? ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Meu Perfil', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        Row(children: [
          _statBox(Icons.emoji_events_rounded, kWarning, 'Nível', nivel),
          const SizedBox(width: 12),
          _statBox(Icons.leaderboard_rounded, kPrimary, 'Ranking', '#$posGlobal'),
          const SizedBox(width: 12),
          _statBox(Icons.local_fire_department_rounded, kDanger, 'Sequência', '${sequencia}d'),
        ]),
      ]),
    );
  }

  Widget _statBox(IconData icon, Color color, String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: kText1, fontWeight: FontWeight.w800, fontSize: 16)),
        Text(label, style: TextStyle(color: kText2, fontSize: 10)),
      ]),
    ),
  );

  Widget _buildXpBar() {
    final p = _perfil ?? {};
    final xpTotal = p['xpTotal'] as int? ?? 0;
    final xpMensal = p['xpMensal'] as int? ?? 0;
    final xpProximo = p['xpParaProximoNivel'] as int? ?? 1;
    final progresso = xpProximo > 0 ? (xpTotal % xpProximo) / xpProximo : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('XP Total', style: TextStyle(color: kText2, fontSize: 12)),
          Text('$xpTotal XP', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progresso.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: kBorder,
            valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Este mês: $xpMensal XP', style: TextStyle(color: kText2, fontSize: 11)),
          Text('Próx. nível: $xpProximo XP', style: TextStyle(color: kText2, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _ConquistaCard extends StatelessWidget {
  final Map<String, dynamic> c;
  const _ConquistaCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final desbloqueada = c['desbloqueada'] == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: desbloqueada ? kSurface : kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: desbloqueada ? kPrimary.withOpacity(0.4) : kBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: desbloqueada ? kPrimary.withOpacity(0.15) : kBorder.withOpacity(0.3),
            ),
            child: Icon(
              desbloqueada ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
              color: desbloqueada ? kPrimary : kText2,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            c['nome'] as String? ?? '',
            style: TextStyle(
              color: desbloqueada ? kText1 : kText2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (desbloqueada && (c['pontosXpBonus'] as int? ?? 0) > 0) ...[
            const SizedBox(height: 4),
            Text('+${c['pontosXpBonus']} XP', style: TextStyle(color: kSuccess, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}
