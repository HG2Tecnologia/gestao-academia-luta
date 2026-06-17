import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/tab_refresh.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const _items = [
    (icon: Icons.bar_chart_rounded, label: 'Dashboard', route: '/admin/dashboard'),
    (icon: Icons.sports_martial_arts, label: 'Alunos', route: '/admin/alunos'),
    (icon: Icons.groups_rounded, label: 'Turmas', route: '/admin/turmas'),
    (icon: Icons.badge_rounded, label: 'Equipe', route: '/admin/equipe'),
    (icon: Icons.credit_card_rounded, label: 'Financeiro', route: '/admin/financeiro'),
    (icon: Icons.emoji_events_rounded, label: 'Ranking', route: '/admin/ranking'),
  ];

  void _navegar(int index) {
    adminTabNotifier.value = index;
    widget.shell.goBranch(index, initialLocation: index == widget.shell.currentIndex);
    Navigator.of(context).pop();
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
                  colors: [Color(0xFF1A0F3C), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kPrimary, const Color(0xFF9B6DFF)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 12),
                const Text('Administrador', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                Text('Painel de Gestão', style: TextStyle(color: kText2, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (int i = 0; i < _items.length; i++)
                    _DrawerItem(
                      icon: _items[i].icon,
                      label: _items[i].label,
                      selected: idx == i,
                      onTap: () => _navegar(i),
                    ),
                  const Divider(height: 24),
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
      drawer: _buildDrawer(),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.selected, required this.onTap});

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
          child: Row(children: [
            Icon(icon, color: selected ? kPrimary : kText2, size: 20),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: selected ? kPrimary : kText1, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
          ]),
        ),
      ),
    );
  }
}
