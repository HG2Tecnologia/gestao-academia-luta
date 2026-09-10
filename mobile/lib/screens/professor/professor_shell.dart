import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/drawer_helper.dart';
import '../../core/perfil_switch.dart';
import '../../core/profile_session_service.dart';
import '../../core/whats_new_service.dart';

class ProfessorShell extends StatefulWidget {
  const ProfessorShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<ProfessorShell> createState() => _ProfessorShellState();
}

class _ProfessorShellState extends State<ProfessorShell>
    with WidgetsBindingObserver {
  static const _allItems = [
    (
      icon: Icons.home_rounded,
      iconOff: Icons.home_outlined,
      labelKey: 'inicio',
      perm: '',
      idx: 0,
    ),
    (
      icon: Icons.groups_rounded,
      iconOff: Icons.groups_outlined,
      labelKey: 'turmas',
      perm: 'tela_turmas',
      idx: 1,
    ),
    (
      icon: Icons.sports_martial_arts,
      iconOff: Icons.sports_martial_arts_outlined,
      labelKey: 'alunos',
      perm: 'tela_alunos',
      idx: 2,
    ),
    (
      icon: Icons.schedule_rounded,
      iconOff: Icons.schedule_outlined,
      labelKey: 'horarios',
      perm: 'tela_horarios',
      idx: 3,
    ),
    (
      icon: Icons.emoji_events_rounded,
      iconOff: Icons.emoji_events_outlined,
      labelKey: 'rankings',
      perm: 'tela_rankings',
      idx: 4,
    ),
    (
      icon: Icons.person_rounded,
      iconOff: Icons.person_outline_rounded,
      labelKey: 'perfil',
      perm: '',
      idx: 5,
    ),
  ];

  Map<String, bool> _permissoes = {};
  bool _permLoaded = false;
  List<Map<String, dynamic>> _perfis = [];
  String _nomePerfilAtual = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _carregarPermissoes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) WhatsNewService.checkAndShow(context);
    });
  }

  Future<void> _carregarPermissoes() async {
    var user = await AuthStorage.getUser();
    try {
      user = await ProfileSessionService.refresh() ?? user;
    } catch (_) {
      // Mantém a última configuração válida para funcionamento offline.
    }
    if (mounted) {
      setState(() {
        _permissoes = user?.permissoes ?? {};
        _perfis = user?.perfis ?? [];
        _nomePerfilAtual = user?.nome ?? '';
        _permLoaded = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _carregarPermissoes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _temPermissao(String perm) {
    if (perm.isEmpty) return true; // Perfil sempre visível
    if (!_permLoaded) return true; // Ainda carregando → mostra tudo
    return _permissoes[perm] ?? false;
  }

  void _navegar(int shellIdx) {
    widget.shell.goBranch(
      shellIdx,
      initialLocation: shellIdx == widget.shell.currentIndex,
    );
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  // Branches: 0 Início · 1 Turmas · 2 Alunos · 3 Horários · 4 Rankings ·
  // 5 Perfil. A barra inferior mostra o Início + até 3 telas permitidas;
  // o resto fica no "Mais" (drawer).
  List<int> get _navBranches {
    const candidatas = [1, 2, 3, 4]; // ordem de prioridade
    final perm = {for (final i in _allItems) i.idx: i.perm};
    final extras = candidatas
        .where((b) => _temPermissao(perm[b] ?? ''))
        .take(3)
        .toList();
    return [0, ...extras];
  }

  int get _navSelectedIndex {
    final i = _navBranches.indexOf(widget.shell.currentIndex);
    return i < 0 ? _navBranches.length : i; // fora da barra → "Mais"
  }

  void _onNavTap(int navIndex) {
    final branches = _navBranches;
    if (navIndex < branches.length) {
      _navegar(branches[navIndex]);
    } else {
      profShellKey.currentState?.openEndDrawer();
    }
  }

  String _label(String k, AppLocalizations l) => switch (k) {
    'inicio' => l.navHome,
    'turmas' => l.navClasses,
    'alunos' => l.navStudents,
    'horarios' => l.navSchedule,
    'rankings' => l.navRanking,
    'perfil' => l.navProfile,
    _ => k,
  };

  NavigationDestination _dest(int branch) {
    final item = _allItems.firstWhere((i) => i.idx == branch);
    return NavigationDestination(
      icon: Icon(item.iconOff),
      selectedIcon: Icon(item.icon),
      label: _label(item.labelKey, context.l10n),
    );
  }

  Widget _buildDrawer() {
    final currentIdx = widget.shell.currentIndex;

    // Filtra itens com permissão
    final visibleItems = _allItems
        .where((item) => _temPermissao(item.perm))
        .toList();

    return Drawer(
      backgroundColor: context.c.surfaceContainer,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.c.surfaceContainer, context.c.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.c.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.blue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.profAreaTitle,
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _nomePerfilAtual.isNotEmpty
                              ? _nomePerfilAtual
                              : context.l10n.profPanelSubtitle,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_perfis.length > 1)
                    PerfilSwitchButton(
                      onPressed: () async {
                        await mostrarTrocarPerfil(context);
                        _carregarPermissoes();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final item in visibleItems)
                    _DrawerItem(
                      icon: currentIdx == item.idx ? item.icon : item.iconOff,
                      label: _label(item.labelKey, context.l10n),
                      selected: currentIdx == item.idx,
                      onTap: () => _navegar(item.idx),
                    ),
                  const Divider(height: 24),
                  _DrawerItem(
                    icon: Icons.newspaper_rounded,
                    label: context.l10n.profNewsAcademy,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/noticias');
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                children: [
                  const Divider(height: 16),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: context.l10n.cfgLogout,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      FirebaseAuth.instance
                          .signOut()
                          .catchError((_) {})
                          .whenComplete(() {
                            AuthStorage.clear().then((_) {
                              if (context.mounted) context.go('/boas-vindas');
                            });
                          });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branches = _navBranches;
    return Scaffold(
      key: profShellKey,
      body: widget.shell,
      endDrawer: _buildDrawer(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: context.c.surfaceContainer,
        indicatorColor: context.c.primary.withValues(alpha: 0.18),
        selectedIndex: _navSelectedIndex,
        onDestinationSelected: _onNavTap,
        destinations: [
          for (final b in branches) _dest(b),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_rounded),
            selectedIcon: const Icon(Icons.more_horiz_rounded),
            label: context.l10n.navMore,
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.c.primary.withOpacity(0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? context.c.primary
                    : context.c.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: selected ? context.c.primary : context.c.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
