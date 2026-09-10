import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_storage.dart';
import 'release_notes.dart';
import 'theme/context_ext.dart';

/// Modal "Novidades da versão" — componente único que herda tema e idioma do
/// app (nada de variante Dark/Light nem Pt/En). O conteúdo vem de
/// [releaseNotesFor] em `release_notes.dart`; a versão vem do `PackageInfo`.
abstract final class WhatsNewService {
  static const _prefKey = 'whats_new_last_seen_version';

  /// Chamado no `initState` dos shells. Mostra o modal uma única vez por versão
  /// (compara com a última versão vista, salva no fim).
  static Future<void> checkAndShow(
    BuildContext context, {
    required ReleaseViewer viewer,
  }) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version;
      final notes = releaseNotesFor(version);
      if (notes == null) return;
      if (notes.entriesFor(viewer).isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_prefKey) == version) return;

      if (!context.mounted) return;
      await _show(context, notes: notes, viewer: viewer);

      await prefs.setString(_prefKey, version);
    } catch (_) {
      // PackageInfo/prefs indisponível — nunca bloqueia o uso do app.
    }
  }

  /// Abertura manual (perfil / configurações / notícias). Mostra mesmo que a
  /// versão já tenha sido vista e não altera a persistência. Se a versão
  /// instalada não tiver notas cadastradas, cai nas notas mais recentes — assim
  /// o botão nunca fica "morto".
  static Future<void> showManually(
    BuildContext context, {
    required ReleaseViewer viewer,
  }) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final notes = releaseNotesFor(info.version) ?? latestReleaseNotes();
      if (notes == null || notes.entriesFor(viewer).isEmpty) return;
      if (!context.mounted) return;
      await _show(context, notes: notes, viewer: viewer);
    } catch (_) {
      /* silencioso */
    }
  }

  /// `true` se há notas para exibir manualmente para [viewer] (usado por
  /// widgets que se escondem quando não há nada).
  static bool hasNotesFor(ReleaseViewer viewer) {
    final notes = latestReleaseNotes();
    return notes != null && notes.entriesFor(viewer).isNotEmpty;
  }

  static Future<void> _show(
    BuildContext context, {
    required AppReleaseNotes notes,
    required ReleaseViewer viewer,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReleaseNotesDialog(notes: notes, viewer: viewer),
    );
  }
}

/// Tile reutilizável para abrir o modal manualmente. Some sozinho se não houver
/// novidades cadastradas para a versão instalada.
class ReleaseNotesMenuTile extends StatelessWidget {
  const ReleaseNotesMenuTile({super.key, required this.viewer});

  final ReleaseViewer viewer;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Material(
      color: context.c.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => WhatsNewService.showManually(context, viewer: viewer),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: context.sem.goldOnSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.rnMenuEntry,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.c.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card fixo no topo da tela de Notícias / avisos — dá um caminho de volta ao
/// modal caso o usuário feche sem querer. Resolve o público pelo perfil logado
/// quando [viewer] não é informado, e some sozinho se não houver novidades.
class ReleaseNotesNewsCard extends StatefulWidget {
  const ReleaseNotesNewsCard({super.key, this.viewer});

  final ReleaseViewer? viewer;

  @override
  State<ReleaseNotesNewsCard> createState() => _ReleaseNotesNewsCardState();
}

class _ReleaseNotesNewsCardState extends State<ReleaseNotesNewsCard> {
  ReleaseViewer? _viewer;

  @override
  void initState() {
    super.initState();
    _viewer = widget.viewer;
    if (_viewer == null) _resolve();
  }

  Future<void> _resolve() async {
    try {
      final user = await AuthStorage.getUser();
      if (mounted) {
        setState(() => _viewer = releaseViewerForRole(user?.perfil));
      }
    } catch (_) {
      if (mounted) setState(() => _viewer = ReleaseViewer.academy);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewer = _viewer;
    if (viewer == null || !WhatsNewService.hasNotesFor(viewer)) {
      return const SizedBox.shrink();
    }
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.sem.goldContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () =>
              WhatsNewService.showManually(context, viewer: viewer),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.c.primary.withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: context.sem.goldOnSurface,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.rnMenuEntry,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.rnNewsCardHint,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.c.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReleaseNotesDialog extends StatelessWidget {
  const _ReleaseNotesDialog({required this.notes, required this.viewer});

  final AppReleaseNotes notes;
  final ReleaseViewer viewer;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final entries = notes.entriesFor(viewer);
    final media = MediaQuery.of(context);

    void close() => Navigator.of(context).maybePop();

    return Dialog(
      backgroundColor: context.c.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: media.size.height * 0.86,
        ),
        child: Semantics(
          container: true,
          label: l.rnA11yTitle(notes.version),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(version: notes.version, onClose: close),
              Divider(height: 1, color: context.c.outlineVariant),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  itemCount: entries.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i == entries.length) return const _FooterCard();
                    return _ReleaseCard(entry: entries[i]);
                  },
                ),
              ),
              _Cta(onPressed: close),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.version, required this.onClose});

  final String version;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.sem.goldContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.rnBadgeVersion(version),
                  style: TextStyle(
                    color: context.sem.goldOnSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                tooltip: l.rnClose,
                icon: Icon(
                  Icons.close_rounded,
                  color: context.c.onSurfaceVariant,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.rnTitle,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.rnSubtitle,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.sem.goldContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: context.sem.goldOnSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({required this.entry});

  final ReleaseEntry entry;

  ({Color color, String label}) _tag(BuildContext context) {
    final l = context.l10n;
    switch (entry.tag) {
      case ReleaseTag.neu:
        return (color: context.sem.info, label: l.rnTagNew);
      case ReleaseTag.improvement:
        return (color: context.sem.success, label: l.rnTagImprovement);
      case ReleaseTag.fix:
        return (color: context.sem.warning, label: l.rnTagFix);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tag = _tag(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.c.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.c.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tag.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(entry.icon, color: tag.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tag.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag.label,
                    style: TextStyle(
                      color: tag.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.title(l),
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.description(l),
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterCard extends StatelessWidget {
  const _FooterCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.sem.goldContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.primary.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.favorite_rounded,
            color: context.sem.goldOnSurface,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.rnFooterTitle,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l.rnFooterBody,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: context.c.primary,
            foregroundColor: context.c.onPrimary,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            context.l10n.rnCta,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
