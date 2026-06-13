import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/paywall_modal.dart';
import '../../core/plan_service.dart';

class ProfPresencaScreen extends StatefulWidget {
  const ProfPresencaScreen({super.key});

  @override
  State<ProfPresencaScreen> createState() => _ProfPresencaScreenState();
}

class _ProfPresencaScreenState extends State<ProfPresencaScreen> {
  List<Map<String, dynamic>> _turmas = [];
  Map<String, dynamic>? _turmaSel;
  List<Map<String, dynamic>> _alunos = [];
  final _selecionados = <String>{};
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  DateTime _dataSel = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTurmas();
  }

  Future<void> _loadTurmas() async {
    try {
      final me = await dio.get('/api/usuarios/me');
      final uid = (me.data['dados'] as Map<String, dynamic>?)?['id'] ?? '';
      final res = await dio.get('/api/turmas', queryParameters: {'professorId': uid});
      final dados = res.data['dados'];
      final list = dados is List ? dados : (dados is Map ? dados['items'] as List? ?? [] : []);
      if (mounted) setState(() => _turmas = list.cast<Map<String, dynamic>>());
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selecionarTurma(Map<String, dynamic> t) async {
    setState(() {
      _turmaSel = t;
      _loading = true;
      _step = 1;
      _selecionados.clear();
    });
    try {
      final res = await dio.get('/api/turmas/${t['id']}');
      final dados = res.data['dados'] as Map<String, dynamic>? ?? {};
      final alunos = (dados['alunos'] as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _alunos = alunos);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSel,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: kPrimary, surface: kSurface),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() { _dataSel = picked; _selecionados.clear(); });
  }

  String get _dataStr {
    return '${_dataSel.year}-${_dataSel.month.toString().padLeft(2, '0')}-${_dataSel.day.toString().padLeft(2, '0')}';
  }

  String get _dataLabel {
    final hoje = DateTime.now();
    final diff = DateTime(hoje.year, hoje.month, hoje.day)
        .difference(DateTime(_dataSel.year, _dataSel.month, _dataSel.day))
        .inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    return '${_dataSel.day.toString().padLeft(2, '0')}/${_dataSel.month.toString().padLeft(2, '0')}/${_dataSel.year}';
  }

  Future<void> _registrar() async {
    if (_selecionados.isEmpty) return;
    setState(() => _saving = true);
    try {
      await Future.wait(_selecionados.map((alunoId) => dio.post('/api/presencas', data: {
            'alunoId': alunoId,
            'turmaId': _turmaSel!['id'].toString(),
            'data': _dataStr,
          })));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selecionados.length} presença(s) registrada(s)!'),
            backgroundColor: kSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _step = 0;
          _turmaSel = null;
          _alunos = [];
          _selecionados.clear();
        });
      }
    } catch (e) {
      String msg = 'Erro ao registrar.';
      try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(children: [
                if (_step > 0) ...[
                  IconButton(
                    onPressed: () => setState(() {
                      _step = 0;
                      _turmaSel = null;
                      _selecionados.clear();
                    }),
                    icon: Icon(Icons.arrow_back, color: kText1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(child: Text('Registrar Presença', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800))),
                IconButton(
                  onPressed: () async {
                    if (PlanService.instance.showAds) {
                      await mostrarPaywall(context);
                      return;
                    }
                    if (context.mounted) context.push('/scan-qr');
                  },
                  icon: Icon(Icons.qr_code_scanner_rounded, color: kPrimary, size: 26),
                  tooltip: 'Escanear QR Code',
                ),
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
                      : _stepAlunos(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepTurma() => ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _turmas.length,
        itemBuilder: (_, i) {
          final t = _turmas[i];
          return GestureDetector(
            onTap: () => _selecionarTurma(t),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
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
                        Text(t['nome'] ?? '', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w600)),
                        if (t['modalidadeNome'] != null)
                          Text(t['modalidadeNome'], style: TextStyle(color: kText2, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: kText2),
                ],
              ),
            ),
          );
        },
      );

  Widget _stepAlunos() => Column(
        children: [
          // Date selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimary.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: kPrimary, size: 18),
                    const SizedBox(width: 10),
                    Text(_dataLabel, style: TextStyle(color: kPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('Alterar', style: TextStyle(color: kText2, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Text('Marque quem esteve presente', style: TextStyle(color: kText2, fontSize: 13)),
                const Spacer(),
                Text('${_selecionados.length}/${_alunos.length}', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _alunos.length,
              itemBuilder: (_, i) {
                final a = _alunos[i];
                // MatriculaDto usa 'alunoId', não 'id'
                final alunoId = (a['alunoId'] ?? a['id'])?.toString() ?? '';
                final nome = (a['nomeAluno'] ?? a['nome'] ?? '').toString();
                final sel = _selecionados.contains(alunoId);
                final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
                return GestureDetector(
                  onTap: () => setState(() => sel ? _selecionados.remove(alunoId) : _selecionados.add(alunoId)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sel ? kPrimary.withOpacity(0.15) : kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? kPrimary : kBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: sel ? kPrimary.withOpacity(0.3) : kPrimary.withOpacity(0.1),
                          child: Text(initials.isEmpty ? '?' : initials,
                              style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(nome, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600))),
                        if (sel) Icon(Icons.check_circle_rounded, color: kPrimary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _saving || _selecionados.isEmpty ? null : _registrar,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text('Registrar ${_selecionados.length} presença(s)', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
}
