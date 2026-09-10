import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';

export 'graduacao_display.dart';

/// Rótulo de seção em caixa alta ("HISTÓRICO", "COBRANÇAS"...).
class SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader(
    this.label, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Estado vazio consistente. Ícone + título + subtítulo opcional + ação
/// opcional.
class AlunoEmptyState extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String? subtitulo;
  final String? acaoLabel;
  final VoidCallback? onAcao;

  const AlunoEmptyState({
    super.key,
    required this.icon,
    required this.titulo,
    this.subtitulo,
    this.acaoLabel,
    this.onAcao,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: context.c.outline, size: 60),
            const SizedBox(height: AppSpacing.md),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitulo!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.c.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
              ),
            ],
            if (acaoLabel != null && onAcao != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: onAcao,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.c.primary,
                  side: BorderSide(
                    color: context.c.primary.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.brSm,
                  ),
                ),
                child: Text(acaoLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum StatusTone { success, warning, danger, neutral, info }

/// Chip de status (Pago / Pendente / Atrasado / Em dia...).
class StatusChip extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;

  const StatusChip(
    this.label, {
    super.key,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  Color _color(BuildContext context) => switch (tone) {
    StatusTone.success => context.sem.success,
    StatusTone.warning => context.sem.warning,
    StatusTone.danger => context.sem.danger,
    StatusTone.info => context.c.primary,
    StatusTone.neutral => context.c.onSurfaceVariant,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color(context).withValues(alpha: 0.15),
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: _color(context)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: _color(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card grande de ação da Home (grid 2x2). Área de toque >= 48dp.
class StudentQuickActionCard extends StatelessWidget {
  final IconData icon;

  /// Substitui o [Icon] padrão por um widget próprio (ex.: BeltIcon). Recebe a
  /// cor de destaque já resolvida.
  final Widget Function(Color color)? iconBuilder;
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  const StudentQuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconBuilder,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? context.c.primary;
    return Material(
      color: context.c.surfaceContainer,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: context.c.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.14),
                  borderRadius: AppRadius.brSm,
                ),
                child: iconBuilder?.call(c) ?? Icon(icon, color: c, size: 21),
              ),
              const SizedBox(height: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Container de card padrão (surface + borda + raio), com toque opcional.
class AlunoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Gradient? gradient;

  const AlunoCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? context.c.surfaceContainer : null,
        gradient: gradient,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: borderColor ?? context.c.outline),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: content,
      ),
    );
  }
}
