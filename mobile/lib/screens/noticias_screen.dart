import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});

  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _carregandoMais = false;
  bool _temMais = true;
  int _pagina = 1;
  static const int _porPagina = 10;

  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _carregar();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
          !_carregandoMais &&
          _temMais) {
        _carregarMais();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _pagina = 1;
      _items.clear();
      _temMais = true;
    });
    try {
      final res = await dio.get('/api/noticias',
          queryParameters: {'pagina': 1, 'tamanhoPagina': _porPagina});
      final dados =
          (res.data['dados']?['items'] as List? ?? []).cast<Map<String, dynamic>>();
      final total = res.data['dados']?['total'] as int? ?? 0;
      setState(() {
        _items.addAll(dados);
        _temMais = _items.length < total;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _carregarMais() async {
    setState(() => _carregandoMais = true);
    try {
      _pagina++;
      final res = await dio.get('/api/noticias',
          queryParameters: {'pagina': _pagina, 'tamanhoPagina': _porPagina});
      final dados =
          (res.data['dados']?['items'] as List? ?? []).cast<Map<String, dynamic>>();
      final total = res.data['dados']?['total'] as int? ?? 0;
      setState(() {
        _items.addAll(dados);
        _temMais = _items.length < total;
      });
    } catch (_) {
      _pagina--;
    } finally {
      if (mounted) setState(() => _carregandoMais = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        title:
            const Text('Notícias', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: _items.isEmpty
                  ? const Center(
                      child: Text('Nenhuma notícia publicada ainda.',
                          style: TextStyle(color: kText2)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length + (_temMais ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                                child: _carregandoMais
                                    ? const CircularProgressIndicator()
                                    : const SizedBox()),
                          );
                        }
                        return _NoticiaCard(noticia: _items[index]);
                      },
                    ),
            ),
    );
  }
}

class _NoticiaCard extends StatelessWidget {
  final Map<String, dynamic> noticia;
  const _NoticiaCard({required this.noticia});

  @override
  Widget build(BuildContext context) {
    final imagem = noticia['imagemBase64'] as String?;
    final titulo = noticia['titulo'] as String? ?? '';
    final resumo = noticia['resumo'] as String? ?? '';
    final autorNome = noticia['autorNome'] as String?;
    final publicadaEm = noticia['publicadaEm'] as String?;
    DateTime? data;
    if (publicadaEm != null) {
      try {
        data = DateTime.parse(publicadaEm).toLocal();
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => _NoticiaDetalheScreen(noticia: noticia))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagem != null && imagem.isNotEmpty) _ImagemNoticia(base64: imagem),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(
                          color: kText1,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.3)),
                  const SizedBox(height: 6),
                  Text(resumo,
                      style: TextStyle(color: kText2, fontSize: 13, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (autorNome != null) ...[
                        Icon(Icons.person_outline_rounded, size: 13, color: kText2),
                        const SizedBox(width: 4),
                        Text(autorNome, style: TextStyle(color: kText2, fontSize: 11)),
                        const SizedBox(width: 10),
                      ],
                      if (data != null) ...[
                        Icon(Icons.schedule_rounded, size: 13, color: kText2),
                        const SizedBox(width: 4),
                        Text(
                            '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                            style: TextStyle(color: kText2, fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagemNoticia extends StatelessWidget {
  final String base64;
  const _ImagemNoticia({required this.base64});

  @override
  Widget build(BuildContext context) {
    try {
      final comma = base64.indexOf(',');
      final raw = comma >= 0 ? base64.substring(comma + 1) : base64;
      final bytes = base64Decode(raw);
      return SizedBox(
        width: double.infinity,
        height: 180,
        child: Image.memory(bytes, fit: BoxFit.cover),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

class _NoticiaDetalheScreen extends StatelessWidget {
  final Map<String, dynamic> noticia;
  const _NoticiaDetalheScreen({required this.noticia});

  @override
  Widget build(BuildContext context) {
    final imagem = noticia['imagemBase64'] as String?;
    final titulo = noticia['titulo'] as String? ?? '';
    final resumo = noticia['resumo'] as String? ?? '';
    final conteudo = noticia['conteudo'] as String?;
    final autorNome = noticia['autorNome'] as String?;
    final publicadaEm = noticia['publicadaEm'] as String?;
    DateTime? data;
    if (publicadaEm != null) {
      try {
        data = DateTime.parse(publicadaEm).toLocal();
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
          backgroundColor: kSurface,
          foregroundColor: kText1,
          title: const Text('Notícia',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagem != null && imagem.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _ImagemNoticia(base64: imagem),
              ),
            if (imagem != null && imagem.isNotEmpty) const SizedBox(height: 16),
            Text(titulo,
                style: TextStyle(
                    color: kText1, fontSize: 22, fontWeight: FontWeight.w900, height: 1.3)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (autorNome != null) ...[
                  Icon(Icons.person_outline_rounded, size: 14, color: kText2),
                  const SizedBox(width: 4),
                  Text(autorNome, style: TextStyle(color: kText2, fontSize: 12)),
                  const SizedBox(width: 10),
                ],
                if (data != null) ...[
                  Icon(Icons.schedule_rounded, size: 14, color: kText2),
                  const SizedBox(width: 4),
                  Text(
                      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                      style: TextStyle(color: kText2, fontSize: 12)),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: kBorder),
            const SizedBox(height: 16),
            Text(conteudo ?? resumo,
                style: TextStyle(color: kText1, fontSize: 15, height: 1.7)),
          ],
        ),
      ),
    );
  }
}
