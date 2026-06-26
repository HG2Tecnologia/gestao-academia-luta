import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/tab_refresh.dart';
import 'aluno_qrcode_sheet.dart';

class AlunoShell extends StatefulWidget {
  const AlunoShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<AlunoShell> createState() => _AlunoShellState();
}

class _AlunoShellState extends State<AlunoShell> {
  static const _items = [
    (icon: Icons.person_rounded, iconOff: Icons.person_outline_rounded, label: 'Perfil'),
    (icon: Icons.schedule_rounded, iconOff: Icons.schedule_outlined, label: 'Horários'),
    (icon: Icons.check_circle_rounded, iconOff: Icons.check_circle_outline_rounded, label: 'Presenças'),
    (icon: Icons.credit_card_rounded, iconOff: Icons.credit_card_outlined, label: 'Financeiro'),
    (icon: Icons.emoji_events_rounded, iconOff: Icons.emoji_events_outlined, label: 'Ranking'),
  ];

  void _navegar(int index) {
    alunoTabNotifier.value = index;
    widget.shell.goBranch(index, initialLocation: index == widget.shell.currentIndex);
    Navigator.of(context).pop();
  }

  void _navegarEAcionar(int index, String action) {
    Navigator.of(context).pop();
    widget.shell.goBranch(index, initialLocation: index == widget.shell.currentIndex);
    alunoTabNotifier.value = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      alunoDrawerActionNotifier.value = action;
    });
  }

  Future<void> _mostrarQr() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    showModalBottomSheet(
      context: alunoShellKey.currentContext ?? context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AlunoQrCodeSheet(),
    );
  }

  Future<void> _sair() async {
    Navigator.of(context).pop();
    try { await dio.post('/api/auth/logout'); } catch (_) {}
    await AuthStorage.clear();
    if (mounted) context.go('/login');
  }

  Future<void> _excluirConta() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Excluir conta?', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Text('Seus dados pessoais serão removidos permanentemente. Esta ação não pode ser desfeita.', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Excluir', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    try {
      await dio.delete('/api/usuarios/me');
      await AuthStorage.clear();
      if (mounted) context.go('/login');
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao excluir conta.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary.withOpacity(0.4), const Color(0xFF0A0A0A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimary.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.person_rounded, color: kPrimary, size: 22),
                ),
                const SizedBox(height: 12),
                const Text('Área do Aluno', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                Text('Meu espaço', style: TextStyle(color: kText2, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  // Navegação principal
                  for (int i = 0; i < _items.length; i++)
                    _DrawerItem(
                      icon: idx == i ? _items[i].icon : _items[i].iconOff,
                      label: _items[i].label,
                      selected: idx == i,
                      onTap: () => _navegar(i),
                    ),

                  const Divider(height: 24),

                  // Atalhos
                  _DrawerItem(
                    icon: Icons.qr_code_rounded,
                    label: 'QR Presença',
                    selected: false,
                    onTap: _mostrarQr,
                  ),
                  _DrawerItem(
                    icon: Icons.assignment_turned_in_rounded,
                    label: 'PAR-Q',
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/aluno/parq');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.newspaper_rounded,
                    label: 'Notícias',
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/noticias');
                    },
                  ),

                  const Divider(height: 24),

                  // Conta
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Text('CONTA', style: TextStyle(color: kText2, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  ),
                  _DrawerItem(
                    icon: Icons.edit_rounded,
                    label: 'Editar Perfil',
                    selected: false,
                    onTap: () => _navegarEAcionar(0, 'editarPerfil'),
                  ),
                  _DrawerItem(
                    icon: Icons.lock_reset_rounded,
                    label: 'Alterar Senha',
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/alterar-senha');
                    },
                  ),
                ],
              ),
            ),

            // Sair + Excluir Conta fixos no rodapé
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(children: [
                const Divider(height: 16),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Sair',
                  selected: false,
                  onTap: _sair,
                  textColor: kText2,
                ),
                _DrawerItem(
                  icon: Icons.delete_forever_rounded,
                  label: 'Excluir conta',
                  selected: false,
                  onTap: _excluirConta,
                  textColor: kDanger.withOpacity(0.7),
                  iconColor: kDanger.withOpacity(0.7),
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
      key: alunoShellKey,
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
  final Color? textColor;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final iColor = iconColor ?? (selected ? kPrimary : kText2);
    final tColor = textColor ?? (selected ? kPrimary : kText1);
    return Material(
      color: selected ? kPrimary.withOpacity(0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Icon(icon, color: iColor, size: 20),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: tColor, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
          ]),
        ),
      ),
    );
  }
}
