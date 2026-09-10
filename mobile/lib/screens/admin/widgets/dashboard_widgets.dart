import 'package:flutter/material.dart';
import '../../../core/theme/context_ext.dart';
import '../../../l10n/app_localizations.dart';

/// Componentes da Dashboard administrativa. Identidade preto/dourado do
/// Sensei Manager: cor só em ícones, badges, bordas e pequenos fundos
/// semânticos — sem grandes gradientes. Agora tema-aware (claro/escuro).

enum DashTone { gold, info, success, warning, danger, neutral }

extension DashToneColor on DashTone {
  Color color(BuildContext context) => switch (this) {
    DashTone.gold => context.c.primary,
    DashTone.info => context.sem.info,
    DashTone.success => context.sem.success,
    DashTone.warning => context.sem.warning,
    DashTone.danger => context.sem.danger,
    DashTone.neutral => context.c.onSurfaceVariant,
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
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 12),
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
              style: TextStyle(
                color: context.c.onSurface,
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
                    style: TextStyle(
                      color: context.c.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.c.primary,
                    size: 18,
                  ),
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
    final c = tone.color(context);
    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      excludeSemantics: true,
      child: Material(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: c, size: 19),
                    ),
                    const Spacer(),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.c.onSurfaceVariant,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 12,
                  ),
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
    final c = tone.color(context);
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: c.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 96,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
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
                      style: TextStyle(
                        color: context.c.onSurface,
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
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final border = tone == DashTone.neutral
        ? context.c.outline
        : tone.color(context).withValues(alpha: 0.30);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
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
    final c = tone.color(context);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: c, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
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
    final l = AppLocalizations.of(context);
    final total = dados.fold<int>(0, (s, e) => s + _val(e));
    final maxVal = dados.fold<int>(1, (m, e) => _val(e) > m ? _val(e) : m);

    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashCardHeader(
            icon: Icons.bar_chart_rounded,
            title: l.dashWeeklyFrequency,
            subtitle: l.dashLast7Days,
            trailing: total == 0
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.sem.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.dashTotalCount(total),
                      style: TextStyle(
                        color: context.sem.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    color: context.c.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.dashNoAttendance7Days,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
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
                            Text(
                              '$v',
                              style: TextStyle(
                                color: isMax
                                    ? context.c.primary
                                    : context.c.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: isMax
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          const SizedBox(height: 3),
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: ratio.clamp(0.06, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isMax
                                      ? context.c.primary
                                      : context.c.primary.withValues(
                                          alpha: 0.35,
                                        ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dia,
                            style: TextStyle(
                              color: context.c.onSurface,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
