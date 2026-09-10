import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/tab_refresh.dart';
import '../../core/theme/context_ext.dart';
import '../../core/whats_new_service.dart';
import '../../core/release_notes.dart';
import 'widgets/belt_icon.dart';

/// Casca da área do aluno: apenas a NavigationBar inferior (Material 3).
/// Não há mais menu lateral — os itens secundários vivem na aba Perfil.
class AlunoShell extends StatefulWidget {
  const AlunoShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<AlunoShell> createState() => _AlunoShellState();
}

class _AlunoShellState extends State<AlunoShell> {
  static const _icons = [
    (on: Icons.home_rounded, off: Icons.home_outlined),
    (on: Icons.calendar_month_rounded, off: Icons.calendar_month_outlined),
    (
      on: Icons.workspace_premium_rounded,
      off: Icons.workspace_premium_outlined,
    ),
    (on: Icons.credit_card_rounded, off: Icons.credit_card_outlined),
    (on: Icons.person_rounded, off: Icons.person_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        WhatsNewService.checkAndShow(context, viewer: ReleaseViewer.student);
      }
    });
  }

  void _navegar(int index) {
    alunoTabNotifier.value = index;
    widget.shell.goBranch(
      index,
      initialLocation: index == widget.shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = [
      l.navHome,
      l.navLessons,
      l.navPromotions,
      l.navBilling,
      l.navProfile,
    ];
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: context.c.surfaceContainer,
        indicatorColor: context.c.primary.withValues(alpha: 0.18),
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: _navegar,
        destinations: [
          for (var i = 0; i < _icons.length; i++)
            NavigationDestination(
              // Graduações usa a faixa de artes marciais desenhada à mão.
              icon: i == 2 ? const BeltIcon() : Icon(_icons[i].off),
              selectedIcon: i == 2 ? const BeltIcon() : Icon(_icons[i].on),
              label: labels[i],
            ),
        ],
      ),
    );
  }
}
