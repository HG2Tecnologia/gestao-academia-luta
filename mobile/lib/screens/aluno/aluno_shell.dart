import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/tab_refresh.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/whats_new_service.dart';
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
  static const _destinos = [
    (icon: Icons.home_rounded, iconOff: Icons.home_outlined, label: 'Início'),
    (
      icon: Icons.calendar_month_rounded,
      iconOff: Icons.calendar_month_outlined,
      label: 'Aulas',
    ),
    (
      icon: Icons.workspace_premium_rounded, // substituído por BeltIcon no build
      iconOff: Icons.workspace_premium_outlined,
      label: 'Graduações',
    ),
    (
      icon: Icons.credit_card_rounded,
      iconOff: Icons.credit_card_outlined,
      label: 'Financeiro',
    ),
    (
      icon: Icons.person_rounded,
      iconOff: Icons.person_outline_rounded,
      label: 'Perfil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) WhatsNewService.checkAndShow(context);
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
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: _navegar,
        destinations: [
          for (var i = 0; i < _destinos.length; i++)
            NavigationDestination(
              // Graduações usa a faixa de artes marciais desenhada à mão.
              icon: i == 2 ? const BeltIcon() : Icon(_destinos[i].iconOff),
              selectedIcon:
                  i == 2 ? const BeltIcon() : Icon(_destinos[i].icon),
              label: _destinos[i].label,
            ),
        ],
      ),
    );
  }
}
