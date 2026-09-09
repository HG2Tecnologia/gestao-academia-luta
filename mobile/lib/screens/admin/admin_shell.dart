import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/perfil_switch.dart';
import '../../core/profile_session_service.dart';
import '../../core/tab_refresh.dart';
import '../../core/whats_new_service.dart';

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
      if (mounted) WhatsNewService.checkAndShow(context);
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

  static const _items = [
    (
      icon: Icons.bar_chart_rounded,
      label: 'Dashboard',
      route: '/admin/dashboard',
    ),
    (icon: Icons.sports_martial_arts, label: 'Alunos', route: '/admin/alunos'),
    (icon: Icons.groups_rounded, label: 'Turmas', route: '/admin/turmas'),
    (icon: Icons.badge_rounded, label: 'Equipe', route: '/admin/equipe'),
    (
      icon: Icons.credit_card_rounded,
      label: 'Financeiro',
      route: '/admin/financeiro',
    ),
    (
      icon: Icons.emoji_events_rounded,
      label: 'Ranking',
      route: '/admin/ranking',
    ),
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
    final idx = widget.shell.currentIndex;
    return Drawer(
      backgroundColor: kSurface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1200), Color(0xFF0A0A0A)],
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
                              colors: [kPrimary, const Color(0xFF0A0A0A)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Administrador',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _nomePerfilAtual.isNotEmpty
                              ? _nomePerfilAtual
                              : 'Painel de Gestão',
                          style: TextStyle(color: kText2, fontSize: 12),
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
                  _DrawerSection('PRINCIPAL'),
                  for (int i = 0; i < _items.length; i++)
                    _DrawerItem(
                      icon: _items[i].icon,
                      label: _items[i].label,
                      selected: idx == i,
                      onTap: () => _navegar(i),
                    ),
                  const Divider(height: 24),
                  _DrawerSection('OUTROS'),
                  _DrawerItem(
                    icon: Icons.newspaper_rounded,
                    label: 'Notícias',
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/admin/noticias');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Configurações',
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
                  _DrawerSection('CONTA'),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Sair',
                    selected: false,
                    onTap: () async {
                      Navigator.of(context).pop();
                      try {
                        await FirebaseAuth.instance.signOut();
                      } catch (_) {}
                      await AuthStorage.clear();
                      if (context.mounted) context.go('/boas-vindas');
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
    return Scaffold(
      key: adminShellKey,
      body: widget.shell,
      endDrawer: _buildDrawer(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: kSurface,
        indicatorColor: kPrimary.withOpacity(0.18),
        selectedIndex: _navSelectedIndex,
        onDestinationSelected: _onNavTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_martial_arts_outlined),
            selectedIcon: Icon(Icons.sports_martial_arts),
            label: 'Alunos',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Turmas',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card_rounded),
            label: 'Financeiro',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'Mais',
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
          color: kText2,
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
    return Material(
      color: selected ? kPrimary.withOpacity(0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: selected ? kPrimary : kText2, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: selected ? kPrimary : kText1,
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
