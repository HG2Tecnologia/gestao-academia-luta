import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferência de idioma escolhida pelo usuário.
/// `system` = seguir o idioma do dispositivo (com fallback pt-BR).
enum LocalePref { system, pt, en }

/// Preferência de tema escolhida pelo usuário.
enum ThemePref { system, light, dark }

@immutable
class AppSettings {
  const AppSettings({
    this.localePref = LocalePref.system,
    this.themePref = ThemePref.system,
  });

  final LocalePref localePref;
  final ThemePref themePref;

  /// `null` => o Flutter resolve pelo dispositivo (ver `localeResolutionCallback`).
  Locale? get locale => switch (localePref) {
    LocalePref.pt => const Locale('pt'),
    LocalePref.en => const Locale('en'),
    LocalePref.system => null,
  };

  ThemeMode get themeMode => switch (themePref) {
    ThemePref.light => ThemeMode.light,
    ThemePref.dark => ThemeMode.dark,
    ThemePref.system => ThemeMode.system,
  };

  AppSettings copyWith({LocalePref? localePref, ThemePref? themePref}) =>
      AppSettings(
        localePref: localePref ?? this.localePref,
        themePref: themePref ?? this.themePref,
      );
}

/// Fonte única da preferência de aparência/idioma. Segue o padrão de
/// `ValueNotifier` global já usado no projeto (ver `core/tab_refresh.dart`).
/// O `MaterialApp` escuta este notifier — trocar aqui reconstrói a UI na hora.
final appSettings = ValueNotifier<AppSettings>(const AppSettings());

const _kLocaleKey = 'app_locale_pref';
const _kThemeKey = 'app_theme_pref';

LocalePref _localePrefFrom(String? v) => switch (v) {
  'pt' => LocalePref.pt,
  'en' => LocalePref.en,
  _ => LocalePref.system,
};

ThemePref _themePrefFrom(String? v) => switch (v) {
  'light' => ThemePref.light,
  'dark' => ThemePref.dark,
  _ => ThemePref.system,
};

String _localePrefName(LocalePref p) => p.name;
String _themePrefName(ThemePref p) => p.name;

/// Lê as preferências salvas. Chamar em `main()` antes de `runApp` para não
/// haver flash de tema/idioma errado.
Future<void> loadAppSettings() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    appSettings.value = AppSettings(
      localePref: _localePrefFrom(prefs.getString(_kLocaleKey)),
      themePref: _themePrefFrom(prefs.getString(_kThemeKey)),
    );
  } catch (_) {
    // Sem persistência disponível: mantém o default (system/system).
  }
}

Future<void> setLocalePref(LocalePref pref) async {
  appSettings.value = appSettings.value.copyWith(localePref: pref);
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, _localePrefName(pref));
  } catch (_) {}
}

Future<void> setThemePref(ThemePref pref) async {
  appSettings.value = appSettings.value.copyWith(themePref: pref);
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, _themePrefName(pref));
  } catch (_) {}
}

/// Resolve o locale efetivo dado o que o dispositivo oferece.
/// Regra: preferência explícita vence; senão usa o 1º locale do device que o
/// app suporta; senão cai para pt-BR (o produto nasceu em português).
Locale resolveLocale(
  Iterable<Locale>? deviceLocales,
  Iterable<Locale> supported,
) {
  final pref = appSettings.value.locale;
  if (pref != null) {
    return supported.firstWhere(
      (l) => l.languageCode == pref.languageCode,
      orElse: () => supported.first,
    );
  }
  for (final d in deviceLocales ?? const <Locale>[]) {
    for (final s in supported) {
      if (s.languageCode == d.languageCode) return s;
    }
  }
  return const Locale('pt', 'BR');
}
