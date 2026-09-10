import 'package:flutter/material.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../core/firestore_service.dart';

class AdminGruposFamiliaresScreen extends StatefulWidget {
  const AdminGruposFamiliaresScreen({super.key});

  @override
  State<AdminGruposFamiliaresScreen> createState() =>
      _AdminGruposFamiliaresScreenState();
}

class _AdminGruposFamiliaresScreenState
    extends State<AdminGruposFamiliaresScreen> {
  List<Map<String, dynamic>> _grupos = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;
      final list = await firestoreService.getGruposFamiliares(academiaId);
      if (mounted) setState(() => _grupos = list);
    } catch (e) {
      if (mounted) setState(() => _erro = context.l10n.famLoadError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _criarGrupo() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          context.l10n.famNewGroup,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: context.c.onSurface),
          decoration: InputDecoration(
            labelText: context.l10n.famGroupNameHint,
            labelStyle: TextStyle(color: context.c.onSurfaceVariant),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.c.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.c.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.l10n.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.famCreate,
              style: TextStyle(
                color: context.c.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty || !mounted) return;
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;
      await firestoreService.addGrupoFamiliar(academiaId, {
        'nome': ctrl.text.trim(),
      });
      await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.famCreateError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _renomear(Map<String, dynamic> grupo) async {
    final ctrl = TextEditingController(text: grupo['nome'] as String? ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          context.l10n.famRename,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: context.c.onSurface),
          decoration: InputDecoration(
            labelText: context.l10n.sdName,
            labelStyle: TextStyle(color: context.c.onSurfaceVariant),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.c.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.c.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.l10n.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.commonSave,
              style: TextStyle(
                color: context.c.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty || !mounted) return;
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;
      await firestoreService.updateGrupoFamiliar(
        academiaId,
        grupo['id'] as String,
        {'nome': ctrl.text.trim()},
      );
      await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.famRenameError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _excluir(Map<String, dynamic> grupo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          context.l10n.famDeleteTitle,
          style: TextStyle(color: context.c.onSurface),
        ),
        content: Text(
          context.l10n.famDeleteBody,
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.l10n.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.commonDelete,
              style: TextStyle(
                color: context.sem.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;
      await firestoreService.deleteGrupoFamiliar(
        academiaId,
        grupo['id'] as String,
      );
      await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.famDeleteError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _removerMembro(
    String grupoId,
    Map<String, dynamic> membro,
  ) async {
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;
      await firestoreService.removerMembroGrupo(
        academiaId,
        grupoId,
        membro['id'] as String,
      );
      await _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${membro['nome']} removido do grupo.'),
            backgroundColor: context.sem.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.famRemoveMemberError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        elevation: 0,
        title: Text(
          context.l10n.famTitle,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _criarGrupo,
            icon: Icon(Icons.add_rounded, color: context.c.primary),
            tooltip: context.l10n.famNewGroupShort,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.c.primary))
          : _erro != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _erro!,
                    style: TextStyle(color: context.sem.danger, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _load,
                    child: Text(
                      context.l10n.commonRetry,
                      style: TextStyle(color: context.c.primary),
                    ),
                  ),
                ],
              ),
            )
          : _grupos.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _grupos.length,
                itemBuilder: (_, i) => _buildGrupoCard(_grupos[i]),
              ),
            ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.family_restroom_rounded,
          size: 56,
          color: context.c.onSurfaceVariant.withOpacity(0.4),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.famEmpty,
          style: TextStyle(
            color: context.c.onSurfaceVariant,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.famEmptyHint,
          style: TextStyle(
            color: context.c.onSurfaceVariant.withOpacity(0.7),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _criarGrupo,
          icon: Icon(Icons.add_rounded, size: 18),
          label: Text(context.l10n.famCreateGroup),
          style: FilledButton.styleFrom(backgroundColor: context.c.primary),
        ),
      ],
    ),
  );

  Widget _buildGrupoCard(Map<String, dynamic> grupo) {
    final membros = (grupo['membros'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.c.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.family_restroom_rounded,
                    color: context.c.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grupo['nome'] as String? ?? '',
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${membros.length} membro${membros.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: context.c.surfaceContainer,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: context.c.onSurfaceVariant,
                  ),
                  onSelected: (v) {
                    if (v == 'renomear') _renomear(grupo);
                    if (v == 'excluir') _excluir(grupo);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'renomear',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: context.c.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(context.l10n.famRenameShort),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: context.sem.danger,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.l10n.commonDelete,
                            style: TextStyle(color: context.sem.danger),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (membros.isNotEmpty) ...[
            const Divider(height: 1),
            ...membros.map(
              (m) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: context.c.primary.withOpacity(0.15),
                  child: Text(
                    (m['nome'] as String? ?? '')
                        .split(' ')
                        .take(2)
                        .map((w) => w.isNotEmpty ? w[0] : '')
                        .join()
                        .toUpperCase(),
                    style: TextStyle(
                      color: context.c.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                title: Text(
                  m['nome'] as String? ?? '',
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  m['perfil'] as String? ?? '',
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.link_off_rounded,
                    color: context.c.onSurfaceVariant,
                    size: 18,
                  ),
                  tooltip: context.l10n.famRemoveFromGroup,
                  onPressed: () => _removerMembro(grupo['id'] as String, m),
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                context.l10n.famNoMembers,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
