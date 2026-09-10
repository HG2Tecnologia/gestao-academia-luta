import 'package:flutter/material.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../core/firestore_service.dart';

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
    if (mounted)
      setState(() {
        _loading = true;
        _erro = false;
      });
    try {
      final user = await AuthStorage.getUser();
      if (user == null) {
        if (mounted)
          setState(() {
            _loading = false;
            _erro = true;
          });
        return;
      }
      final academiaId = user.academiaId!;

      final results = await Future.wait([
        firestoreService.getPerfilRanking(academiaId, user.id),
        firestoreService.getConquistasAluno(academiaId, user.id),
      ]);

      final perfilData = results[0] as Map<String, dynamic>?;
      final conquistasList = results[1] as List<Map<String, dynamic>>;

      // Marcar conquistas novas como vistas
      final naoVistas = conquistasList
          .where(
            (c) => c['desbloqueada'] == true && c['vista_pelo_aluno'] == false,
          )
          .toList();
      if (naoVistas.isNotEmpty) {
        try {
          await firestoreService.marcarConquistasVistas(academiaId, user.id);
        } catch (_) {}
      }

      if (mounted)
        setState(() {
          _perfil = perfilData;
          _conquistas = conquistasList;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _erro = true;
        });
    }
  }

  AppBar _appBar() => AppBar(
    backgroundColor: context.c.surfaceContainer,
    foregroundColor: context.c.onSurface,
    elevation: 0,
    title: Text(
      context.l10n.apAchievements,
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: _appBar(),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: context.c.primary))
            : _erro
            ? _buildErro()
            : RefreshIndicator(
                onRefresh: _load,
                color: context.c.primary,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildXpBar()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          context.l10n.apAchievements,
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (_conquistas.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            context.l10n.apNoAchievements,
                            style: TextStyle(color: context.c.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
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
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
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
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: context.sem.danger, size: 40),
        const SizedBox(height: 12),
        Text(
          context.l10n.ctLoadError,
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _load,
          child: Text(
            context.l10n.commonRetry,
            style: TextStyle(color: context.c.primary),
          ),
        ),
      ],
    ),
  );

  Widget _buildHeader() {
    final p = _perfil ?? {};
    final nivel = p['nivel']?.toString() ?? '—';
    final xpTotal = (p['xp_total'] as num?)?.toInt() ?? 0;
    final sequencia = p['sequenciaAtual'] as int? ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.apMyProfile,
            style: TextStyle(
              color: context.c.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statBox(
                Icons.emoji_events_rounded,
                context.sem.warning,
                context.l10n.apLevel,
                nivel,
              ),
              const SizedBox(width: 12),
              _statBox(
                Icons.leaderboard_rounded,
                context.c.primary,
                'XP Total',
                '$xpTotal',
              ),
              const SizedBox(width: 12),
              _statBox(
                Icons.local_fire_department_rounded,
                context.sem.danger,
                context.l10n.apStreak,
                '${sequencia}d',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, Color color, String label, String value) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: context.c.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.c.outline),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildXpBar() {
    final p = _perfil ?? {};
    final xpTotal = (p['xp_total'] as num?)?.toInt() ?? 0;
    final xpMensal = (p['xp_mensal'] as num?)?.toInt() ?? 0;
    final xpProximo = (p['xpParaProximoNivel'] as num?)?.toInt() ?? 1;
    final progresso = xpProximo > 0 ? (xpTotal % xpProximo) / xpProximo : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP Total',
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Text(
                '$xpTotal XP',
                style: TextStyle(
                  color: context.c.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progresso.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: context.c.outline,
              valueColor: AlwaysStoppedAnimation<Color>(context.c.primary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.apThisMonthXp(xpMensal),
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                context.l10n.apNextLevelXp(xpProximo),
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
        color: desbloqueada ? context.c.surfaceContainer : context.c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: desbloqueada
              ? context.c.primary.withOpacity(0.4)
              : context.c.outline,
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
              color: desbloqueada
                  ? context.c.primary.withOpacity(0.15)
                  : context.c.outline.withOpacity(0.3),
            ),
            child: Icon(
              desbloqueada
                  ? Icons.emoji_events_rounded
                  : Icons.lock_outline_rounded,
              color: desbloqueada
                  ? context.c.primary
                  : context.c.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            c['nome'] as String? ?? '',
            style: TextStyle(
              color: desbloqueada
                  ? context.c.onSurface
                  : context.c.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (desbloqueada && (c['pontosXpBonus'] as int? ?? 0) > 0) ...[
            const SizedBox(height: 4),
            Text(
              '+${c['pontosXpBonus']} XP',
              style: TextStyle(
                color: context.sem.success,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
