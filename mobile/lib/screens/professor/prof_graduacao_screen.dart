import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';

class ProfGraduacaoScreen extends StatefulWidget {
  const ProfGraduacaoScreen({super.key});

  @override
  State<ProfGraduacaoScreen> createState() => _ProfGraduacaoScreenState();
}

class _ProfGraduacaoScreenState extends State<ProfGraduacaoScreen> {
  List<Map<String, dynamic>> _turmas = [];
  List<Map<String, dynamic>> _alunos = [];
  List<Map<String, dynamic>> _faixas = [];
  List<String> _aptosIds = [];
  Map<String, dynamic>? _turmaSel;
  Map<String, dynamic>? _alunoSel;
  Map<String, dynamic>? _faixaSel;
  int _grauSel = 0;
  final _obsCtrl = TextEditingController();
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  bool _sucesso = false;
  String? _profId;

  @override
  void initState() {
    super.initState();
    _loadTurmas();
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTurmas() async {
    try {
      final me = await dio.get('/api/usuarios/me');
      final uid = (me.data['dados'] as Map<String, dynamic>?)?['id'] ?? '';
      _profId = uid.toString();
      final res = await dio.get('/api/turmas', queryParameters: {'professorId': uid});
      final dados = res.data['dados'];
      final list = dados is List ? dados : (dados is Map ? dados['items'] as List? ?? [] : []);
      if (mounted) setState(() => _turmas = list.cast<Map<String, dynamic>>());
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selecionarTurma(Map<String, dynamic> t) async {
    setState(() { _turmaSel = t; _loading = true; _step = 1; _aptosIds = []; });
    try {
      final modalidadeId = t['modalidadeId'] as String? ?? '';
      final turmaRes = await dio.get('/api/turmas/${t['id']}');
      final dados = turmaRes.data['dados'] as Map<String, dynamic>? ?? {};
      final alunos = (dados['alunos'] as List? ?? []).cast<Map<String, dynamic>>();

      // Carrega aptos para a primeira faixa da modalidade
      if (modalidadeId.isNotEmpty) {
        try {
          final faixasRes = await dio.get('/api/faixas', queryParameters: {'modalidadeId': modalidadeId});
          final faixasData = faixasRes.data['dados'];
          final faixasList = faixasData is List ? faixasData.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
          if (faixasList.isNotEmpty) {
            final aptosRes = await dio.get('/api/graduacoes/aptos', queryParameters: {'faixaId': faixasList.first['id']});
            final aptosData = aptosRes.data['dados'] as List? ?? [];
            _aptosIds = aptosData.cast<Map<String, dynamic>>().map((a) => (a['id'] ?? a['alunoId'] ?? '').toString()).toList();
          }
        } catch (_) {}
      }

      if (mounted) setState(() => _alunos = alunos);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selecionarAluno(Map<String, dynamic> a) async {
    setState(() { _alunoSel = a; _loading = true; _step = 2; });
    try {
      final modalidadeId = _turmaSel?['modalidadeId'] ?? '';
      final res = await dio.get('/api/faixas', queryParameters: {'modalidadeId': modalidadeId});
      final dados = res.data['dados'];
      final list = dados is List ? dados : [];
      if (mounted) setState(() => _faixas = list.cast<Map<String, dynamic>>());
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _promover() async {
    if (_faixaSel == null) return;
    setState(() => _saving = true);
    try {
      final hoje = DateTime.now();
      final dataExame = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      await dio.post('/api/graduacoes', data: {
        'alunoId': _alunoSel!['id'],
        'faixaId': _faixaSel!['id'],
        'dataExame': dataExame,
        'professorId': _profId,
        'aprovado': true,
        'grau': _grauSel,
        'observacoes': _obsCtrl.text.trim(),
      });
      if (mounted) {
        final nomeAluno = _alunoSel!['nome'];
        final nomeFaixa = _faixaSel!['nome'];
        final corFaixa = _faixaSel!['cor'];
        setState(() { _sucesso = true; });
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) setState(() { _sucesso = false; _step = 0; _turmaSel = null; _alunoSel = null; _faixaSel = null; _obsCtrl.clear(); });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nomeAluno promovido para $nomeFaixa!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating),
        );
        // ignore: unused_local_variable
        final _ = corFaixa;
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao promover.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _back() => setState(() {
    if (_step == 2) { _step = 1; _faixaSel = null; _grauSel = 0; }
    else if (_step == 1) { _step = 0; _turmaSel = null; }
  });

  Color _hexCor(String? hex) {
    if (hex == null || hex.isEmpty) return kPrimary;
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); } catch (_) { return kPrimary; }
  }

  @override
  Widget build(BuildContext context) {
    if (_sucesso) {
      final cor = _hexCor(_faixaSel?['cor'] as String?);
      return Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cor.withOpacity(0.2),
                      border: Border.all(color: cor.withOpacity(0.5), width: 3),
                    ),
                    child: Icon(Icons.military_tech_rounded, color: cor, size: 52),
                  ),
                  const SizedBox(height: 24),
                  Text('Graduação registrada!', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(
                    '${_alunoSel?['nome'] ?? ''} foi promovido(a) para',
                    style: TextStyle(color: kText2, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: cor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cor.withOpacity(0.4)),
                    ),
                    child: Text(_faixaSel?['nome'] ?? '', style: TextStyle(color: cor, fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(children: [
                if (_step == 0)
                  GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26))
                else
                  IconButton(onPressed: _back, icon: Icon(Icons.arrow_back, color: kText1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                const SizedBox(width: 8),
                Text('Graduação', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: kPrimary))
                  : _step == 0
                      ? RefreshIndicator(
                          onRefresh: _loadTurmas,
                          color: kPrimary,
                          child: _stepTurma(),
                        )
                      : [_stepTurma, _stepAluno, _stepFaixa][_step](),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepTurma() => _lista(_turmas, (t) => _selecionarTurma(t), (t) => t['nome']);
  Widget _stepAluno() => _lista(_alunos, (a) => _selecionarAluno(a), (a) => a['nome'],
      badge: (a) {
        final id = a['id'] as String? ?? a['alunoId'] as String? ?? '';
        return _aptosIds.contains(id);
      });

  Widget _lista(
    List<Map<String, dynamic>> items,
    void Function(Map<String, dynamic>) onTap,
    String Function(Map<String, dynamic>) title, {
    bool Function(Map<String, dynamic>)? badge,
  }) =>
      ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final isApto = badge != null && badge(items[i]);
          return GestureDetector(
            onTap: () => onTap(items[i]),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
              child: Row(children: [
                Expanded(child: Text(title(items[i]), style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w600))),
                if (isApto)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: kSuccess.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('Apto', style: TextStyle(color: kSuccess, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                Icon(Icons.chevron_right, color: kText2),
              ]),
            ),
          );
        },
      );

  Widget _stepFaixa() => Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ..._faixas.map((f) => GestureDetector(
                      onTap: () => setState(() { _faixaSel = f; _grauSel = 0; }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _faixaSel?['id'] == f['id'] ? kPrimary.withOpacity(0.15) : kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _faixaSel?['id'] == f['id'] ? kPrimary : kBorder),
                        ),
                        child: Row(children: [
                          if (f['cor'] != null)
                            Container(width: 16, height: 16, margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(shape: BoxShape.circle,
                                    color: Color(int.tryParse(f['cor'].toString().replaceAll('#', '0xFF')) ?? 0xFF94A3B8))),
                          Expanded(child: Text(f['nome'] ?? '', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600))),
                          if (_faixaSel?['id'] == f['id']) Icon(Icons.check_circle_rounded, color: kPrimary),
                        ]),
                      ),
                    )),
                // Seletor de grau — aparece apenas quando a faixa selecionada tem graus
                if (_faixaSel != null && _faixaSel!['temGraus'] == true) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.military_tech_rounded, color: kPrimary, size: 16),
                          const SizedBox(width: 6),
                          Text('Grau', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: kPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                            child: Text(_grauSel == 0 ? 'Sem grau' : '$_grauSel° grau',
                                style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            (_faixaSel!['maxGraus'] as num? ?? 4).toInt() + 1,
                            (i) => GestureDetector(
                              onTap: () => setState(() => _grauSel = i),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _grauSel == i ? kPrimary : kBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _grauSel == i ? kPrimary : kBorder, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    i == 0 ? '—' : '$i',
                                    style: TextStyle(
                                      color: _grauSel == i ? Colors.white : kText2,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _obsCtrl,
                  style: TextStyle(color: kText1),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Observação (opcional)',
                    hintStyle: TextStyle(color: kText2),
                    filled: true, fillColor: kSurface,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _saving || _faixaSel == null ? null : _promover,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Promover', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      if (_alunoSel != null && _aptosIds.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(
                          _aptosIds.contains(_alunoSel!['id'] ?? _alunoSel!['alunoId'])
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ],
                    ]),
            ),
          ),
        ],
      );
}
