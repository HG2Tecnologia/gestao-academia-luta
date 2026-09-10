import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/firestore_service.dart';

class AdminNoticiasScreen extends StatefulWidget {
  const AdminNoticiasScreen({super.key});

  @override
  State<AdminNoticiasScreen> createState() => _AdminNoticiasScreenState();
}

class _AdminNoticiasScreenState extends State<AdminNoticiasScreen> {
  AppLocalizations get _l => context.l10n;
  List<Map<String, dynamic>> _noticias = [];
  bool _loading = true;
  String? _academiaId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId ?? '';
      if (_academiaId!.isEmpty) return;
      // getNoticias without publicadasOnly loads all (including drafts)
      final dados = await firestoreService.getNoticias(_academiaId!);
      final list = dados.cast<Map<String, dynamic>>();
      // Sort by created_at / publicada_em desc
      list.sort((a, b) {
        final da = a['publicada_em'] ?? a['created_at'] ?? '';
        final db = b['publicada_em'] ?? b['created_at'] ?? '';
        return db.toString().compareTo(da.toString());
      });
      if (mounted) setState(() => _noticias = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publicar(Map<String, dynamic> n) async {
    if (_academiaId == null) return;
    try {
      await firestoreService.updateNoticia(_academiaId!, n['id'].toString(), {
        'publicada': true,
        'publicada_em': DateTime.now().toUtc().toIso8601String(),
      });
      await _carregar();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.newsPublished),
            backgroundColor: context.sem.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.newsPublishError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _excluir(Map<String, dynamic> n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.newsDeleteTitle,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          _l.newsDeleteBody,
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _l.commonDelete,
              style: TextStyle(
                color: context.sem.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.deleteNoticia(_academiaId!, n['id'].toString());
      await _carregar();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.newsDeleteError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _abrirFormulario([Map<String, dynamic>? noticia]) async {
    if (_academiaId == null) return;
    // Full noticia data is already loaded in the list; no need for extra GET
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NoticiaFormScreen(
          academiaId: _academiaId!,
          noticia: noticia,
          onSalvo: _carregar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        title: Text(
          _l.menuNews,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: context.c.primary),
            onPressed: () => _abrirFormulario(),
            tooltip: _l.newsNew,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: _noticias.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context).newsEmpty,
                        style: TextStyle(color: context.c.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _noticias.length,
                      itemBuilder: (context, index) {
                        final n = _noticias[index];
                        final publicada = n['publicada'] == true;
                        final publicadaEm =
                            n['publicada_em'] as String? ??
                            n['publicadaEm'] as String?;
                        DateTime? data;
                        if (publicadaEm != null) {
                          try {
                            data = DateTime.parse(publicadaEm).toLocal();
                          } catch (_) {}
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.c.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.c.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: publicada
                                          ? context.sem.success.withOpacity(
                                              0.12,
                                            )
                                          : context.sem.warning.withOpacity(
                                              0.12,
                                            ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      publicada
                                          ? _l.newsStatusPublished
                                          : _l.newsStatusDraft,
                                      style: TextStyle(
                                        color: publicada
                                            ? context.sem.success
                                            : context.sem.warning,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (data != null)
                                    Text(
                                      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                                      style: TextStyle(
                                        color: context.c.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                n['titulo'] as String? ?? '',
                                style: TextStyle(
                                  color: context.c.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n['resumo'] as String? ?? '',
                                style: TextStyle(
                                  color: context.c.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (!publicada) ...[
                                    _ActionBtn(
                                      label: _l.newsPublish,
                                      icon: Icons.send_rounded,
                                      color: context.sem.success,
                                      onTap: () => _publicar(n),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  _ActionBtn(
                                    label: _l.commonEdit,
                                    icon: Icons.edit_outlined,
                                    color: context.c.primary,
                                    onTap: () => _abrirFormulario(n),
                                  ),
                                  const SizedBox(width: 8),
                                  _ActionBtn(
                                    label: _l.commonDelete,
                                    icon: Icons.delete_outline_rounded,
                                    color: context.sem.danger,
                                    onTap: () => _excluir(n),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticiaFormScreen extends StatefulWidget {
  final String academiaId;
  final Map<String, dynamic>? noticia;
  final VoidCallback onSalvo;
  const _NoticiaFormScreen({
    required this.academiaId,
    this.noticia,
    required this.onSalvo,
  });

  @override
  State<_NoticiaFormScreen> createState() => _NoticiaFormScreenState();
}

class _NoticiaFormScreenState extends State<_NoticiaFormScreen> {
  AppLocalizations get _l => context.l10n;
  final _tituloCtrl = TextEditingController();
  final _resumoCtrl = TextEditingController();
  final _conteudoCtrl = TextEditingController();
  String? _imagemBase64;
  bool _publicarAgora = true;
  bool _salvando = false;

  bool get _editando => widget.noticia != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      _tituloCtrl.text = widget.noticia!['titulo'] as String? ?? '';
      _resumoCtrl.text = widget.noticia!['resumo'] as String? ?? '';
      _conteudoCtrl.text = widget.noticia!['conteudo'] as String? ?? '';
      _imagemBase64 =
          widget.noticia!['imagem_base64'] as String? ??
          widget.noticia!['imagemBase64'] as String?;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _resumoCtrl.dispose();
    _conteudoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImagem() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    if (bytes.length > 3 * 1024 * 1024) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.newsImageTooLarge),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    setState(() => _imagemBase64 = base64Encode(bytes));
  }

  Future<void> _salvar() async {
    if (_tituloCtrl.text.trim().isEmpty || _resumoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l.newsTitleSummaryRequired),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      if (_editando) {
        await firestoreService.updateNoticia(
          widget.academiaId,
          widget.noticia!['id'].toString(),
          {
            'titulo': _tituloCtrl.text.trim(),
            'resumo': _resumoCtrl.text.trim(),
            'conteudo': _conteudoCtrl.text.trim().isNotEmpty
                ? _conteudoCtrl.text.trim()
                : null,
            'imagem_base64': _imagemBase64,
          },
        );
      } else {
        await firestoreService.addNoticia(widget.academiaId, {
          'titulo': _tituloCtrl.text.trim(),
          'resumo': _resumoCtrl.text.trim(),
          'conteudo': _conteudoCtrl.text.trim().isNotEmpty
              ? _conteudoCtrl.text.trim()
              : null,
          'imagem_base64': _imagemBase64,
          'publicada': _publicarAgora,
          if (_publicarAgora) 'publicada_em': now,
          'created_at': now,
        });
      }
      widget.onSalvo();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.newsSaveError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        title: Text(
          _editando ? _l.newsEditTitle : _l.newsNewTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _l.commonSave,
                    style: TextStyle(
                      color: context.c.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImagem,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: context.c.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.c.outline),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imagemBase64 != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Builder(
                            builder: (_) {
                              try {
                                return Image.memory(
                                  base64Decode(_imagemBase64!),
                                  fit: BoxFit.cover,
                                );
                              } catch (_) {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              onTap: () => setState(() => _imagemBase64 = null),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: context.c.onSurfaceVariant,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _l.newsAddImage,
                            style: TextStyle(
                              color: context.c.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            _campo(_tituloCtrl, _l.newsFieldTitle, maxLines: 1),
            const SizedBox(height: 12),
            _campo(_resumoCtrl, _l.newsFieldSummary, maxLines: 3),
            const SizedBox(height: 12),
            _campo(_conteudoCtrl, _l.newsFieldContent, maxLines: 8),
            if (!_editando) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.c.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.c.outline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _l.newsPublishNow,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Switch(
                      value: _publicarAgora,
                      onChanged: (v) => setState(() => _publicarAgora = v),
                      activeColor: context.c.primary,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _salvando ? null : _salvar,
                style: FilledButton.styleFrom(
                  backgroundColor: context.c.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _editando ? _l.sdSaveChanges : _l.newsCreate,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: context.c.onSurface),
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.c.onSurfaceVariant),
        filled: true,
        fillColor: context.c.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.c.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.c.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.c.primary, width: 1.5),
        ),
      ),
    );
  }
}
