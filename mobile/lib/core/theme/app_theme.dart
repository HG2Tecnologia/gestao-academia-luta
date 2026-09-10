import 'package:flutter/material.dart';

/// Cores semânticas e de marca que não pertencem ao [ColorScheme] do Material.
///
/// Verde = sucesso/pago/ativo/presente · Vermelho = erro/atrasado/exclusão ·
/// Âmbar = atenção/pendente · Azul = informação · Dourado = marca/seleção.
/// O significado é o MESMO nos dois temas — só o tom muda para manter contraste.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
    required this.info,
    required this.onInfo,

    /// Dourado da marca em superfícies preenchidas (botões, badges). É o mesmo
    /// hex nos dois temas — é a identidade.
    required this.brandGold,

    /// Dourado para texto/ícone/label sobre fundo claro (o dourado puro perde
    /// contraste no branco). No dark é igual a [brandGold].
    required this.goldOnSurface,

    /// Container dourado translúcido (chips/realces).
    required this.goldContainer,

    /// Fallback neutro para graduações sem cor cadastrada. NUNCA usar a cor da
    /// marca aqui.
    required this.graduationNeutral,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;
  final Color info;
  final Color onInfo;
  final Color brandGold;
  final Color goldOnSurface;
  final Color goldContainer;
  final Color graduationNeutral;

  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>() ?? _dark;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? danger,
    Color? onDanger,
    Color? info,
    Color? onInfo,
    Color? brandGold,
    Color? goldOnSurface,
    Color? goldContainer,
    Color? graduationNeutral,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      brandGold: brandGold ?? this.brandGold,
      goldOnSurface: goldOnSurface ?? this.goldOnSurface,
      goldContainer: goldContainer ?? this.goldContainer,
      graduationNeutral: graduationNeutral ?? this.graduationNeutral,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      brandGold: Color.lerp(brandGold, other.brandGold, t)!,
      goldOnSurface: Color.lerp(goldOnSurface, other.goldOnSurface, t)!,
      goldContainer: Color.lerp(goldContainer, other.goldContainer, t)!,
      graduationNeutral: Color.lerp(
        graduationNeutral,
        other.graduationNeutral,
        t,
      )!,
    );
  }

  static const _dark = AppSemanticColors(
    success: Color(0xFF22C55E),
    onSuccess: Color(0xFF04140A),
    warning: Color(0xFFF59E0B),
    onWarning: Color(0xFF1A1200),
    danger: Color(0xFFEF4444),
    onDanger: Color(0xFF1A0303),
    info: Color(0xFF0EA5E9),
    onInfo: Color(0xFF03131C),
    brandGold: Color(0xFFC9A020),
    goldOnSurface: Color(0xFFD9B54A),
    goldContainer: Color(0x1FC9A020),
    graduationNeutral: Color(0xFF3A3A3A),
  );

  static const _light = AppSemanticColors(
    success: Color(0xFF15803D),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFB45309),
    onWarning: Color(0xFFFFFFFF),
    danger: Color(0xFFDC2626),
    onDanger: Color(0xFFFFFFFF),
    info: Color(0xFF0369A1),
    onInfo: Color(0xFFFFFFFF),
    brandGold: Color(0xFFC9A020),
    goldOnSurface: Color(0xFF8A6D0F),
    goldContainer: Color(0x24C9A020),
    graduationNeutral: Color(0xFFBDBDBD),
  );
}

/// Fábrica dos dois temas do Sensei Manager. Dourado é a marca nos dois modos.
abstract final class AppTheme {
  static const _gold = Color(0xFFC9A020);

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: _gold,
      onPrimary: Color(0xFF1A1400),
      primaryContainer: Color(0xFF3A2E00),
      onPrimaryContainer: Color(0xFFF0D98A),
      secondary: _gold,
      onSecondary: Color(0xFF1A1400),
      surface: Color(0xFF0A0A0A),
      onSurface: Color(0xFFF8FAFC),
      onSurfaceVariant: Color(0xFFA0A0A0),
      surfaceContainerLowest: Color(0xFF080808),
      surfaceContainerLow: Color(0xFF121212),
      surfaceContainer: Color(0xFF161616),
      surfaceContainerHigh: Color(0xFF1E1E1E),
      surfaceContainerHighest: Color(0xFF242424),
      outline: Color(0xFF282828),
      outlineVariant: Color(0xFF1F1F1F),
      error: Color(0xFFEF4444),
      onError: Color(0xFF1A0303),
      inverseSurface: Color(0xFFF8FAFC),
      onInverseSurface: Color(0xFF161616),
    ),
    semantic: AppSemanticColors._dark,
    scaffold: const Color(0xFF0A0A0A),
  );

  static ThemeData light() => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: _gold,
      onPrimary: Color(0xFF1A1400),
      primaryContainer: Color(0xFFF5E7B8),
      onPrimaryContainer: Color(0xFF4A3B00),
      secondary: Color(0xFF8A6D0F),
      onSecondary: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A1A1A),
      onSurfaceVariant: Color(0xFF5A5A5A),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF7F7F4),
      surfaceContainer: Color(0xFFF2F2EE),
      surfaceContainerHigh: Color(0xFFECECE7),
      surfaceContainerHighest: Color(0xFFE6E6E0),
      outline: Color(0xFFD8D8D2),
      outlineVariant: Color(0xFFE8E8E2),
      error: Color(0xFFDC2626),
      onError: Color(0xFFFFFFFF),
      inverseSurface: Color(0xFF2A2A2A),
      onInverseSurface: Color(0xFFF5F5F0),
    ),
    semantic: AppSemanticColors._light,
    scaffold: const Color(0xFFFAFAF8),
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required AppSemanticColors semantic,
    required Color scaffold,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      extensions: [semantic],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        actionTextColor: scheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return Colors.white;
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.all(scheme.outline),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(const TextStyle(fontSize: 12.5)),
        ),
      ),
    );
  }
}
