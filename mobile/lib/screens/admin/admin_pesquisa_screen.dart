import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';

class AdminPesquisaScreen extends StatefulWidget {
  final Map<String, dynamic>? template;
  const AdminPesquisaScreen({super.key, this.template});

  @override
  State<AdminPesquisaScreen> createState() => _AdminPesquisaScreenState();
}

class _AdminPesquisaScreenState extends State<AdminPesquisaScreen> {
  List<Map<String, dynamic>> _respostas = [];
  bool _loading = true;
  bool _erro = false;
  String? _academiaId;

  // Filtro de mês
  late String _mesSelecionado;
  late List<String> _mesesDisponiveis;

  String? get _templateId => widget.template?['id'] as String?;
  String get _tituloTela => widget.template != null
      ? widget.template!['titulo']?.toString() ?? 'Pesquisa'
      : 'Pesquisa de Satisfação';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mesSelecionado = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _mesesDisponiveis = _gerarUltimos6Meses();
    _load();
  }

  List<String> _gerarUltimos6Meses() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _erro = false; });
    try {
      final user = await AuthStorage.getUser();
      if (user == null) { if (mounted) setState(() { _loading = false; _erro = true; }); return; }
      _academiaId = user.academiaId;
      final lista = await firestoreService.getRespostasPesquisa(
        user.academiaId!,
        mes: _mesSelecionado,
        templateId: _templateId,
      );
      if (mounted) setState(() { _respostas = lista; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _erro = true; });
    }
  }

  double get _mediaNota {
    if (_respostas.isEmpty) return 0;
    final soma = _respostas.fold<int>(0, (s, r) => s + ((r['nota'] as num?)?.toInt() ?? 0));
    return soma / _respostas.length;
  }

  Map<int, int> get _contPorNota {
    final map = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in _respostas) {
      final nota = (r['nota'] as num?)?.toInt() ?? 0;
      if (nota >= 1 && nota <= 5) map[nota] = (map[nota] ?? 0) + 1;
    }
    return map;
  }

  String _labelMes(String mes) {
    final parts = mes.split('-');
    if (parts.length != 2) return mes;
    const meses = ['', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${meses[m.clamp(0, 12)]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kText1, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(_tituloTela, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kPrimary))
          : _erro
              ? Center(child: Text('Erro ao carregar respostas.', style: TextStyle(color: kText2)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kPrimary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Seletor de mês
                      SliverToBoxAdapter(child: _buildFiltroMes()),
                      // Card resumo
                      SliverToBoxAdapter(child: _buildResumo()),
                      // Distribuição por estrela
                      if (_respostas.isNotEmpty)
                        SliverToBoxAdapter(child: _buildDistribuicao()),
                      // Lista de comentários
                      if (_respostas.isNotEmpty)
                        SliverToBoxAdapter(child: _buildComentarios()),
                      if (_respostas.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.star_border_rounded, color: kText2, size: 48),
                            const SizedBox(height: 12),
                            Text('Nenhuma resposta em ${_labelMes(_mesSelecionado)}', style: TextStyle(color: kText2, fontSize: 14)),
                          ])),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFiltroMes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _mesesDisponiveis.map((mes) {
            final selected = mes == _mesSelecionado;
            return GestureDetector(
              onTap: () {
                if (mes != _mesSelecionado) {
                  setState(() => _mesSelecionado = mes);
                  _load();
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? kPrimary : kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? kPrimary : kBorder),
                ),
                child: Text(
                  _labelMes(mes),
                  style: TextStyle(
                    color: selected ? Colors.white : kText2,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResumo() {
    final media = _mediaNota;
    final total = _respostas.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          // Nota média grande
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Média geral', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  total == 0 ? '—' : media.toStringAsFixed(1),
                  style: TextStyle(color: kText1, fontSize: 40, fontWeight: FontWeight.w900, height: 1),
                ),
                if (total > 0) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Icon(Icons.star_rounded, color: kPrimary, size: 22),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Text('$total resposta${total != 1 ? 's' : ''}', style: TextStyle(color: kText2, fontSize: 12)),
            ]),
          ),
          // Estrelas visuais
          if (total > 0)
            Row(children: List.generate(5, (i) {
              final preenchido = i < media.round();
              return Icon(
                preenchido ? Icons.star_rounded : Icons.star_outline_rounded,
                color: preenchido ? kPrimary : kBorder,
                size: 28,
              );
            })),
        ]),
      ),
    );
  }

  Widget _buildDistribuicao() {
    final cont = _contPorNota;
    final maxCont = cont.values.fold<int>(1, (m, v) => v > m ? v : m);
    const labels = ['', 'Muito ruim', 'Ruim', 'Regular', 'Bom', 'Excelente'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Distribuição', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ...List.generate(5, (i) {
            final estrela = 5 - i;
            final qtd = cont[estrela] ?? 0;
            final pct = maxCont > 0 ? qtd / maxCont : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Icon(Icons.star_rounded, color: kPrimary, size: 14),
                const SizedBox(width: 4),
                Text('$estrela', style: TextStyle(color: kText2, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.toDouble(),
                      minHeight: 8,
                      backgroundColor: kBorder.withOpacity(0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimary.withOpacity(0.8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text('$qtd', style: TextStyle(color: kText2, fontSize: 12), textAlign: TextAlign.right),
                ),
              ]),
            );
          }),
          const Divider(height: 16),
          ...List.generate(5, (i) {
            final estrela = 5 - i;
            final qtd = cont[estrela] ?? 0;
            if (qtd == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(children: [
                Text('${labels[estrela]}:', style: TextStyle(color: kText2, fontSize: 11)),
                const SizedBox(width: 4),
                Text('$qtd', style: TextStyle(color: kText1, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildComentarios() {
    final comComentario = _respostas.where((r) {
      final c = r['comentario']?.toString().trim() ?? '';
      return c.isNotEmpty;
    }).toList();

    if (comComentario.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Comentários (${comComentario.length})', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...comComentario.map((r) {
            final nota = (r['nota'] as num?)?.toInt() ?? 0;
            final comentario = r['comentario']?.toString().trim() ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: List.generate(5, (i) => Icon(
                  i < nota ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < nota ? kPrimary : kBorder,
                  size: 14,
                ))),
                const SizedBox(height: 6),
                Text(comentario, style: TextStyle(color: kText1, fontSize: 13)),
              ]),
            );
          }),
        ]),
      ),
    );
  }
}
