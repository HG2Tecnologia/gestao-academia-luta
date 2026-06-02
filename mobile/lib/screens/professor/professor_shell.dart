import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';

class ProfessorShell extends StatelessWidget {
  const ProfessorShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: kSurface,
        indicatorColor: kPrimary.withOpacity(0.2),
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: Icon(Icons.groups_outlined, color: kText2), selectedIcon: Icon(Icons.groups_rounded, color: kPrimary), label: 'Turmas'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined, color: kText2), selectedIcon: Icon(Icons.schedule_rounded, color: kPrimary), label: 'Horários'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline_rounded, color: kText2), selectedIcon: Icon(Icons.check_circle_rounded, color: kPrimary), label: 'Presença'),
          NavigationDestination(icon: Icon(Icons.sports_martial_arts_outlined, color: kText2), selectedIcon: Icon(Icons.sports_martial_arts, color: kPrimary), label: 'Graduação'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined, color: kText2), selectedIcon: Icon(Icons.emoji_events_rounded, color: kPrimary), label: 'Rankings'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded, color: kText2), selectedIcon: Icon(Icons.person_rounded, color: kPrimary), label: 'Perfil'),
        ],
      ),
    );
  }
}
