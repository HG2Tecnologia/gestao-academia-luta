import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import 'turmas_screen.dart' show TurmaFormSheet;

class AdminTurmaDetalheScreen extends StatefulWidget {
  final String turmaId;
  const AdminTurmaDetalheScreen({super.key, required this.turmaId});

  @override
  State<AdminTurmaDetalheScreen> createState() => _AdminTurmaDetalheScreenState();
}

class _AdminTurmaDetalheScreenState extends State<AdminTurmaDetalheScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _ctrl = TextEditingController();

  Map<String, dynamic>? _turma;
  List<Map<String, dynamic>> _alunos = [];
  List<Map<String, dynamic>> _filtrados = [];
  List<Map<String, dynamic>> _horarios = [];
  Map<String, int> _presencaCount = {};

  // Aba Presença
  DateTime _dataSel = DateTime.now();
  Set<String> _presentesNaData = {};
  final Set<String> _marcando = {};

  Set<String> _aptosGraduar = {};

  bool _loading = true;
  bool _loadingPresenca = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 1 && !_tabCtrl.indexIsChanging) _loadPresencaData();
    });
    _ctrl.addListener(_filtrar);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final hoje = DateTime.now();
      final ate = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      final deDate = hoje.subtract(const Duration(days: 180));
      final de = '${deDate.year}-${deDate.month.toString().padLeft(2, '0')}-${deDate.day.toString().padLeft(2, '0')}';

      final futures = await Future.wait([
        dio.get('/api/turmas/${widget.turmaId}'),
        dio.get('/api/presencas/relatorio', queryParameters: {
          'turmaId': widget.turmaId,
          'de': de,
          'ate': ate,
        }),
      ]);

      final turmaBody = futures[0].data as Map<String, dynamic>;
      final dados = turmaBody['dados'] as Map<String, dynamic>?;
      if (dados == null) throw Exception('Turma não encontrada');
      final alunosList = (dados['alunos'] as List? ?? []).cast<Map<String, dynamic>>();

      // Monta mapa de presença por alunoId
      final relatorio = futures[1].data['dados'] as Map<String, dynamic>?;
      final relAlunos = (relatorio?['alunos'] as List? ?? []).cast<Map<String, dynamic>>();
      final countMap = <String, int>{};
      for (final ra in relAlunos) {
        final id = ra['alunoId']?.toString() ?? '';
        countMap[id] = (ra['presencas'] as num?)?.toInt() ?? 0;
      }

      // Carrega horários
      final horariosRes = await dio.get('/api/horarios', queryParameters: {'turmaId': widget.turmaId});
      final horariosData = horariosRes.data['dados'];
      final horariosList = horariosData is List ? horariosData.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];

      // Fetch aptos para cada faixa da modalidade desta turma
      Set<String> aptosSet = {};
      try {
        final modalidadeId = (dados['modalidadeId'] as String?) ?? '';
        if (modalidadeId.isNotEmpty) {
          final faixasRes = await dio.get('/api/faixas', queryParameters: {'modalidadeId': modalidadeId});
          final faixasList = (faixasRes.data['dados'] as List? ?? []).cast<Map<String, dynamic>>();
          for (final f in faixasList) {
            final faixaId = f['id']?.toString() ?? '';
            if (faixaId.isEmpty) continue;
            final aptosRes = await dio.get('/api/graduacoes/aptos', queryParameters: {'faixaId': faixaId});
            final aptosList = (aptosRes.data['dados'] as List? ?? []).cast<Map<String, dynamic>>();
            for (final ap in aptosList) {
              final id = ap['alunoId']?.toString() ?? '';
              if (id.isNotEmpty) aptosSet.add(id);
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _turma = dados;
          _alunos = alunosList;
          _presencaCount = countMap;
          _horarios = horariosList;
          _aptosGraduar = aptosSet;
          _filtrar();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _erro = 'Erro ao carregar turma');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mostrarQrTurma() async {
    final turmaId = widget.turmaId;
    // turmaId já é suficiente como dado do QR — o check-in valida autenticação no backend
    final qrData = turmaId;
    if (!mounted) return;

    final nomeTurma = _turma?['nome'] ?? 'Turma';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: kSurface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('QR Code da Turma', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(nomeTurma, style: TextStyle(color: kText2, fontSize: 13)),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: 'TURMA:$qrData', version: QrVersions.auto, size: 190),
            ),
          ),
          const SizedBox(height: 12),
          Text('Alunos escaneiam para registrar presença', style: TextStyle(color: kText2, fontSize: 12), textAlign: TextAlign.center),
          Text('Válido apenas no horário da aula', style: TextStyle(color: kText2, fontSize: 11), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  void _filtrar() {
    final q = _ctrl.text.trim().toLowerCase();
    setState(() {
      _filtrados = q.isEmpty
          ? List.from(_alunos)
          : _alunos.where((a) {
              final nome = (a['nomeAluno'] as String? ?? '').toLowerCase();
              return nome.contains(q);
            }).toList();
    });
  }

  // ── Aba Presença ─────────────────────────────────────

  String get _dataStr =>
      '${_dataSel.year}-${_dataSel.month.toString().padLeft(2, '0')}-${_dataSel.day.toString().padLeft(2, '0')}';

  String get _dataLabel {
    final hoje = DateTime.now();
    final diff = DateTime(hoje.year, hoje.month, hoje.day)
        .difference(DateTime(_dataSel.year, _dataSel.month, _dataSel.day))
        .inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    return '${_dataSel.day.toString().padLeft(2, '0')}/${_dataSel.month.toString().padLeft(2, '0')}/${_dataSel.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSel,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: kPrimary, surface: kSurface),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() { _dataSel = picked; _presentesNaData.clear(); });
      _loadPresencaData();
    }
  }

  void _prevDay() {
    setState(() { _dataSel = _dataSel.subtract(const Duration(days: 1)); _presentesNaData.clear(); });
    _loadPresencaData();
  }

  void _nextDay() {
    final hoje = DateTime.now();
    final amanha = DateTime(hoje.year, hoje.month, hoje.day + 1);
    if (_dataSel.isBefore(amanha)) {
      setState(() { _dataSel = _dataSel.add(const Duration(days: 1)); _presentesNaData.clear(); });
      _loadPresencaData();
    }
  }

  bool get _isHoje {
    final hoje = DateTime.now();
    return _dataSel.year == hoje.year && _dataSel.month == hoje.month && _dataSel.day == hoje.day;
  }

  Future<void> _loadPresencaData() async {
    setState(() => _loadingPresenca = true);
    try {
      // Buscar o horarioId do dia da semana selecionado
      final horarios = (_turma?['horarios'] as List? ?? []).cast<Map<String, dynamic>>();
      final diaSemana = _dataSel.weekday % 7; // 0=Dom,1=Seg,...,6=Sab (mesmo que DiaSemana do backend)
      final horario = horarios.firstWhere(
        (h) => (h['diaSemana'] as num?)?.toInt() == diaSemana,
        orElse: () => horarios.isNotEmpty ? horarios.first : {},
      );
      final horarioId = horario['id']?.toString() ?? '';
      if (horarioId.isEmpty) {
        if (mounted) setState(() { _presentesNaData = {}; _loadingPresenca = false; });
        return;
      }
      final res = await dio.get('/api/presencas/aula', queryParameters: {'horarioId': horarioId, 'data': _dataStr});
      final lista = (res.data['dados'] as List? ?? []).cast<Map<String, dynamic>>();
      final presentes = lista.map((p) => (p['alunoId'] ?? '').toString()).toSet();
      if (mounted) setState(() => _presentesNaData = presentes);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingPresenca = false);
    }
  }

  Future<void> _marcarPresenca(String alunoId) async {
    if (_marcando.contains(alunoId)) return;
    setState(() => _marcando.add(alunoId));
    try {
      await dio.post('/api/presencas', data: {
        'alunoId': alunoId,
        'turmaId': widget.turmaId,
        'data': _dataStr,
      });
      if (mounted) {
        setState(() => _presentesNaData.add(alunoId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Presença registrada!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      String msg = 'Erro ao registrar presença.';
      try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _marcando.remove(alunoId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _turma;
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
        title: Text(t?['nome'] ?? 'Turma', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
        actions: [
          if (t != null)
            IconButton(
              icon: Icon(Icons.edit_rounded, color: kText2, size: 20),
              tooltip: 'Editar turma',
              onPressed: () async {
                final editou = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => TurmaFormSheet(turma: t),
                );
                if (editou == true) _load();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: kPrimary,
          unselectedLabelColor: kText2,
          indicatorColor: kPrimary,
          tabs: const [
            Tab(text: 'Alunos'),
            Tab(text: 'Presença'),
            Tab(text: 'Horários'),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kPrimary))
          : _erro != null
              ? Center(child: Text(_erro!, style: TextStyle(color: kDanger)))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _abaAlunos(),
                    _abaPresenca(),
                    _abaHorarios(),
                  ],
                ),
    );
  }

  // ── ABA ALUNOS ────────────────────────────────────────

  Widget _abaAlunos() {
    final t = _turma;
    return Column(
      children: [
        if (t != null) _buildHeader(t),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text('Alunos matriculados', style: TextStyle(color: kText2, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${_filtrados.length}', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _mostrarQrTurma,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: kSuccess.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.qr_code_rounded, color: kSuccess, size: 16),
                    const SizedBox(width: 5),
                    Text('QR', style: TextStyle(color: kSuccess, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _abrirMatricula,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_add_rounded, color: kPrimary, size: 16),
                    const SizedBox(width: 5),
                    Text('Matricular', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filtrados.isEmpty
              ? Center(child: Text('Nenhum aluno matriculado.', style: TextStyle(color: kText2)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtrados.length,
                    itemBuilder: (_, i) => _buildAlunoCard(_filtrados[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(Map<String, dynamic> t) {
    final ativa = t['ativo'] == true;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((t['modalidadeNome'] as String?)?.isNotEmpty == true)
                      Text(t['modalidadeNome'], style: TextStyle(color: kText2, fontSize: 12)),
                    if ((t['professorNome'] as String?)?.isNotEmpty == true)
                      Text('Prof. ${t['professorNome']}', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ativa ? kSuccess.withOpacity(0.15) : kText2.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(ativa ? 'Ativa' : 'Inativa',
                    style: TextStyle(color: ativa ? kSuccess : kText2, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${t['totalAlunos'] ?? _alunos.length} / ${t['capacidadeMaxima'] ?? 0} alunos',
            style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAlunoCard(Map<String, dynamic> a) {
    final alunoId = a['alunoId']?.toString() ?? '';
    final nome = a['nomeAluno'] as String? ?? '';
    final count = _presencaCount[alunoId] ?? 0;
    final apto = _aptosGraduar.contains(alunoId);
    final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return Dismissible(
      key: Key(alunoId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: kDanger.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.person_remove_rounded, color: kDanger),
      ),
      confirmDismiss: (_) async {
        await _desmatricularAluno(a);
        return false;
      },
      child: GestureDetector(
        onTap: alunoId.isNotEmpty ? () => context.push('/admin/alunos/$alunoId') : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: apto ? kSuccess.withOpacity(0.05) : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: apto ? kSuccess.withOpacity(0.4) : kBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: (apto ? kSuccess : kPrimary).withOpacity(0.2),
                child: Text(initials.isEmpty ? '?' : initials,
                    style: TextStyle(color: apto ? kSuccess : kPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
                    if (apto)
                      Text('Apto para graduar', style: TextStyle(color: kSuccess, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Text('$count', style: TextStyle(color: kPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                    Text('presenças', style: TextStyle(color: kText2, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ABA PRESENÇA ──────────────────────────────────────

  Widget _abaPresenca() {
    return Column(
      children: [
        // Seletor de data — setas prev/next + toque no centro abre calendário
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimary.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _prevDay,
                  icon: Icon(Icons.chevron_left_rounded, color: kPrimary, size: 26),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_rounded, color: kPrimary, size: 16),
                          const SizedBox(width: 8),
                          Text(_dataLabel, style: TextStyle(color: kPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isHoje ? null : _nextDay,
                  icon: Icon(Icons.chevron_right_rounded, color: _isHoje ? kBorder : kPrimary, size: 26),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Text('Marque quem compareceu', style: TextStyle(color: kText2, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${_presentesNaData.length} presente(s)', style: TextStyle(color: kSuccess, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        if (_loadingPresenca)
          const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
        else
          Expanded(
            child: _alunos.isEmpty
                ? Center(child: Text('Nenhum aluno matriculado.', style: TextStyle(color: kText2)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _alunos.length,
                    itemBuilder: (_, i) => _buildPresencaCard(_alunos[i]),
                  ),
          ),
      ],
    );
  }

  // ── MATRÍCULA ─────────────────────────────────────────

  Future<void> _abrirMatricula() async {
    final turmaId = widget.turmaId;
    final alunosNaTurma = _alunos.map((a) => a['alunoId']?.toString() ?? '').toSet();

    final matriculou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MatriculaSheet(turmaId: turmaId, alunosJaMatriculados: alunosNaTurma),
    );
    if (matriculou == true) _load();
  }

  Future<void> _desmatricularAluno(Map<String, dynamic> a) async {
    final nome = a['nomeAluno'] as String? ?? '';
    final matriculaId = a['matriculaId']?.toString() ?? '';
    if (matriculaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('ID de matrícula não encontrado.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Remover aluno', style: TextStyle(color: kText1)),
        content: Text('Deseja remover $nome desta turma?', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Remover', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await dio.delete('/api/matriculas/$matriculaId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nome removido da turma.'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating),
        );
        _load();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao remover aluno.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ── ABA HORÁRIOS ──────────────────────────────────────

  static const _diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  Widget _abaHorarios() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Text('Horários da turma', style: TextStyle(color: kText2, fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => _abrirHorarioForm(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: kPrimary, size: 14),
                  const SizedBox(width: 4),
                  Text('Novo horário', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
        ),
        Expanded(
          child: _horarios.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.schedule_rounded, color: kText2, size: 48),
                    const SizedBox(height: 12),
                    Text('Nenhum horário cadastrado', style: TextStyle(color: kText2, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _abrirHorarioForm(),
                      child: Text('Adicionar horário', style: TextStyle(color: kPrimary)),
                    ),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _horarios.length,
                  itemBuilder: (_, i) => _buildHorarioCard(_horarios[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildHorarioCard(Map<String, dynamic> h) {
    final dia = (h['diaSemana'] as num?)?.toInt() ?? 0;
    final diaLabel = dia >= 0 && dia < _diasSemana.length ? _diasSemana[dia] : '?';
    final inicio = h['horaInicio']?.toString().substring(0, 5) ?? '--:--';
    final fim = h['horaFim']?.toString().substring(0, 5) ?? '--:--';
    final sala = h['sala'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(diaLabel, style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$inicio – $fim', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
            if (sala != null && sala.isNotEmpty)
              Text('Sala: $sala', style: TextStyle(color: kText2, fontSize: 12)),
          ]),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(
            onTap: () => _abrirHorarioForm(horario: h),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.edit_rounded, color: kPrimary, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _deletarHorario(h),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: kDanger.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.delete_outline_rounded, color: kDanger, size: 16),
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _abrirHorarioForm({Map<String, dynamic>? horario}) async {
    final turmaId = widget.turmaId;
    final salvou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HorarioFormSheet(turmaId: turmaId, horario: horario),
    );
    if (salvou == true) _load();
  }

  Future<void> _deletarHorario(Map<String, dynamic> h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Remover horário', style: TextStyle(color: kText1)),
        content: Text('Deseja remover este horário da turma?', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Remover', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await dio.delete('/api/horarios/${h['id']}');
      if (mounted) _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao remover horário.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Widget _buildPresencaCard(Map<String, dynamic> a) {
    final alunoId = a['alunoId']?.toString() ?? '';
    final nome = a['nomeAluno'] as String? ?? '';
    final presente = _presentesNaData.contains(alunoId);
    final carregando = _marcando.contains(alunoId);
    final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: presente ? kSuccess.withOpacity(0.05) : kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: presente ? kSuccess.withOpacity(0.4) : kBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: presente ? kSuccess.withOpacity(0.2) : kPrimary.withOpacity(0.2),
            child: Text(initials.isEmpty ? '?' : initials,
                style: TextStyle(color: presente ? kSuccess : kPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(nome, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          if (presente)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: kSuccess.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: kSuccess, size: 14),
                  const SizedBox(width: 4),
                  Text('Presente', style: TextStyle(color: kSuccess, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            )
          else
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: carregando ? null : () => _marcarPresenca(alunoId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                child: carregando
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Marcar'),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sheet: Matricular aluno ──────────────────────────────────────────────────

class _MatriculaSheet extends StatefulWidget {
  final String turmaId;
  final Set<String> alunosJaMatriculados;
  const _MatriculaSheet({required this.turmaId, required this.alunosJaMatriculados});

  @override
  State<_MatriculaSheet> createState() => _MatriculaSheetState();
}

class _MatriculaSheetState extends State<_MatriculaSheet> {
  final _busca = TextEditingController();
  List<Map<String, dynamic>> _todos = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _loading = true;
  bool _salvando = false;
  String? _selecionadoId;

  @override
  void initState() {
    super.initState();
    _busca.addListener(_filtrar);
    _load();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await dio.get('/api/alunos', queryParameters: {'pageSize': 200, 'ativo': true});
      final dados = res.data['dados'];
      final list = dados is List ? dados : (dados is Map ? (dados['itens'] as List? ?? []) : []);
      final todos = list.cast<Map<String, dynamic>>();
      final disponiveis = todos.where((a) => !widget.alunosJaMatriculados.contains(a['id']?.toString() ?? '')).toList();
      if (mounted) {
        setState(() {
          _todos = disponiveis;
          _filtrar();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filtrar() {
    final q = _busca.text.trim().toLowerCase();
    setState(() {
      _filtrados = q.isEmpty
          ? List.from(_todos)
          : _todos.where((a) => (a['nome'] as String? ?? '').toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _matricular() async {
    if (_selecionadoId == null) return;
    setState(() => _salvando = true);
    try {
      await dio.post('/api/matriculas', data: {
        'alunoId': _selecionadoId,
        'turmaId': widget.turmaId,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      String msg = 'Erro ao matricular aluno.';
      try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(color: kBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(children: [
            Text('Matricular aluno', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (_salvando)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              TextButton(
                onPressed: _selecionadoId == null ? null : _matricular,
                style: TextButton.styleFrom(
                  backgroundColor: _selecionadoId != null ? kPrimary.withOpacity(0.12) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Confirmar', style: TextStyle(color: _selecionadoId != null ? kPrimary : kText2, fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _busca,
            style: TextStyle(color: kText1),
            decoration: InputDecoration(
              hintText: 'Buscar aluno...',
              hintStyle: TextStyle(color: kText2),
              prefixIcon: Icon(Icons.search, color: kText2),
              filled: true, fillColor: kSurface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: CircularProgressIndicator())
          else if (_filtrados.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text('Nenhum aluno disponível.', style: TextStyle(color: kText2)),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtrados.length,
                itemBuilder: (_, i) {
                  final a = _filtrados[i];
                  final id = a['id']?.toString() ?? '';
                  final nome = a['nome'] as String? ?? '';
                  final sel = _selecionadoId == id;
                  return GestureDetector(
                    onTap: () => setState(() => _selecionadoId = sel ? null : id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary.withOpacity(0.12) : kSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? kPrimary : kBorder),
                      ),
                      child: Row(children: [
                        Expanded(child: Text(nome, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600))),
                        if (sel) Icon(Icons.check_circle_rounded, color: kPrimary, size: 18),
                      ]),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sheet: Formulário de Horário ─────────────────────────────────────────────

class _HorarioFormSheet extends StatefulWidget {
  final String turmaId;
  final Map<String, dynamic>? horario;
  const _HorarioFormSheet({required this.turmaId, this.horario});

  @override
  State<_HorarioFormSheet> createState() => _HorarioFormSheetState();
}

class _HorarioFormSheetState extends State<_HorarioFormSheet> {
  static const _dias = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
  final _salaCtrl = TextEditingController();

  int? _diaSemana;
  TimeOfDay? _inicio;
  TimeOfDay? _fim;
  bool _salvando = false;

  bool get _editando => widget.horario != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      final h = widget.horario!;
      _diaSemana = (h['diaSemana'] as num?)?.toInt();
      _salaCtrl.text = h['sala'] as String? ?? '';
      final inicioStr = h['horaInicio']?.toString() ?? '';
      final fimStr = h['horaFim']?.toString() ?? '';
      if (inicioStr.length >= 5) {
        final parts = inicioStr.split(':');
        _inicio = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
      }
      if (fimStr.length >= 5) {
        final parts = fimStr.split(':');
        _fim = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
      }
    }
  }

  @override
  void dispose() {
    _salaCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickTime(bool isInicio) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isInicio ? (_inicio ?? const TimeOfDay(hour: 8, minute: 0)) : (_fim ?? const TimeOfDay(hour: 9, minute: 0)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: kPrimary, surface: kSurface)),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => isInicio ? _inicio = picked : _fim = picked);
  }

  Future<void> _salvar() async {
    if (_diaSemana == null || _inicio == null || _fim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Preencha dia, horário de início e fim.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final body = {
        'turmaId': widget.turmaId,
        'diaSemana': _diaSemana,
        'horaInicio': _formatTime(_inicio!),
        'horaFim': _formatTime(_fim!),
        if (_salaCtrl.text.trim().isNotEmpty) 'sala': _salaCtrl.text.trim(),
      };
      if (_editando) {
        await dio.put('/api/horarios/${widget.horario!['id']}', data: body);
      } else {
        await dio.post('/api/horarios', data: body);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      String msg = _editando ? 'Erro ao editar horário.' : 'Erro ao criar horário.';
      try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(color: kBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(children: [
            Text(_editando ? 'Editar Horário' : 'Novo Horário', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (_salvando)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              TextButton(
                onPressed: _salvar,
                style: TextButton.styleFrom(
                  backgroundColor: kPrimary.withOpacity(0.12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Salvar', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 20),
          // Dia da semana
          DropdownButtonFormField<int>(
            value: _diaSemana,
            decoration: InputDecoration(
              labelText: 'Dia da semana',
              labelStyle: TextStyle(color: kText2, fontSize: 13),
              prefixIcon: Icon(Icons.calendar_today_rounded, color: kText2, size: 18),
              filled: true, fillColor: kSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            dropdownColor: kSurface,
            style: TextStyle(color: kText1, fontSize: 15),
            items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text(_dias[i], style: TextStyle(color: kText1)))),
            onChanged: (v) => setState(() => _diaSemana = v),
          ),
          const SizedBox(height: 14),
          // Horários
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickTime(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder),
                  ),
                  child: Row(children: [
                    Icon(Icons.access_time_rounded, color: kText2, size: 18),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Início', style: TextStyle(color: kText2, fontSize: 11)),
                      Text(
                        _inicio != null ? _formatTime(_inicio!).substring(0, 5) : '--:--',
                        style: TextStyle(color: _inicio != null ? kText1 : kText2, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickTime(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder),
                  ),
                  child: Row(children: [
                    Icon(Icons.access_time_filled_rounded, color: kText2, size: 18),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Fim', style: TextStyle(color: kText2, fontSize: 11)),
                      Text(
                        _fim != null ? _formatTime(_fim!).substring(0, 5) : '--:--',
                        style: TextStyle(color: _fim != null ? kText1 : kText2, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          TextFormField(
            controller: _salaCtrl,
            style: TextStyle(color: kText1, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Sala (opcional)',
              labelStyle: TextStyle(color: kText2, fontSize: 13),
              prefixIcon: Icon(Icons.room_rounded, color: kText2, size: 18),
              filled: true, fillColor: kSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
