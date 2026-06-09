import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/widgets.dart';

class AdminAlunosScreen extends StatefulWidget {
  const AdminAlunosScreen({super.key});

  @override
  State<AdminAlunosScreen> createState() => _AdminAlunosScreenState();
}

class _AdminAlunosScreenState extends State<AdminAlunosScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _alunos = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load('');
    _ctrl.addListener(() => _debounce(_ctrl.text));
  }

  DateTime? _last;
  void _debounce(String q) {
    _last = DateTime.now();
    final snap = _last!;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_last == snap) _load(q);
    });
  }

  Future<void> _load(String q) async {
    setState(() { _loading = true; _erro = null; });
    try {
      final res = await dio.get('/api/alunos', queryParameters: {'nome': q, 'pageSize': 50});
      final body = res.data as Map<String, dynamic>;
      final dados = body['dados'];
      final items = dados is Map ? (dados['itens'] as List? ?? []) : (dados as List? ?? []);
      if (mounted) setState(() => _alunos = items.cast<Map<String, dynamic>>());
    } catch (e) {
      if (mounted) setState(() => _erro = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _finCor(String? s) {
    if (s == 'Inadimplente') return kDanger;
    if (s == 'Pendente') return kWarning;
    return kSuccess;
  }

  String _formatFin(String? s) {
    if (s == 'EmDia') return 'Em Dia';
    return s ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/admin/alunos/novo');
          _load(_ctrl.text);
        },
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text('Alunos', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: kText1),
                decoration: InputDecoration(
                  hintText: 'Buscar aluno...',
                  hintStyle: TextStyle(color: kText2),
                  prefixIcon: Icon(Icons.search, color: kText2),
                  filled: true,
                  fillColor: kSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: kPrimary))
                  : _erro != null
                      ? Center(child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_erro!, style: TextStyle(color: kDanger, fontSize: 13), textAlign: TextAlign.center),
                        ))
                      : _alunos.isEmpty
                          ? Center(child: Text('Nenhum aluno encontrado.', style: TextStyle(color: kText2)))
                          : RefreshIndicator(
                              onRefresh: () => _load(_ctrl.text),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _alunos.length,
                                itemBuilder: (_, i) {
                                  final a = _alunos[i];
                                  final ativo = a['ativo'] == true;
                                  final fin = a['situacaoFinanceira'] as String?;
                                  final faixaCor = a['faixaAtualCor'] as String?;
                                  final faixaCorBarra = a['faixaAtualCorBarra'] as String?;
                                  final grauAtual = (a['grauAtual'] as num?)?.toInt() ?? 0;
                                  final maxGraus = (a['faixaAtualMaxGraus'] as num?)?.toInt() ?? 4;
                                  final temGraus = a['faixaAtualTemGraus'] == true || grauAtual > 0;
                                  Color parseCor(String? hex) {
                                    try { return Color(int.parse((hex ?? '').replaceAll('#', '0xFF'))); } catch (_) { return kPrimary; }
                                  }
                                  return GestureDetector(
                                    onTap: () async {
                                      await context.push('/admin/alunos/${a['id']}');
                                      _load(_ctrl.text);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: kSurface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: kBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(a['nome'] ?? '', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
                                                const SizedBox(height: 4),
                                                Row(children: [
                                                  if (faixaCor != null) ...[
                                                    BeltBadge(
                                                      cor: parseCor(faixaCor),
                                                      corBarra: parseCor(faixaCorBarra ?? '#000000'),
                                                      temGraus: temGraus,
                                                      grau: grauAtual,
                                                      maxGraus: maxGraus,
                                                      height: 10,
                                                      minWidth: 24,
                                                    ),
                                                    const SizedBox(width: 6),
                                                  ],
                                                  Flexible(child: Text(
                                                    [
                                                      a['faixaAtualNome'],
                                                      (a['turmas'] as List?)?.isNotEmpty == true ? (a['turmas'] as List).first.toString() : null,
                                                    ].where((s) => s != null && s != '').join(' · '),
                                                    style: TextStyle(color: kText2, fontSize: 12),
                                                    overflow: TextOverflow.ellipsis,
                                                  )),
                                                ]),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: ativo ? kSuccess.withOpacity(0.15) : kText2.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  ativo ? 'Ativo' : 'Inativo',
                                                  style: TextStyle(color: ativo ? kSuccess : kText2, fontSize: 11, fontWeight: FontWeight.w700),
                                                ),
                                              ),
                                              if (fin != null) ...[
                                                const SizedBox(height: 4),
                                                Text(_formatFin(fin), style: TextStyle(color: _finCor(fin), fontSize: 12, fontWeight: FontWeight.w600)),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.chevron_right, color: kText2, size: 18),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
