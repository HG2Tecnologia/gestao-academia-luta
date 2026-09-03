import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';

/// Tela inicial de entrada: separa o público antes do login.
///
/// Evita que um aluno/responsável veja a opção de criar uma academia e
/// contextualiza a tela de login seguinte (`/login`) por meio do parâmetro
/// `contexto` ('aluno' ou 'academia'), passado via `extra` do GoRouter.
class EntradaScreen extends StatelessWidget {
  const EntradaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
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
                const Text(
                  'SENSEI MANAGER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bem-vindo, escolha sua forma de acesso',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kText2, fontSize: 13),
                ),
                const SizedBox(height: 36),
                _EntradaCard(
                  icone: Icons.person_rounded,
                  titulo: 'Sou Aluno ou Responsável',
                  subtitulo: 'Treinos, graduações, financeiro e carteirinha',
                  onTap: () => context.push(
                    '/login',
                    extra: const {'contexto': 'aluno'},
                  ),
                ),
                const SizedBox(height: 14),
                _EntradaCard(
                  icone: Icons.apartment_rounded,
                  titulo: 'Sou uma Academia',
                  subtitulo: 'Gerencie alunos, turmas, equipe e financeiro',
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
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, color: kPrimary, size: 24),
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
                          color: kText1,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(color: kText2, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, color: kText2, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
