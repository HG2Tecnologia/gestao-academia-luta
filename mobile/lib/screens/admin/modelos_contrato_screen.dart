import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';

class AdminModelosContratoScreen extends StatefulWidget {
  const AdminModelosContratoScreen({super.key});

  @override
  State<AdminModelosContratoScreen> createState() => _AdminModelosContratoScreenState();
}

class _AdminModelosContratoScreenState extends State<AdminModelosContratoScreen> {
  List<Map<String, dynamic>> _modelos = [];
  bool _loading = true;
  bool _erro = false;
  final _fmt = DateFormat('dd/MM/yyyy');
  String? _academiaId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _erro = false; });
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId ?? '';
      if (_academiaId!.isEmpty) { setState(() => _loading = false); return; }
      final list = await firestoreService.getModelosContrato(_academiaId!);
      if (mounted) setState(() { _modelos = list.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _erro = true; _loading = false; });
    }
  }

  Future<void> _deletar(Map<String, dynamic> m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Remover Modelo', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Text('Deseja remover "${m['nome']}"?', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remover', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || _academiaId == null) return;
    try {
      await firestoreService.deleteModeloContrato(_academiaId!, m['id'].toString());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao remover modelo'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _abrirEditor({Map<String, dynamic>? modelo}) {
    if (_academiaId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ModeloEditorSheet(
        academiaId: _academiaId!,
        modelo: modelo,
        onSalvo: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kText1, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Modelos de Contrato', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: !_loading && !_erro
          ? FloatingActionButton.extended(
              onPressed: () => _abrirEditor(),
              backgroundColor: kPrimary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Novo Modelo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, color: kDanger, size: 52),
                      const SizedBox(height: 14),
                      Text('Não foi possível carregar', style: TextStyle(color: kText2)),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tentar novamente'),
                        style: OutlinedButton.styleFrom(foregroundColor: kPrimary),
                      ),
                    ],
                  ),
                )
              : _modelos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_rounded, color: kText2, size: 52),
                          const SizedBox(height: 14),
                          Text('Nenhum modelo cadastrado', style: TextStyle(color: kText2)),
                          const SizedBox(height: 8),
                          Text('Toque em + para criar', style: TextStyle(color: kText2.withOpacity(0.6), fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _modelos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final m = _modelos[i];
                        final criadoEm = m['criadoEm'] != null || m['criado_em'] != null
                            ? _fmt.format(DateTime.tryParse((m['criadoEm'] ?? m['criado_em']).toString()) ?? DateTime.now())
                            : '';
                        final htmlContent = m['conteudoHtml'] ?? m['conteudo_html'] ?? '';
                        final previewHtml = (htmlContent as String)
                            .replaceAll(RegExp(r'<[^>]*>'), ' ')
                            .replaceAll(RegExp(r'\s+'), ' ')
                            .trim();
                        final preview = previewHtml.length > 80 ? '${previewHtml.substring(0, 80)}…' : previewHtml;

                        return Container(
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kBorder),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                            leading: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.description_rounded, color: kPrimary, size: 22),
                            ),
                            title: Text(
                              m['nome']?.toString() ?? '',
                              style: TextStyle(color: kText1, fontWeight: FontWeight.w700),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (preview.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(preview, style: TextStyle(color: kText2, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ),
                                if (criadoEm.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(children: [
                                      Icon(Icons.calendar_today_rounded, size: 10, color: kText2.withOpacity(0.6)),
                                      const SizedBox(width: 3),
                                      Text(criadoEm, style: TextStyle(color: kText2.withOpacity(0.6), fontSize: 10)),
                                    ]),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _abrirEditor(modelo: m),
                                  icon: Icon(Icons.edit_rounded, color: kPrimary, size: 20),
                                ),
                                IconButton(
                                  onPressed: () => _deletar(m),
                                  icon: Icon(Icons.delete_outline_rounded, color: kDanger, size: 20),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _ModeloEditorSheet extends StatefulWidget {
  const _ModeloEditorSheet({required this.academiaId, this.modelo, required this.onSalvo});
  final String academiaId;
  final Map<String, dynamic>? modelo;
  final VoidCallback onSalvo;

  @override
  State<_ModeloEditorSheet> createState() => _ModeloEditorSheetState();
}

class _ModeloEditorSheetState extends State<_ModeloEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _htmlCtrl = TextEditingController();
  bool _salvando = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    final m = widget.modelo;
    if (m != null) {
      _nomeCtrl.text = m['nome']?.toString() ?? '';
      _htmlCtrl.text = (m['conteudoHtml'] ?? m['conteudo_html'])?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _htmlCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _salvando = true; });
    try {
      final data = {
        'nome': _nomeCtrl.text.trim(),
        'conteudo_html': _htmlCtrl.text,
      };
      if (widget.modelo != null) {
        await firestoreService.updateModeloContrato(widget.academiaId, widget.modelo!['id'].toString(), data);
      } else {
        await firestoreService.addModeloContrato(widget.academiaId, data);
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSalvo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao salvar modelo'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() { _salvando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.modelo != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.description_rounded, color: kPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'Editar Modelo' : 'Novo Modelo de Contrato',
                        style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => _showPreview = !_showPreview),
                      icon: Icon(_showPreview ? Icons.edit_rounded : Icons.visibility_rounded, size: 14),
                      label: Text(_showPreview ? 'Editar' : 'Preview'),
                      style: TextButton.styleFrom(foregroundColor: kPrimary, textStyle: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: TextFormField(
                  controller: _nomeCtrl,
                  style: TextStyle(color: kText1),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  decoration: InputDecoration(
                    labelText: 'Nome do Modelo',
                    labelStyle: TextStyle(color: kText2, fontSize: 13),
                    prefixIcon: Icon(Icons.label_rounded, color: kText2, size: 18),
                    filled: true, fillColor: kBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: _showPreview
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: SingleChildScrollView(
                            controller: scroll,
                            child: Text(
                              _htmlCtrl.text
                                  .replaceAll(RegExp(r'<br\s*/?>',  caseSensitive: false), '\n')
                                  .replaceAll(RegExp(r'</p>',        caseSensitive: false), '\n\n')
                                  .replaceAll(RegExp(r'</h[1-6]>',  caseSensitive: false), '\n\n')
                                  .replaceAll(RegExp(r'</li>',       caseSensitive: false), '\n')
                                  .replaceAll(RegExp(r'<[^>]*>'), '')
                                  .replaceAll(RegExp(r'&nbsp;'), ' ')
                                  .trim(),
                              style: TextStyle(color: kText1, fontSize: 13, height: 1.5),
                            ),
                          ),
                        )
                      : TextFormField(
                          controller: _htmlCtrl,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(color: kText1, fontSize: 13, fontFamily: 'monospace'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                          decoration: InputDecoration(
                            labelText: 'Conteúdo HTML',
                            labelStyle: TextStyle(color: kText2, fontSize: 12),
                            alignLabelWithHint: true,
                            filled: true, fillColor: kBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
                            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? 'Salvar Alterações' : 'Criar Modelo',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
