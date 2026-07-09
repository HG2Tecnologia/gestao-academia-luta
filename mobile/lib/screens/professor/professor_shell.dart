import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';

class ProfessorShell extends StatefulWidget {
  const ProfessorShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<ProfessorShell> createState() => _ProfessorShellState();
}

class _ProfessorShellState extends State<ProfessorShell> {
  static const _allItems = [
    (icon: Icons.groups_rounded,          iconOff: Icons.groups_outlined,               label: 'Turmas',     perm: 'tela_turmas',    idx: 0),
    (icon: Icons.schedule_rounded,        iconOff: Icons.schedule_outlined,             label: 'Horários',   perm: 'tela_horarios',  idx: 1),
    (icon: Icons.check_circle_rounded,    iconOff: Icons.check_circle_outline_rounded,  label: 'Presença',   perm: 'tela_presenca',  idx: 2),
    (icon: Icons.sports_martial_arts,     iconOff: Icons.sports_martial_arts_outlined,  label: 'Graduação',  perm: 'tela_graduacao', idx: 3),
    (icon: Icons.emoji_events_rounded,    iconOff: Icons.emoji_events_outlined,         label: 'Rankings',   perm: 'tela_rankings',  idx: 4),
    (icon: Icons.person_rounded,          iconOff: Icons.person_outline_rounded,        label: 'Perfil',     perm: '',               idx: 5),
  ];

  Map<String, bool> _permissoes = {};
  bool _permLoaded = false;

  @override
  void initState() {
    super.initState();
    _carregarPermissoes();
  }

  Future<void> _carregarPermissoes() async {
    final user = await AuthStorage.getUser();
    if (mounted) {
      setState(() {
        _permissoes = user?.permissoes ?? {};
        _permLoaded = true;
      });
    }
  }

  bool _temPermissao(String perm) {
    if (perm.isEmpty) return true; // Perfil sempre visível
    if (!_permLoaded) return true; // Ainda carregando → mostra tudo
    return _permissoes[perm] ?? false;
  }

  void _navegar(int shellIdx) {
    widget.shell.goBranch(shellIdx, initialLocation: shellIdx == widget.shell.currentIndex);
    Navigator.of(context).pop();
  }

  Widget _buildDrawer() {
    final currentIdx = widget.shell.currentIndex;

    // Filtra itens com permissão
    final visibleItems = _allItems.where((item) => _temPermissao(item.perm)).toList();

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
                  colors: [Color(0xFF161616), Color(0xFF0A0A0A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.blue, size: 22),
                ),
                const SizedBox(height: 12),
                const Text('Área do Professor', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                Text('Painel do professor', style: TextStyle(color: kText2, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final item in visibleItems)
                    _DrawerItem(
                      icon: currentIdx == item.idx ? item.icon : item.iconOff,
                      label: item.label,
                      selected: currentIdx == item.idx,
                      onTap: () => _navegar(item.idx),
                    ),
                  const Divider(height: 24),
                  _DrawerItem(
                    icon: Icons.newspaper_rounded,
                    label: 'Notícias da Academia',
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
              child: Column(children: [
                const Divider(height: 16),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Sair',
                  selected: false,
                  onTap: () {
                    Navigator.of(context).pop();
                    FirebaseAuth.instance.signOut().catchError((_) {}).whenComplete(() {
                      AuthStorage.clear().then((_) {
                        if (context.mounted) context.go('/login');
                      });
                    });
                  },
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: profShellKey,
      body: widget.shell,
      endDrawer: _buildDrawer(),
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
