import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

class AdminNoticiasScreen extends StatefulWidget {
  const AdminNoticiasScreen({super.key});

  @override
  State<AdminNoticiasScreen> createState() => _AdminNoticiasScreenState();
}

class _AdminNoticiasScreenState extends State<AdminNoticiasScreen> {
  List<Map<String, dynamic>> _noticias = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final res = await dio.get('/api/noticias/admin',
          queryParameters: {'pagina': 1, 'tamanhoPagina': 50});
      final dados =
          (res.data['dados']?['items'] as List? ?? []).cast<Map<String, dynamic>>();
      setState(() => _noticias = dados);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publicar(Map<String, dynamic> n) async {
    try {
      await dio.post('/api/noticias/${n['id']}/publicar');
      await _carregar();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Notícia publicada!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao publicar.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _excluir(Map<String, dynamic> n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Excluir notícia?', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Text('Esta ação não pode ser desfeita.', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Excluir', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.delete('/api/noticias/${n['id']}');
      await _carregar();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao excluir.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _abrirFormulario([Map<String, dynamic>? noticia]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NoticiaFormScreen(
          noticia: noticia,
          onSalvo: _carregar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        title: const Text('Notícias', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: kPrimary),
            onPressed: () => _abrirFormulario(),
            tooltip: 'Nova notícia',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: _noticias.isEmpty
                  ? const Center(child: Text('Nenhuma notícia cadastrada.', style: TextStyle(color: kText2)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _noticias.length,
                      itemBuilder: (context, index) {
                        final n = _noticias[index];
                        final publicada = n['publicada'] == true;
                        final publicadaEm = n['publicadaEm'] as String?;
                        DateTime? data;
                        if (publicadaEm != null) {
                          try { data = DateTime.parse(publicadaEm).toLocal(); } catch (_) {}
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: publicada ? kSuccess.withOpacity(0.12) : kWarning.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      publicada ? 'Publicada' : 'Rascunho',
                                      style: TextStyle(color: publicada ? kSuccess : kWarning, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (data != null)
                                    Text(
                                      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                                      style: TextStyle(color: kText2, fontSize: 11),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(n['titulo'] as String? ?? '', style: TextStyle(color: kText1, fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(n['resumo'] as String? ?? '', style: TextStyle(color: kText2, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (!publicada) ...[
                                    _ActionBtn(
                                      label: 'Publicar',
                                      icon: Icons.send_rounded,
                                      color: kSuccess,
                                      onTap: () => _publicar(n),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  _ActionBtn(
                                    label: 'Editar',
                                    icon: Icons.edit_outlined,
                                    color: kPrimary,
                                    onTap: () => _abrirFormulario(n),
                                  ),
                                  const SizedBox(width: 8),
                                  _ActionBtn(
                                    label: 'Excluir',
                                    icon: Icons.delete_outline_rounded,
                                    color: kDanger,
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
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

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
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _NoticiaFormScreen extends StatefulWidget {
  final Map<String, dynamic>? noticia;
  final VoidCallback onSalvo;
  const _NoticiaFormScreen({this.noticia, required this.onSalvo});

  @override
  State<_NoticiaFormScreen> createState() => _NoticiaFormScreenState();
}

class _NoticiaFormScreenState extends State<_NoticiaFormScreen> {
  final _tituloCtrl = TextEditingController();
  final _resumoCtrl = TextEditingController();
  final _conteudoCtrl = TextEditingController();
  String? _imagemBase64;
  bool _publicarAgora = false;
  bool _salvando = false;

  bool get _editando => widget.noticia != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      _tituloCtrl.text = widget.noticia!['titulo'] as String? ?? '';
      _resumoCtrl.text = widget.noticia!['resumo'] as String? ?? '';
      _conteudoCtrl.text = widget.noticia!['conteudo'] as String? ?? '';
      _imagemBase64 = widget.noticia!['imagemBase64'] as String?;
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Imagem muito grande. Máximo 3MB.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _imagemBase64 = base64Encode(bytes));
  }

  Future<void> _salvar() async {
    if (_tituloCtrl.text.trim().isEmpty || _resumoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Título e resumo são obrigatórios.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _salvando = true);
    try {
      if (_editando) {
        await dio.put('/api/noticias/${widget.noticia!['id']}', data: {
          'titulo': _tituloCtrl.text.trim(),
          'resumo': _resumoCtrl.text.trim(),
          'conteudo': _conteudoCtrl.text.trim().isNotEmpty ? _conteudoCtrl.text.trim() : null,
          'imagemBase64': _imagemBase64,
        });
      } else {
        await dio.post('/api/noticias', data: {
          'titulo': _tituloCtrl.text.trim(),
          'resumo': _resumoCtrl.text.trim(),
          'conteudo': _conteudoCtrl.text.trim().isNotEmpty ? _conteudoCtrl.text.trim() : null,
          'imagemBase64': _imagemBase64,
          'publicarAgora': _publicarAgora,
        });
      }
      widget.onSalvo();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao salvar notícia.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        title: Text(_editando ? 'Editar Notícia' : 'Nova Notícia',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Salvar', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
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
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder, style: _imagemBase64 == null ? BorderStyle.solid : BorderStyle.solid),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imagemBase64 != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Builder(builder: (_) {
                            try {
                              return Image.memory(base64Decode(_imagemBase64!), fit: BoxFit.cover);
                            } catch (_) {
                              return const SizedBox.shrink();
                            }
                          }),
                          Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              onTap: () => setState(() => _imagemBase64 = null),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: kText2, size: 32),
                          const SizedBox(height: 8),
                          Text('Adicionar imagem (opcional)', style: TextStyle(color: kText2, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            _campo(_tituloCtrl, 'Título', maxLines: 1),
            const SizedBox(height: 12),
            _campo(_resumoCtrl, 'Resumo (exibido na lista)', maxLines: 3),
            const SizedBox(height: 12),
            _campo(_conteudoCtrl, 'Conteúdo completo (opcional)', maxLines: 8),
            if (!_editando) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                child: Row(
                  children: [
                    Expanded(child: Text('Publicar agora e notificar', style: TextStyle(color: kText1, fontWeight: FontWeight.w600, fontSize: 14))),
                    Switch(value: _publicarAgora, onChanged: (v) => setState(() => _publicarAgora = v), activeColor: kPrimary),
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
                  backgroundColor: kPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _salvando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_editando ? 'Salvar alterações' : 'Criar notícia',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
      style: TextStyle(color: kText1),
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kText2),
        filled: true,
        fillColor: kSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
      ),
    );
  }
}
