import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'theme/context_ext.dart';

/// Controles reutilizáveis de aparência (tema) e idioma.
///
/// - [AppearanceSettingsCard]: bloco para telas de perfil (aluno / professor),
///   equivalente ao que o admin tem em Configurações.
/// - [PreLoginAppearanceBar]: barra compacta com um seletor PT/EN e um botão
///   sol/lua, para as telas antes do login. A escolha é salva em
///   [appSettings] (SharedPreferences) e permanece após o login.

String languagePrefLabel(BuildContext context) {
  final l = context.l10n;
  return switch (appSettings.value.localePref) {
    LocalePref.pt => l.settingsLanguagePt,
    LocalePref.en => l.settingsLanguageEn,
    LocalePref.system => l.settingsOptionSystem,
  };
}

String themePrefLabel(BuildContext context) {
  final l = context.l10n;
  return switch (appSettings.value.themePref) {
    ThemePref.light => l.settingsThemeLight,
    ThemePref.dark => l.settingsThemeDark,
    ThemePref.system => l.settingsOptionSystem,
  };
}

Future<void> showLanguageSheet(BuildContext context) {
  final l = context.l10n;
  return _showOptionSheet(
    context,
    titulo: l.settingsLanguageSheetTitle,
    selecionada: appSettings.value.localePref.name,
    opcoes: [
      _Opcao(
        'system',
        l.settingsOptionSystem,
        l.settingsOptionSystemLanguageHint,
        Icons.smartphone_rounded,
      ),
      _Opcao('pt', l.settingsLanguagePt, null, Icons.translate_rounded),
      _Opcao('en', l.settingsLanguageEn, null, Icons.translate_rounded),
    ],
    onSelecionar: (v) => setLocalePref(switch (v) {
      'pt' => LocalePref.pt,
      'en' => LocalePref.en,
      _ => LocalePref.system,
    }),
  );
}

Future<void> showThemeSheet(BuildContext context) {
  final l = context.l10n;
  return _showOptionSheet(
    context,
    titulo: l.settingsThemeSheetTitle,
    selecionada: appSettings.value.themePref.name,
    opcoes: [
      _Opcao(
        'system',
        l.settingsOptionSystem,
        l.settingsOptionSystemThemeHint,
        Icons.smartphone_rounded,
      ),
      _Opcao('light', l.settingsThemeLight, null, Icons.light_mode_rounded),
      _Opcao('dark', l.settingsThemeDark, null, Icons.dark_mode_rounded),
    ],
    onSelecionar: (v) => setThemePref(switch (v) {
      'light' => ThemePref.light,
      'dark' => ThemePref.dark,
      _ => ThemePref.system,
    }),
  );
}

/// Card com duas linhas (Idioma / Tema) para telas de perfil.
class AppearanceSettingsCard extends StatelessWidget {
  const AppearanceSettingsCard({super.key, this.showSectionTitle = true});

  /// Quando `true`, imprime o título/subtítulo de seção acima do card.
  final bool showSectionTitle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        final card = Container(
          decoration: BoxDecoration(
            color: context.c.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.c.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Row(
                icon: Icons.translate_rounded,
                titulo: l.settingsLanguage,
                valor: languagePrefLabel(context),
                onTap: () => showLanguageSheet(context),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Divider(height: 1, color: context.c.outline),
              ),
              _Row(
                icon: Icons.brightness_6_rounded,
                titulo: l.settingsTheme,
                valor: themePrefLabel(context),
                onTap: () => showThemeSheet(context),
              ),
            ],
          ),
        );
        if (!showSectionTitle) return card;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.settingsAppearanceSection,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l.settingsAppearanceSubtitle,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 12),
            card,
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.titulo,
    required this.valor,
    required this.onTap,
  });
  final IconData icon;
  final String titulo;
  final String valor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.c.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: context.c.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                valor,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: context.c.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra compacta para telas de pré-login: seletor PT/EN + botão sol/lua.
class PreLoginAppearanceBar extends StatelessWidget {
  const PreLoginAppearanceBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        final s = appSettings.value;
        // Tema efetivo (considera "Automático").
        final isDark = switch (s.themePref) {
          ThemePref.dark => true,
          ThemePref.light => false,
          ThemePref.system =>
            MediaQuery.platformBrightnessOf(context) == Brightness.dark,
        };
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangPill(pref: s.localePref),
            const SizedBox(width: 8),
            _IconToggle(
              icon: isDark
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              tooltip: context.l10n.settingsTheme,
              onTap: () => setThemePref(
                isDark ? ThemePref.light : ThemePref.dark,
              ),
              onLongPress: () => showThemeSheet(context),
            ),
          ],
        );
      },
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({required this.pref});
  final LocalePref pref;

  @override
  Widget build(BuildContext context) {
    // Idioma efetivo p/ destacar o segmento correto quando em "Automático".
    final effective = switch (pref) {
      LocalePref.pt => 'pt',
      LocalePref.en => 'en',
      LocalePref.system =>
        Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'pt',
    };
    Widget seg(String code, String label) {
      final sel = effective == code;
      return GestureDetector(
        onTap: () => setLocalePref(
          code == 'pt' ? LocalePref.pt : LocalePref.en,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? context.c.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: sel ? context.c.onPrimary : context.c.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: context.l10n.settingsLanguage,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.c.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.c.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [seg('pt', 'PT'), seg('en', 'EN')],
        ),
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  const _IconToggle({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.onLongPress,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.c.surfaceContainer,
        shape: CircleBorder(side: BorderSide(color: context.c.outline)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: context.c.primary, size: 18),
          ),
        ),
      ),
    );
  }
}

// ── Bottom sheet de opções (compartilhado) ──────────────────────────────────

class _Opcao {
  const _Opcao(this.valor, this.titulo, this.hint, this.icone);
  final String valor;
  final String titulo;
  final String? hint;
  final IconData icone;
}

Future<void> _showOptionSheet(
  BuildContext context, {
  required String titulo,
  required List<_Opcao> opcoes,
  required String selecionada,
  required Future<void> Function(String) onSelecionar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OptionSheet(
      titulo: titulo,
      opcoes: opcoes,
      selecionada: selecionada,
      onSelecionar: onSelecionar,
    ),
  );
}

class _OptionSheet extends StatefulWidget {
  const _OptionSheet({
    required this.titulo,
    required this.opcoes,
    required this.selecionada,
    required this.onSelecionar,
  });
  final String titulo;
  final List<_Opcao> opcoes;
  final String selecionada;
  final Future<void> Function(String) onSelecionar;

  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  late String _sel = widget.selecionada;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.c.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.titulo,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            ...widget.opcoes.map((o) {
              final sel = o.valor == _sel;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: sel
                      ? context.c.primary.withValues(alpha: 0.12)
                      : context.c.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final nav = Navigator.of(context);
                      setState(() => _sel = o.valor);
                      await widget.onSelecionar(o.valor);
                      if (mounted) nav.pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? context.c.primary : context.c.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            o.icone,
                            size: 20,
                            color: sel
                                ? context.c.primary
                                : context.c.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  o.titulo,
                                  style: TextStyle(
                                    color: context.c.onSurface,
                                    fontSize: 14,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                if (o.hint != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    o.hint!,
                                    style: TextStyle(
                                      color: context.c.onSurfaceVariant,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (sel)
                            Icon(
                              Icons.check_rounded,
                              color: context.c.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
