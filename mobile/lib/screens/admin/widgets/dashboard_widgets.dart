import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';

/// Componentes da Dashboard administrativa. Identidade preto/dourado do
/// Sensei Manager: cor só em ícones, badges, bordas e pequenos fundos
/// semânticos — sem grandes gradientes.

enum DashTone { gold, info, success, warning, danger, neutral }

extension DashToneColor on DashTone {
  Color get color => switch (this) {
        DashTone.gold => AppColors.primary,
        DashTone.info => AppColors.info,
        DashTone.success => AppColors.success,
        DashTone.warning => AppColors.warning,
        DashTone.danger => AppColors.danger,
        DashTone.neutral => AppColors.textSecondary,
      };
}

/// Cabeçalho de seção: título + ação "Ver todas" opcional.
class DashSectionHeader extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry padding;

  const DashSectionHeader(
    this.title, {
    super.key,
    this.trailingLabel,
    this.onTrailingTap,
    this.padding =
        const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (trailingLabel != null && onTrailingTap != null)
            GestureDetector(
              onTap: onTrailingTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    trailingLabel!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.primary, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Card de indicador (grid 2x2). Todos com o mesmo tamanho/estrutura.
class DashMetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final DashTone tone;
  final VoidCallback? onTap;

  const DashMetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.tone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = tone.color;
    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brMd,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: c.withValues(alpha: 0.30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.14),
                        borderRadius: AppRadius.brSm,
                      ),
                      child: Icon(icon, color: c, size: 19),
                    ),
                    const Spacer(),
                    if (onTap != null)
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary, size: 18),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ação rápida: card quadrado com fundo tonal leve, ícone e rótulo dentro.
class DashQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final DashTone tone;
  final VoidCallback onTap;

  const DashQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = tone.color;
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: c.withValues(alpha: 0.10),
            borderRadius: AppRadius.brMd,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.brMd,
              child: Container(
                height: 96,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: c.withValues(alpha: 0.28)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: c, size: 26),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Casca de card padrão da dashboard: surface + borda com leve tint.
class DashCard extends StatelessWidget {
  final Widget child;
  final DashTone tone;
  final EdgeInsetsGeometry padding;

  const DashCard({
    super.key,
    required this.child,
    this.tone = DashTone.neutral,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final border = tone == DashTone.neutral
        ? AppColors.border
        : tone.color.withValues(alpha: 0.30);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

/// Linha de cabeçalho dentro de um DashCard: ícone + título + subtítulo +
/// trailing opcional (badge / contador / seta).
class DashCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final DashTone tone;
  final Widget? trailing;

  const DashCardHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.tone = DashTone.gold,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = tone.color;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: AppRadius.brSm,
          ),
          child: Icon(icon, color: c, size: 18),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              if (subtitle != null)
                Text(subtitle!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Gráfico compacto de frequência (contagens reais). Estado vazio elegante
/// quando não há presenças nos últimos 7 dias.
class WeeklyFrequencyChart extends StatelessWidget {
  /// Cada item: { 'data': 'yyyy-MM-dd', 'total': int }.
  final List<Map<String, dynamic>> dados;

  const WeeklyFrequencyChart({super.key, required this.dados});

  int _val(Map<String, dynamic> e) => (e['total'] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final total = dados.fold<int>(0, (s, e) => s + _val(e));
    final maxVal = dados.fold<int>(1, (m, e) => _val(e) > m ? _val(e) : m);

    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashCardHeader(
            icon: Icons.bar_chart_rounded,
            title: 'Frequência semanal',
            subtitle: 'Últimos 7 dias',
            trailing: total == 0
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$total total',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.event_busy_rounded,
                      color: AppColors.textSecondary, size: 18),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Nenhuma presença registrada nos últimos 7 dias.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 92,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dados.map((e) {
                  final v = _val(e);
                  final ratio = maxVal > 0 ? v / maxVal : 0.0;
                  final parts = (e['data'] as String? ?? '').split('-');
                  final dia = parts.length == 3 ? parts[2] : '?';
                  final isMax = v == maxVal && v > 0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (v > 0)
                            Text('$v',
                                style: TextStyle(
                                  color: isMax
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: isMax
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                )),
                          const SizedBox(height: 3),
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: ratio.clamp(0.06, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isMax
                                      ? AppColors.primary
                                      : AppColors.primary
                                          .withValues(alpha: 0.35),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(dia,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
