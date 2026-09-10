import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth_storage.dart';
import '../../core/drawer_helper.dart';
import '../../core/perfil_switch.dart';
import '../../core/profile_session_service.dart';
import '../../core/tab_refresh.dart';
import '../../core/theme/context_ext.dart';
import '../../core/whats_new_service.dart';
import '../../core/release_notes.dart';
import '../../l10n/app_localizations.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _perfis = [];
  String _nomePerfilAtual = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _atualizarPerfis();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        WhatsNewService.checkAndShow(context, viewer: ReleaseViewer.academy);
      }
    });
  }

  Future<void> _atualizarPerfis() async {
    var user = await AuthStorage.getUser();
    try {
      user = await ProfileSessionService.refresh() ?? user;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _perfis = user?.perfis ?? [];
        _nomePerfilAtual = user?.nome ?? '';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _atualizarPerfis();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  static const _icons = [
    Icons.bar_chart_rounded,
    Icons.sports_martial_arts,
    Icons.groups_rounded,
    Icons.badge_rounded,
    Icons.credit_card_rounded,
    Icons.emoji_events_rounded,
  ];

  List<String> _labels(AppLocalizations l) => [
    l.navDashboard,
    l.navStudents,
    l.navClasses,
    l.navStaff,
    l.navBilling,
    l.navRanking,
  ];

  // Branches do StatefulShellRoute: 0 Dashboard · 1 Alunos · 2 Turmas ·
  // 3 Equipe · 4 Financeiro · 5 Ranking.
  static const _navBranches = [
    0,
    1,
    2,
    4,
  ]; // Início · Alunos · Turmas · Financeiro

  void _navegar(int branchIndex) {
    adminTabNotifier.value = branchIndex;
    widget.shell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.shell.currentIndex,
    );
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  int get _navSelectedIndex {
    final i = _navBranches.indexOf(widget.shell.currentIndex);
    return i < 0 ? _navBranches.length : i; // Equipe/Ranking → "Mais"
  }

  void _onNavTap(int navIndex) {
    if (navIndex < _navBranches.length) {
      _navegar(_navBranches[navIndex]);
    } else {
      adminShellKey.currentState?.openEndDrawer();
    }
  }

  Widget _buildDrawer() {
    final l = context.l10n;
    final idx = widget.shell.currentIndex;
    final labels = _labels(l);
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
                  colors: context.isDark
                      ? const [Color(0xFF1A1200), Color(0xFF0A0A0A)]
                      : [
                          context.sem.goldContainer,
                          context.c.surfaceContainerLow,
                        ],
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
                            gradient: LinearGradient(
                              colors: [
                                context.c.primary,
                                context.c.primary.withValues(alpha: 0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            color: context.c.onPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.roleAdmin,
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _nomePerfilAtual.isNotEmpty
                              ? _nomePerfilAtual
                              : l.adminPanelSubtitle,
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
                        Navigator.of(context).pop();
                        await mostrarTrocarPerfil(context);
                        _atualizarPerfis();
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
                  _DrawerSection(l.menuSectionMain),
                  for (int i = 0; i < _icons.length; i++)
                    _DrawerItem(
                      icon: _icons[i],
                      label: labels[i],
                      selected: idx == i,
                      onTap: () => _navegar(i),
                    ),
                  const Divider(height: 24),
                  _DrawerSection(l.menuSectionOther),
                  _DrawerItem(
                    icon: Icons.newspaper_rounded,
                    label: l.menuNews,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/admin/noticias');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: l.menuSettings,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/admin/dashboard/configuracoes');
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
                  _DrawerSection(l.menuSectionAccount),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: l.menuSignOut,
                    selected: false,
                    onTap: () async {
                      final router = GoRouter.of(context);
                      Navigator.of(context).pop();
                      try {
                        await FirebaseAuth.instance.signOut();
                      } catch (_) {}
                      await AuthStorage.clear();
                      router.go('/boas-vindas');
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
    final l = context.l10n;
    return Scaffold(
      key: adminShellKey,
      body: widget.shell,
      endDrawer: _buildDrawer(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navSelectedIndex,
        onDestinationSelected: _onNavTap,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.sports_martial_arts_outlined),
            selectedIcon: const Icon(Icons.sports_martial_arts),
            label: l.navStudents,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
            label: l.navClasses,
          ),
          NavigationDestination(
            icon: const Icon(Icons.credit_card_outlined),
            selectedIcon: const Icon(Icons.credit_card_rounded),
            label: l.navBilling,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_rounded),
            selectedIcon: const Icon(Icons.more_horiz_rounded),
            label: l.navMore,
          ),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String label;
  const _DrawerSection(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Text(
        label,
        style: TextStyle(
          color: context.c.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
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
    final active = selected ? context.c.primary : context.c.onSurfaceVariant;
    return Material(
      color: selected
          ? context.c.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: active, size: 20),
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
