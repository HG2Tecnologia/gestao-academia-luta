import 'package:flutter/material.dart';
import 'paywall_modal.dart';
import 'theme/context_ext.dart';

/// Selo "PRO" pequeno, usado tanto no `ProGate` quanto em qualquer lugar que
/// precise só do selo sem o bloqueio inteiro (ex.: ao lado de um título).
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A020),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Deixa `child` visualmente desabilitado (esmaecido, sem interação) e
/// sobrepõe um selo "PRO" — tocar em qualquer ponto abre o paywall em vez de
/// executar a ação original. Usado pra desabilitar um controle existente
/// (botão de exportar, switch de configuração) sem precisar reescrevê-lo.
///
/// Quando a academia já é Pro, devolve `child` sem nenhuma alteração.
class ProGate extends StatelessWidget {
  const ProGate({super.key, required this.child, this.isPro = false});

  final Widget child;

  /// Permite que a tela já decida isso uma vez (ex.: lendo PlanService.isPro)
  /// e passe pra vários ProGate sem reconsultar toda hora.
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    if (isPro) return child;
    return Stack(
      children: [
        IgnorePointer(child: Opacity(opacity: 0.45, child: child)),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => mostrarPaywall(context),
              child: const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: ProBadge(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cartão de substituição completa pra uma seção/feature inteira que só
/// existe no Pro (ex.: "Risco de evasão", "Próximos de graduar") — em vez de
/// esmaecer dados reais de alunos, troca a seção toda por um aviso limpo.
/// Tocar abre o paywall.
class ProLockedCard extends StatelessWidget {
  const ProLockedCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Material(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => mostrarPaywall(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: context.c.onSurfaceVariant.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: context.c.onSurfaceVariant, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: context.c.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const ProBadge(),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.lock_rounded,
                  color: context.c.onSurfaceVariant,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
