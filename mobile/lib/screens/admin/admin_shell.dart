import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/tab_refresh.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _tabs = [
    (icon: Icons.bar_chart_rounded, label: 'Dashboard', route: '/admin/dashboard'),
    (icon: Icons.sports_martial_arts, label: 'Alunos', route: '/admin/alunos'),
    (icon: Icons.groups_rounded, label: 'Turmas', route: '/admin/turmas'),
    (icon: Icons.badge_rounded, label: 'Equipe', route: '/admin/equipe'),
    (icon: Icons.credit_card_rounded, label: 'Financeiro', route: '/admin/financeiro'),
    (icon: Icons.emoji_events_rounded, label: 'Ranking', route: '/admin/ranking'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: kSurface,
        indicatorColor: kPrimary.withOpacity(0.2),
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) {
          adminTabNotifier.value = i;
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon, color: kText2),
                  selectedIcon: Icon(t.icon, color: kPrimary),
                  label: t.label,
                ))
            .toList(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
