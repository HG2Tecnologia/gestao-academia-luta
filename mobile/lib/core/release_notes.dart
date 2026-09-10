import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Tipo da novidade — mapeia para uma tag colorida e um rótulo localizado.
enum ReleaseTag { neu, improvement, fix }

/// Para quem a novidade é relevante.
///
///  * [all] — todos os perfis (inclui o aluno). Só coisas que **não** são
///    regra de negócio da academia (visual, tema, idioma).
///  * [academyOnly] — apenas academia/professor (gestão).
enum ReleaseAudience { all, academyOnly }

/// Quem está vendo o modal. [student] enxerga só entradas [ReleaseAudience.all];
/// [academy] enxerga tudo.
enum ReleaseViewer { student, academy }

/// Uma novidade dentro de uma versão. Título e descrição são resolvidos via
/// [AppLocalizations] no momento da exibição — nada de string fixa aqui.
@immutable
class ReleaseEntry {
  final IconData icon;
  final ReleaseTag tag;
  final ReleaseAudience audience;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) description;

  const ReleaseEntry({
    required this.icon,
    required this.tag,
    required this.audience,
    required this.title,
    required this.description,
  });

  bool visibleTo(ReleaseViewer viewer) =>
      viewer == ReleaseViewer.academy || audience == ReleaseAudience.all;
}

/// Conjunto de novidades de uma versão.
@immutable
class AppReleaseNotes {
  final String version;
  final List<ReleaseEntry> entries;

  const AppReleaseNotes({required this.version, required this.entries});

  /// Entradas visíveis para [viewer], já na ordem de exibição.
  List<ReleaseEntry> entriesFor(ReleaseViewer viewer) =>
      entries.where((e) => e.visibleTo(viewer)).toList(growable: false);
}

/// Notas por versão. A chave é a versão do `pubspec.yaml` (`PackageInfo.version`,
/// sem o `+build`). Versões sem entrada aqui simplesmente não mostram modal.
///
/// Ao publicar uma nova versão: adicione uma entrada nova; não altere as antigas.
final Map<String, AppReleaseNotes> _releaseNotesByVersion = {
  '1.3.0': AppReleaseNotes(
    version: '1.3.0',
    entries: [
      ReleaseEntry(
        icon: Icons.light_mode_rounded,
        tag: ReleaseTag.neu,
        audience: ReleaseAudience.all,
        title: (l) => l.rnLightThemeTitle,
        description: (l) => l.rnLightThemeDesc,
      ),
      ReleaseEntry(
        icon: Icons.language_rounded,
        tag: ReleaseTag.neu,
        audience: ReleaseAudience.all,
        title: (l) => l.rnLanguageTitle,
        description: (l) => l.rnLanguageDesc,
      ),
      // Redesign — texto diferente para aluno e academia; só um aparece por
      // viewer graças ao audience.
      ReleaseEntry(
        icon: Icons.auto_awesome_rounded,
        tag: ReleaseTag.improvement,
        audience: ReleaseAudience.all,
        title: (l) => l.rnRedesignStudentTitle,
        description: (l) => l.rnRedesignStudentDesc,
      ),
      ReleaseEntry(
        icon: Icons.auto_awesome_rounded,
        tag: ReleaseTag.improvement,
        audience: ReleaseAudience.academyOnly,
        title: (l) => l.rnRedesignAcademyTitle,
        description: (l) => l.rnRedesignAcademyDesc,
      ),
      ReleaseEntry(
        icon: Icons.login_rounded,
        tag: ReleaseTag.neu,
        audience: ReleaseAudience.academyOnly,
        title: (l) => l.rnSignInTitle,
        description: (l) => l.rnSignInDesc,
      ),
      ReleaseEntry(
        icon: Icons.lock_reset_rounded,
        tag: ReleaseTag.neu,
        audience: ReleaseAudience.academyOnly,
        title: (l) => l.rnPasswordTitle,
        description: (l) => l.rnPasswordDesc,
      ),
      ReleaseEntry(
        icon: Icons.workspace_premium_rounded,
        tag: ReleaseTag.improvement,
        audience: ReleaseAudience.academyOnly,
        title: (l) => l.rnClassesTitle,
        description: (l) => l.rnClassesDesc,
      ),
      ReleaseEntry(
        icon: Icons.payments_rounded,
        tag: ReleaseTag.improvement,
        audience: ReleaseAudience.academyOnly,
        title: (l) => l.rnBillingTitle,
        description: (l) => l.rnBillingDesc,
      ),
    ],
  ),
};

/// Notas da [version] instalada, ou `null` se não houver nada a anunciar.
AppReleaseNotes? releaseNotesFor(String version) =>
    _releaseNotesByVersion[version];

/// Notas mais recentes cadastradas (maior versão semântica). Usado só na
/// abertura **manual** — nunca no disparo automático, que exige match exato
/// com a versão instalada.
AppReleaseNotes? latestReleaseNotes() {
  if (_releaseNotesByVersion.isEmpty) return null;
  final versions = _releaseNotesByVersion.keys.toList()
    ..sort(_compareSemver);
  return _releaseNotesByVersion[versions.last];
}

int _compareSemver(String a, String b) {
  final pa = a.split('.').map((x) => int.tryParse(x) ?? 0).toList();
  final pb = b.split('.').map((x) => int.tryParse(x) ?? 0).toList();
  for (var i = 0; i < 3; i++) {
    final da = i < pa.length ? pa[i] : 0;
    final db = i < pb.length ? pb[i] : 0;
    if (da != db) return da.compareTo(db);
  }
  return 0;
}

/// Mapeia o nome de perfil armazenado para quem enxerga o modal.
ReleaseViewer releaseViewerForRole(String? perfil) =>
    perfil == 'Aluno' ? ReleaseViewer.student : ReleaseViewer.academy;

/// Só para o teste conseguir enumerar as versões cadastradas.
Iterable<String> get knownReleaseNoteVersions => _releaseNotesByVersion.keys;
