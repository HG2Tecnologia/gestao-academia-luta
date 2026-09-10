import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'app_theme.dart';

/// Atalhos para leitura de tema e traduções nas telas.
///
/// Migração de cores (era `constants.dart`):
///   kBg      -> use o `Scaffold` (scaffoldBackgroundColor) ou `context.c.surface`
///   kSurface -> context.c.surfaceContainer   (cards)
///   kBorder  -> context.c.outline
///   kText1   -> context.c.onSurface
///   kText2   -> context.c.onSurfaceVariant
///   kPrimary -> context.c.primary            (preenchimentos / seleção)
///            -> context.sem.goldOnSurface    (texto/ícone dourado sobre superfície)
///   kSuccess/kWarning/kDanger -> context.sem.success/warning/danger
///   AppColors.info -> context.sem.info
extension ThemeContextX on BuildContext {
  ColorScheme get c => Theme.of(this).colorScheme;
  AppSemanticColors get sem => AppSemanticColors.of(this);
  TextTheme get texts => Theme.of(this).textTheme;
  AppLocalizations get l10n => AppLocalizations.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
