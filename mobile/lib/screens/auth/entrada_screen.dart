import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/appearance_controls.dart';
import '../../core/theme/context_ext.dart';

/// Tela inicial de entrada: separa o público antes do login.
///
/// Evita que um aluno/responsável veja a opção de criar uma academia e
/// contextualiza a tela de login seguinte (`/login`) por meio do parâmetro
/// `contexto` ('aluno' ou 'academia'), passado via `extra` do GoRouter.
class EntradaScreen extends StatelessWidget {
  const EntradaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: PreLoginAppearanceBar(),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/logo_app.png',
                          width: 72,
                          height: 72,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'SENSEI MANAGER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.authWelcomeChooseAccess,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 36),
                      _EntradaCard(
                        icone: Icons.person_rounded,
                        titulo: l.authIAmStudentOrGuardianTitle,
                        subtitulo: l.authIAmStudentOrGuardianSubtitle,
                        onTap: () => context.push(
                          '/login',
                          extra: const {'contexto': 'aluno'},
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EntradaCard(
                        icone: Icons.apartment_rounded,
                        titulo: l.authIAmAcademyTitle,
                        subtitulo: l.authIAmAcademySubtitle,
                        onTap: () => context.push(
                          '/login',
                          extra: const {'contexto': 'academia'},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntradaCard extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _EntradaCard({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$titulo. $subtitulo',
      excludeSemantics: true,
      child: Material(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.c.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.c.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, color: context.c.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: context.c.onSurfaceVariant,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
