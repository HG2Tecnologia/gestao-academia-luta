import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/ad_banner.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';
import '../../core/graduacao_order.dart';
import '../../core/turma_service.dart';
import '../../core/widgets.dart';
import 'turmas_screen.dart' show TurmaFormSheet;

/// Critérios de ordenação da lista de alunos da turma.
enum _OrdAlunos {
  manual,
  nomeAsc,
  nomeDesc,
  graduacaoDesc,
  graduacaoAsc,
  matriculaAntiga,
  matriculaNova,
  presencasDesc,
  presencasAsc,
}

const _labelsOrd = <_OrdAlunos, String>{
  _OrdAlunos.manual: 'Ordem personalizada',
  _OrdAlunos.nomeAsc: 'Nome (A–Z)',
  _OrdAlunos.nomeDesc: 'Nome (Z–A)',
  _OrdAlunos.graduacaoDesc: 'Graduação (mais alta)',
  _OrdAlunos.graduacaoAsc: 'Graduação (mais baixa)',
  _OrdAlunos.matriculaAntiga: 'Matrícula (mais antiga)',
  _OrdAlunos.matriculaNova: 'Matrícula (mais recente)',
  _OrdAlunos.presencasDesc: 'Mais presenças',
  _OrdAlunos.presencasAsc: 'Menos presenças',
};

class AdminTurmaDetalheScreen extends StatefulWidget {
  final String turmaId;

  /// Quando `true`, a tela é aberta pelo app do professor: esconde os controles
  /// de gestão da turma (editar/excluir turma, matricular/desmatricular, criar/
  /// editar/excluir horário) e navega para os alunos pela rota `/professor/...`.
  final bool professorMode;

  const AdminTurmaDetalheScreen({
    super.key,
    required this.turmaId,
    this.professorMode = false,
  });

  @override
  State<AdminTurmaDetalheScreen> createState() =>
      _AdminTurmaDetalheScreenState();
}

class _AdminTurmaDetalheScreenState extends State<AdminTurmaDetalheScreen>
    with SingleTickerProviderStateMixin {
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
  Map<String, String> _presencaIds = {}; // alunoId -> presencaId
  final Set<String> _marcando = {};

  Set<String> _aptosGraduar = {};

  // Ordenação / reordenação manual da lista de alunos
  _OrdAlunos _ordenacao = _OrdAlunos.nomeAsc;
  bool _ordenacaoInicializada = false;
  bool _temOrdemManual = false;
  bool _podeReordenar = false;
  bool _reordenando = false;
  bool _salvandoOrdem = false;
  String? _turmaModalidadeId;

  bool _loading = true;
  bool _loadingPresenca = false;
  String? _erro;
  String? _academiaId;

  // Modo professor: permissões concedidas pela academia.
  bool _podeDarPresenca = true;

  bool get _pm => widget.professorMode;

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
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId ?? '';
      if (_academiaId!.isEmpty) throw Exception('Academia não encontrada');

      _podeDarPresenca =
          !_pm || (user?.temPermissao('acao_dar_presenca') ?? false);

      final hoje = DateTime.now();
      final cutoff = hoje.subtract(const Duration(days: 180));

      // Load turma data, presencas, matriculas e alunos em paralelo
      final results = await Future.wait([
        firestoreService.getTurma(_academiaId!, widget.turmaId),
        firestoreService.getPresencas(_academiaId!, turmaId: widget.turmaId),
        firestoreService.getHorarios(_academiaId!, turmaId: widget.turmaId),
        firestoreService.getAptosGraduacao(_academiaId!),
        firestoreService.getMatriculas(
          _academiaId!,
          turmaId: widget.turmaId,
          ativasOnly: false,
        ),
        firestoreService.getAlunos(_academiaId!),
        firestoreService.getGraduacoes(_academiaId!, detalhadas: true),
      ]);

      final turmaData = results[0] as Map<String, dynamic>?;
      if (turmaData == null) throw Exception('Turma não encontrada');

      final presencas = (results[1] as List).cast<Map<String, dynamic>>();
      final horariosList = (results[2] as List).cast<Map<String, dynamic>>();
      final aptosGrad = (results[3] as List).cast<Map<String, dynamic>>();

      // Monta lista de alunos a partir das matrículas + join com dados do aluno
      final matriculas = (results[4] as List).cast<Map<String, dynamic>>();
      final todosAlunos = (results[5] as List).cast<Map<String, dynamic>>();
      final graduacoes = (results[6] as List).cast<Map<String, dynamic>>();
      final faixasAtuaisPorAluno = montarFaixasAtuaisPorAluno(graduacoes);

      final alunoMap = <String, Map<String, dynamic>>{
        for (final a in todosAlunos) a['id'].toString(): a,
      };
      final alunosList = matriculas
          .map((m) {
            final alunoId = m['aluno_id']?.toString() ?? '';
            final aluno = alunoMap[alunoId] ?? {};
            return <String, dynamic>{
              ...aluno,
              'faixasAtuais': faixasAtuaisPorAluno[alunoId] ?? const {},
              'matriculaId': m['id'],
              'alunoId': alunoId,
              'ordem': m['ordem'],
              'matriculaCriadoEm': m['criado_em'] ?? m['criadoEm'],
              'nome': aluno['nome'] ?? '',
              'nomeAluno': aluno['nome'] ?? '',
            };
          })
          .where((a) {
            if ((a['alunoId'] as String).isEmpty) return false;
            // Oculta alunos inativos da lista da turma
            if (a['ativo'] == false) return false;
            return true;
          })
          .toList();

      // Compute 180-day presença count per aluno for this turma
      final countMap = <String, int>{};
      for (final p in presencas) {
        final dataStr =
            p['data'] as String? ?? p['data_presenca'] as String? ?? '';
        if (dataStr.isEmpty) continue;
        try {
          final d = DateTime.parse(dataStr);
          if (d.isAfter(cutoff)) {
            final alunoId =
                p['aluno_id']?.toString() ?? p['alunoId']?.toString() ?? '';
            if (alunoId.isNotEmpty) {
              countMap[alunoId] = (countMap[alunoId] ?? 0) + 1;
            }
          }
        } catch (_) {}
      }

      // Build aptos set
      final aptosSet = aptosGrad
          .map(
            (a) => a['alunoId']?.toString() ?? a['aluno_id']?.toString() ?? '',
          )
          .where((id) => id.isNotEmpty)
          .toSet();

      final meuId = user?.id ?? '';
      final temOrdemManual = matriculas.any((m) => m['ordem'] != null);

      if (mounted) {
        setState(() {
          _turma = turmaData;
          _turmaModalidadeId =
              (turmaData['modalidadeId'] ?? turmaData['modalidade_id'])
                  ?.toString();
          _alunos = alunosList;
          _presencaCount = countMap;
          _horarios = horariosList;
          _aptosGraduar = aptosSet;
          _temOrdemManual = temOrdemManual;
          _podeReordenar = !_pm ||
              (user?.temPermissao('acesso_turmas_todas') ?? false) ||
              (turmaData['professorId']?.toString() == meuId);
          if (!_ordenacaoInicializada) {
            _ordenacao =
                temOrdemManual ? _OrdAlunos.manual : _OrdAlunos.nomeAsc;
            _ordenacaoInicializada = true;
          }
          _reordenando = false;
          _recomputarFiltrados();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _erro = 'Erro ao carregar turma');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Exclusão lógica (soft delete) via transação server-side: o histórico
  /// (presenças, graduações, horários) permanece íntegro; só as matrículas
  /// ativas são encerradas e a turma some das listagens operacionais.
  Future<void> _excluirTurma() async {
    final academiaId = _academiaId;
    if (academiaId == null) return;
    final nome = _turma?['nome']?.toString() ?? 'esta turma';
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: kSurface,
            title: Text(
              'Excluir "$nome"?',
              style: TextStyle(
                color: kText1,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            content: Text(
              'A turma some das listagens ativas e as matrículas em aberto são encerradas. '
              'Alunos, presenças e graduações continuam no histórico — nada é apagado.',
              style: TextStyle(color: kText2, fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancelar', style: TextStyle(color: kText2)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Excluir',
                  style: TextStyle(color: kDanger, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;

    // Capturados ANTES do showDialog: showDialog abre no Navigator RAIZ por
    // padrão, mas esta tela pode estar dentro de um Navigator aninhado (shell
    // do admin). Um Navigator.of(context).pop() sem `rootNavigator: true`
    // resolve o Navigator aninhado, não o raiz — popava a própria tela em vez
    // de fechar o loading, que ficava órfão e preso na tela (tudo escuro,
    // sem clique) igual foi reportado.
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final resultado = await TurmaService.arquivarTurma(
        academiaId: academiaId,
        turmaId: widget.turmaId,
      );
      rootNavigator.pop(); // fecha o loading
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(); // volta pra lista — a turma não existe mais nela
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            resultado.matriculasEncerradas > 0
                ? 'Turma excluída. ${resultado.matriculasEncerradas} matrícula(s) encerrada(s).'
                : 'Turma excluída.',
          ),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      rootNavigator.pop(); // fecha o loading
      String msg = 'Erro ao excluir turma.';
      if (e is FirebaseFunctionsException) msg = e.message ?? msg;
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: kDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _mostrarQrTurma() async {
    final turmaId = widget.turmaId;
    final qrData = turmaId;
    if (!mounted) return;

    final nomeTurma = _turma?['nome'] ?? 'Turma';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'QR Code da Turma',
              style: TextStyle(
                color: kText1,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(nomeTurma, style: TextStyle(color: kText2, fontSize: 13)),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: 'TURMA:$qrData',
                  version: QrVersions.auto,
                  size: 190,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Alunos escaneiam para registrar presença',
              style: TextStyle(color: kText2, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            Text(
              'Válido apenas no horário da aula',
              style: TextStyle(color: kText2, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _filtrar() => setState(_recomputarFiltrados);

  /// Recalcula `_filtrados` (busca + ordenação). Não chama setState — use
  /// dentro de um setState existente ou via [_filtrar].
  void _recomputarFiltrados() {
    if (_reordenando) return;
    final q = _ctrl.text.trim().toLowerCase();
    final base = q.isEmpty
        ? List<Map<String, dynamic>>.from(_alunos)
        : _alunos
            .where((a) => _nomeDe(a).toLowerCase().contains(q))
            .toList();
    _filtrados = _ordenar(base);
  }

  String _nomeDe(Map<String, dynamic> a) =>
      (a['nomeAluno'] ?? a['nome_aluno'] ?? a['nome'] ?? '').toString();

  String _idDe(Map<String, dynamic> a) =>
      (a['alunoId'] ?? a['aluno_id'] ?? '').toString();

  int _cmpNome(Map<String, dynamic> a, Map<String, dynamic> b) =>
      _nomeDe(a).toLowerCase().compareTo(_nomeDe(b).toLowerCase());

  /// Peso da graduação do aluno na modalidade DESTA turma (faixa + grau).
  /// -1 quando não há faixa registrada nessa modalidade.
  int _pesoGraduacao(Map<String, dynamic> a) {
    final fa = a['faixasAtuais'];
    final modId = _turmaModalidadeId;
    if (fa is Map && modId != null && fa[modId] is Map) {
      final m = fa[modId] as Map;
      final ordem = (m['faixaOrdem'] as num?)?.toInt() ?? 0;
      final grau = (m['grau'] as num?)?.toInt() ?? 0;
      return ordem * 100 + grau;
    }
    return -1;
  }

  DateTime _matriculaEm(Map<String, dynamic> a) =>
      DateTime.tryParse(a['matriculaCriadoEm']?.toString() ?? '') ??
      DateTime(2000);

  int _pesoManual(Map<String, dynamic> a) =>
      (a['ordem'] as num?)?.toInt() ?? 1000000;

  int _presencasDe(Map<String, dynamic> a) => _presencaCount[_idDe(a)] ?? 0;

  List<Map<String, dynamic>> _ordenar(List<Map<String, dynamic>> src) {
    final l = List<Map<String, dynamic>>.from(src);
    int tie(int c, Map<String, dynamic> a, Map<String, dynamic> b) =>
        c != 0 ? c : _cmpNome(a, b);
    switch (_ordenacao) {
      case _OrdAlunos.manual:
        l.sort((a, b) => tie(_pesoManual(a).compareTo(_pesoManual(b)), a, b));
      case _OrdAlunos.nomeAsc:
        l.sort(_cmpNome);
      case _OrdAlunos.nomeDesc:
        l.sort((a, b) => _cmpNome(b, a));
      case _OrdAlunos.graduacaoDesc:
        l.sort((a, b) =>
            tie(_pesoGraduacao(b).compareTo(_pesoGraduacao(a)), a, b));
      case _OrdAlunos.graduacaoAsc:
        l.sort((a, b) =>
            tie(_pesoGraduacao(a).compareTo(_pesoGraduacao(b)), a, b));
      case _OrdAlunos.matriculaAntiga:
        l.sort((a, b) => tie(_matriculaEm(a).compareTo(_matriculaEm(b)), a, b));
      case _OrdAlunos.matriculaNova:
        l.sort((a, b) => tie(_matriculaEm(b).compareTo(_matriculaEm(a)), a, b));
      case _OrdAlunos.presencasDesc:
        l.sort((a, b) => tie(_presencasDe(b).compareTo(_presencasDe(a)), a, b));
      case _OrdAlunos.presencasAsc:
        l.sort((a, b) => tie(_presencasDe(a).compareTo(_presencasDe(b)), a, b));
    }
    return l;
  }

  void _abrirMenuOrdenacao() {
    final opcoes = <_OrdAlunos>[
      if (_temOrdemManual) _OrdAlunos.manual,
      _OrdAlunos.nomeAsc,
      _OrdAlunos.nomeDesc,
      _OrdAlunos.graduacaoDesc,
      _OrdAlunos.graduacaoAsc,
      _OrdAlunos.matriculaAntiga,
      _OrdAlunos.matriculaNova,
      _OrdAlunos.presencasDesc,
      _OrdAlunos.presencasAsc,
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text(
              'Ordenar alunos',
              style: TextStyle(
                color: kText1,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final o in opcoes)
              ListTile(
                dense: true,
                leading: Icon(
                  _ordenacao == o
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _ordenacao == o ? kPrimary : kText2,
                  size: 20,
                ),
                title: Text(
                  _labelsOrd[o]!,
                  style: TextStyle(color: kText1, fontSize: 13.5),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _ordenacao = o;
                    _recomputarFiltrados();
                  });
                },
              ),
            if (_podeReordenar) ...[
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.swap_vert_rounded, color: kPrimary),
                title: Text(
                  'Reordenar arrastando',
                  style: TextStyle(
                    color: kPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Segure e arraste os alunos para montar a ordem da turma',
                  style: TextStyle(color: kText2, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _entrarReordenar();
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }

  void _entrarReordenar() {
    _ctrl.clear();
    setState(() {
      _ordenacao = _OrdAlunos.manual;
      _reordenando = false; // garante que _ordenar rode abaixo
      _recomputarFiltrados();
      _reordenando = true;
    });
  }

  void _cancelarReordenar() {
    setState(() => _reordenando = false);
    _filtrar();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _filtrados.removeAt(oldIndex);
      _filtrados.insert(newIndex, item);
    });
  }

  Future<void> _salvarOrdemManual() async {
    setState(() => _salvandoOrdem = true);
    try {
      final ids = _filtrados
          .map((a) => a['matriculaId']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      await firestoreService.salvarOrdemMatriculas(_academiaId!, ids);
      // Reflete o novo índice nos mapas (compartilhados com _alunos).
      for (var i = 0; i < _filtrados.length; i++) {
        _filtrados[i]['ordem'] = i;
      }
      setState(() {
        _temOrdemManual = true;
        _reordenando = false;
        _ordenacao = _OrdAlunos.manual;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ordem da turma salva.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a ordem.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvandoOrdem = false);
    }
  }

  // ── Aba Presença ─────────────────────────────────────

  String get _dataStr =>
      '${_dataSel.year}-${_dataSel.month.toString().padLeft(2, '0')}-${_dataSel.day.toString().padLeft(2, '0')}';

  String get _dataLabel {
    final hoje = DateTime.now();
    final diff = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    ).difference(DateTime(_dataSel.year, _dataSel.month, _dataSel.day)).inDays;
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
      setState(() {
        _dataSel = picked;
        _presentesNaData.clear();
      });
      _loadPresencaData();
    }
  }

  void _prevDay() {
    setState(() {
      _dataSel = _dataSel.subtract(const Duration(days: 1));
      _presentesNaData.clear();
    });
    _loadPresencaData();
  }

  void _nextDay() {
    final hoje = DateTime.now();
    final amanha = DateTime(hoje.year, hoje.month, hoje.day + 1);
    if (_dataSel.isBefore(amanha)) {
      setState(() {
        _dataSel = _dataSel.add(const Duration(days: 1));
        _presentesNaData.clear();
      });
      _loadPresencaData();
    }
  }

  bool get _isHoje {
    final hoje = DateTime.now();
    return _dataSel.year == hoje.year &&
        _dataSel.month == hoje.month &&
        _dataSel.day == hoje.day;
  }

  Future<void> _loadPresencaData() async {
    if (_academiaId == null) return;
    setState(() => _loadingPresenca = true);
    try {
      final presencas = await firestoreService.getPresencas(
        _academiaId!,
        turmaId: widget.turmaId,
      );
      final presentes = <String>{};
      final ids = <String, String>{};
      for (final p in presencas.cast<Map<String, dynamic>>()) {
        final dataStr =
            p['data'] as String? ?? p['data_presenca'] as String? ?? '';
        if (!dataStr.startsWith(_dataStr)) continue;
        final alunoId = (p['aluno_id'] ?? p['alunoId'] ?? '').toString();
        if (alunoId.isEmpty) continue;
        presentes.add(alunoId);
        final pid = p['id']?.toString() ?? '';
        if (pid.isNotEmpty) ids[alunoId] = pid;
      }
      if (mounted)
        setState(() {
          _presentesNaData = presentes;
          _presencaIds = ids;
        });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPresenca = false);
    }
  }

  static const _diasNomes = [
    'Domingo',
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
  ];

  // Converte DateTime.weekday (1=Mon..7=Sun) para índice Firestore (0=Dom..6=Sáb)
  int _dartDiaToFirestore(int weekday) => weekday % 7;

  bool get _dataNoDiaDaTurma {
    final idx = _dartDiaToFirestore(_dataSel.weekday);
    return _horarios.any(
      (h) => (h['diaSemana'] ?? h['dia_semana'] as num?)?.toInt() == idx,
    );
  }

  Future<void> _marcarPresenca(String alunoId) async {
    if (_marcando.contains(alunoId) || _academiaId == null) return;

    // Verifica se a data selecionada é um dia de treino dessa turma
    if (!_dataNoDiaDaTurma) {
      final diaLabel = _diasNomes[_dartDiaToFirestore(_dataSel.weekday)];
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kSurface,
          title: Text(
            'Dia fora do horário',
            style: TextStyle(color: kText1, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Hoje não é o dia de treino cadastrado para essa turma. Deseja mesmo confirmar presença para $diaLabel?',
            style: TextStyle(color: kText2),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancelar', style: TextStyle(color: kText2)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Confirmar assim mesmo',
                style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }

    setState(() => _marcando.add(alunoId));
    try {
      final now = DateTime.now();
      final horaStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
      final pid = await firestoreService.addPresenca(_academiaId!, {
        'aluno_id': alunoId,
        'turma_id': widget.turmaId,
        'data': _dataStr,
        'data_presenca': _dataStr,
        'hora_checkin': horaStr,
        'metodo_checkin': 2,
        'confirmado': true,
      });
      if (mounted) {
        setState(() {
          _presentesNaData.add(alunoId);
          if (pid.isNotEmpty) _presencaIds[alunoId] = pid;
          _presencaCount[alunoId] = (_presencaCount[alunoId] ?? 0) + 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Presença registrada!'),
            backgroundColor: kSuccess,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is CheckinBloqueadoException
                  ? e.mensagem
                  : 'Erro ao registrar presença.',
            ),
            backgroundColor: kDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _marcando.remove(alunoId));
    }
  }

  Future<void> _desmarcarPresenca(String alunoId, String nome) async {
    if (_academiaId == null) return;
    final pid = _presencaIds[alunoId];
    if (pid == null || pid.isEmpty) {
      // Sem ID local, recarrega para garantir
      await _loadPresencaData();
      final pid2 = _presencaIds[alunoId];
      if (pid2 == null || pid2.isEmpty) return;
      _desmarcarPresenca(alunoId, nome);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(
          'Desfazer presença',
          style: TextStyle(color: kText1, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Deseja remover a presença de $nome nesta data?',
          style: TextStyle(color: kText2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: kText2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remover',
              style: TextStyle(color: kDanger, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _marcando.add(alunoId));
    try {
      await firestoreService.deletePresenca(_academiaId!, pid);
      if (mounted) {
        setState(() {
          _presentesNaData.remove(alunoId);
          _presencaIds.remove(alunoId);
          _presencaCount[alunoId] = ((_presencaCount[alunoId] ?? 1) - 1).clamp(
            0,
            999999,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Presença removida.'),
            backgroundColor: kSuccess,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao remover presença.'),
            backgroundColor: kDanger,
            behavior: SnackBarBehavior.floating,
          ),
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
        title: Text(
          t?['nome'] ?? 'Turma',
          style: TextStyle(color: kText1, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!_pm && t != null && _academiaId != null)
            IconButton(
              icon: Icon(Icons.edit_rounded, color: kText2, size: 20),
              tooltip: 'Editar turma',
              onPressed: () async {
                final editou = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      TurmaFormSheet(academiaId: _academiaId!, turma: t),
                );
                if (editou == true) _load();
              },
            ),
          if (!_pm && t != null && _academiaId != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: kDanger,
                size: 20,
              ),
              tooltip: 'Excluir turma',
              onPressed: _excluirTurma,
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
          ? Center(
              child: Text(_erro!, style: TextStyle(color: kDanger)),
            )
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [_abaAlunos(), _abaPresenca(), _abaHorarios()],
                  ),
                ),
                const AdBannerWidget(),
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
        if (!_reordenando)
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kPrimary),
              ),
            ),
          ),
        ),
        if (_reordenando) _barraReordenar(),
        if (!_reordenando)
          Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text(
                'Alunos matriculados',
                style: TextStyle(
                  color: kText2,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_filtrados.length}',
                style: TextStyle(
                  color: kPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _mostrarQrTurma,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: kSuccess.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_rounded, color: kSuccess, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        'QR',
                        style: TextStyle(
                          color: kSuccess,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_pm) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _abrirMatricula,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_add_rounded,
                          color: kPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Matricular',
                          style: TextStyle(
                            color: kPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!_reordenando && _filtrados.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Material(
              color: kSurface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _abrirMenuOrdenacao,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swap_vert_rounded, color: kText2, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Ordenar: ',
                        style: TextStyle(color: kText2, fontSize: 13),
                      ),
                      Expanded(
                        child: Text(
                          _labelsOrd[_ordenacao] ?? '',
                          style: TextStyle(
                            color: kPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.expand_more_rounded,
                        color: kPrimary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: _filtrados.isEmpty
              ? Center(
                  child: Text(
                    'Nenhum aluno matriculado.',
                    style: TextStyle(color: kText2),
                  ),
                )
              : _reordenando
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _filtrados.length,
                      onReorder: _onReorder,
                      itemBuilder: (_, i) =>
                          _buildReorderTile(_filtrados[i], i),
                    )
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

  Widget _barraReordenar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimary.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator_rounded, color: kPrimary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Segure e arraste para reordenar',
              style: TextStyle(color: kText1, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: _salvandoOrdem ? null : _cancelarReordenar,
            child: Text('Cancelar', style: TextStyle(color: kText2)),
          ),
          ElevatedButton(
            onPressed: _salvandoOrdem ? null : _salvarOrdemManual,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: _salvandoOrdem
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderTile(Map<String, dynamic> a, int index) {
    final nome = _nomeDe(a);
    final foto = a['fotoBase64'] as String? ?? a['foto_base64'] as String?;
    final initials = nome
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    return Container(
      key: ValueKey('reord_${a['matriculaId'] ?? _idDe(a)}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator_rounded, color: kText2),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: kPrimary.withOpacity(0.2),
            backgroundImage: foto != null && foto.contains(',')
                ? MemoryImage(base64Decode(foto.split(',').last))
                : null,
            child: foto == null || !foto.contains(',')
                ? Text(
                    initials.isEmpty ? '?' : initials,
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nome,
              style: TextStyle(
                color: kText1,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${index + 1}',
            style: TextStyle(
              color: kText2,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> t) {
    final ativa = t['ativo'] == true;
    final modalidadeNome = t['modalidadeNome'] ?? t['nome_modalidade'] ?? '';
    final professorNome = t['professorNome'] ?? t['nome_professor'] ?? '';
    final cap = t['capacidadeMaxima'] ?? t['capacidade_maxima'] ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((modalidadeNome as String).isNotEmpty)
                      Text(
                        modalidadeNome,
                        style: TextStyle(color: kText2, fontSize: 12),
                      ),
                    if ((professorNome as String).isNotEmpty)
                      Text(
                        'Prof. $professorNome',
                        style: TextStyle(
                          color: kPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ativa
                      ? kSuccess.withOpacity(0.15)
                      : kText2.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ativa ? 'Ativa' : 'Inativa',
                  style: TextStyle(
                    color: ativa ? kSuccess : kText2,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${t['totalAlunos'] ?? _alunos.length} / $cap alunos',
            style: TextStyle(
              color: kText1,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseCor2(String? hex) {
    try {
      return Color(int.parse((hex ?? '').replaceAll('#', '0xFF')));
    } catch (_) {
      return kPrimary;
    }
  }

  Widget _buildAlunoCard(Map<String, dynamic> a) {
    final alunoId = a['alunoId']?.toString() ?? a['aluno_id']?.toString() ?? '';
    final nome = a['nomeAluno'] as String? ?? a['nome_aluno'] as String? ?? '';
    final count = _presencaCount[alunoId] ?? 0;
    final apto = _aptosGraduar.contains(alunoId);
    final initials = nome
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    final foto = a['fotoBase64'] as String? ?? a['foto_base64'] as String?;
    final faixasAtuaisMap = a['faixasAtuais'] as Map<String, dynamic>?;
    final faixasCount = faixasAtuaisMap?.length ?? 0;
    Map<String, dynamic>? primary;
    if (faixasAtuaisMap != null && faixasAtuaisMap.isNotEmpty) {
      final principalId = a['faixaPrincipalModalidadeId'] as String?;
      primary =
          (principalId != null && faixasAtuaisMap.containsKey(principalId)
                  ? faixasAtuaisMap[principalId]
                  : faixasAtuaisMap.values.first)
              as Map<String, dynamic>?;
    }
    final faixaCor = primary?['faixaCor'] as String?;
    final faixaNome = primary?['faixaNome'] as String?;
    final grauAtual = (primary?['grau'] as num?)?.toInt() ?? 0;
    final temGraus = primary?['faixaTemGraus'] == true || grauAtual > 0;
    final maxGrausRaw = (primary?['faixaMaxGraus'] as num?)?.toInt() ?? 4;
    final maxGraus = maxGrausRaw > 0
        ? maxGrausRaw
        : (grauAtual > 0 ? grauAtual : 4);

    final card = GestureDetector(
      onTap: alunoId.isNotEmpty
          ? () => context.push(
              _pm ? '/professor/alunos/$alunoId' : '/admin/alunos/$alunoId',
            )
          : null,
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
              backgroundImage: foto != null && foto.contains(',')
                  ? MemoryImage(base64Decode(foto.split(',').last))
                  : null,
              child: foto == null || !foto.contains(',')
                  ? Text(
                      initials.isEmpty ? '?' : initials,
                      style: TextStyle(
                        color: apto ? kSuccess : kPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: TextStyle(
                      color: kText1,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (faixaCor != null) ...[
                        BeltBadge(
                          cor: _parseCor2(faixaCor),
                          corBarra: _parseCor2('#000000'),
                          temGraus: temGraus,
                          grau: grauAtual,
                          maxGraus: maxGraus,
                          height: 12,
                          minWidth: 28,
                        ),
                        if (faixasCount > 1) ...[
                          const SizedBox(width: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '+${faixasCount - 1}',
                              style: TextStyle(
                                color: kPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 5),
                      ],
                      if (faixaNome != null)
                        Flexible(
                          child: Text(
                            grauAtual > 0
                                ? '$faixaNome · $grauAtual° Grau'
                                : faixaNome,
                            style: TextStyle(
                              color: apto ? kSuccess : kText2,
                              fontSize: 11,
                              fontWeight: apto
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else if (apto)
                        Text(
                          'Apto para graduar',
                          style: TextStyle(
                            color: kSuccess,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (faixaNome == null && !apto)
                        Text(
                          'Sem graduação',
                          style: TextStyle(color: kText2, fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'presenças',
                    style: TextStyle(color: kText2, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (_pm) return card;

    return Dismissible(
      key: Key(alunoId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: kDanger.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.person_remove_rounded, color: kDanger),
      ),
      confirmDismiss: (_) async {
        await _desmatricularAluno(a);
        return false;
      },
      child: card,
    );
  }

  // ── ABA PRESENÇA ──────────────────────────────────────

  Widget _abaPresenca() {
    return Column(
      children: [
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
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: kPrimary,
                    size: 26,
                  ),
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
                          Icon(
                            Icons.calendar_today_rounded,
                            color: kPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _dataLabel,
                            style: TextStyle(
                              color: kPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isHoje ? null : _nextDay,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: _isHoje ? kBorder : kPrimary,
                    size: 26,
                  ),
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
              Text(
                'Marque quem compareceu',
                style: TextStyle(
                  color: kText2,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_presentesNaData.length} presente(s)',
                  style: TextStyle(
                    color: kSuccess,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_loadingPresenca)
          const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          )
        else
          Expanded(
            child: _alunos.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum aluno matriculado.',
                      style: TextStyle(color: kText2),
                    ),
                  )
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
    if (_academiaId == null) return;
    final turmaId = widget.turmaId;
    final alunosNaTurma = _alunos
        .map((a) => (a['alunoId'] ?? a['aluno_id'] ?? '').toString())
        .toSet();

    final matriculou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MatriculaSheet(
        turmaId: turmaId,
        academiaId: _academiaId!,
        alunosJaMatriculados: alunosNaTurma,
      ),
    );
    if (matriculou == true) _load();
  }

  Future<void> _desmatricularAluno(Map<String, dynamic> a) async {
    if (_academiaId == null) return;
    final nome = a['nomeAluno'] as String? ?? a['nome_aluno'] as String? ?? '';
    final matriculaId =
        a['matriculaId']?.toString() ?? a['id']?.toString() ?? '';
    if (matriculaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ID de matrícula não encontrado.'),
          backgroundColor: kDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Remover aluno', style: TextStyle(color: kText1)),
        content: Text(
          'Deseja remover $nome desta turma?',
          style: TextStyle(color: kText2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: kText2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remover',
              style: TextStyle(color: kDanger, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await firestoreService.deleteMatricula(_academiaId!, matriculaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nome removido da turma.'),
            backgroundColor: kSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _load();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao remover aluno.'),
            backgroundColor: kDanger,
            behavior: SnackBarBehavior.floating,
          ),
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
          child: Row(
            children: [
              Text(
                'Horários da turma',
                style: TextStyle(
                  color: kText2,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!_pm)
                GestureDetector(
                  onTap: () => _abrirHorarioForm(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: kPrimary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Novo horário',
                          style: TextStyle(
                            color: kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _horarios.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, color: kText2, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum horário cadastrado',
                        style: TextStyle(color: kText2, fontSize: 14),
                      ),
                      if (!_pm) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _abrirHorarioForm(),
                          child: Text(
                            'Adicionar horário',
                            style: TextStyle(color: kPrimary),
                          ),
                        ),
                      ],
                    ],
                  ),
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
    final dia = (h['diaSemana'] ?? h['dia_semana'] as num?)?.toInt() ?? 0;
    final diaLabel = dia >= 0 && dia < _diasSemana.length
        ? _diasSemana[dia]
        : '?';
    final inicio =
        (h['horaInicio'] ?? h['hora_inicio'])?.toString().substring(0, 5) ??
        '--:--';
    final fim =
        (h['horaFim'] ?? h['hora_fim'])?.toString().substring(0, 5) ?? '--:--';
    final sala = h['sala'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  diaLabel,
                  style: TextStyle(
                    color: kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$inicio – $fim',
                  style: TextStyle(
                    color: kText1,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sala != null && sala.isNotEmpty)
                  Text(
                    'Sala: $sala',
                    style: TextStyle(color: kText2, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (!_pm)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _abrirHorarioForm(horario: h),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit_rounded, color: kPrimary, size: 16),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deletarHorario(h),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kDanger.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: kDanger,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _abrirHorarioForm({Map<String, dynamic>? horario}) async {
    if (_academiaId == null) return;
    final turmaId = widget.turmaId;
    final salvou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HorarioFormSheet(
        turmaId: turmaId,
        academiaId: _academiaId!,
        horario: horario,
      ),
    );
    if (salvou == true) _load();
  }

  Future<void> _deletarHorario(Map<String, dynamic> h) async {
    if (_academiaId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Remover horário', style: TextStyle(color: kText1)),
        content: Text(
          'Deseja remover este horário da turma?',
          style: TextStyle(color: kText2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: kText2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remover',
              style: TextStyle(color: kDanger, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await firestoreService.deleteHorario(
        _academiaId!,
        h['id']?.toString() ?? '',
      );
      if (mounted) _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao remover horário.'),
            backgroundColor: kDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Widget _buildPresencaCard(Map<String, dynamic> a) {
    final alunoId = a['alunoId']?.toString() ?? a['aluno_id']?.toString() ?? '';
    final nome = a['nomeAluno'] as String? ?? a['nome_aluno'] as String? ?? '';
    final presente = _presentesNaData.contains(alunoId);
    final carregando = _marcando.contains(alunoId);
    final initials = nome
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    final foto = a['fotoBase64'] as String? ?? a['foto_base64'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: presente ? kSuccess.withOpacity(0.05) : kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: presente ? kSuccess.withOpacity(0.4) : kBorder,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: presente
                ? kSuccess.withOpacity(0.2)
                : kPrimary.withOpacity(0.2),
            backgroundImage: foto != null && foto.contains(',')
                ? MemoryImage(base64Decode(foto.split(',').last))
                : null,
            child: foto == null || !foto.contains(',')
                ? Text(
                    initials.isEmpty ? '?' : initials,
                    style: TextStyle(
                      color: presente ? kSuccess : kPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nome,
              style: TextStyle(
                color: kText1,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (presente)
            GestureDetector(
              onTap: (carregando || !_podeDarPresenca)
                  ? null
                  : () => _desmarcarPresenca(alunoId, nome),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kSuccess.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    carregando
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.check_circle_rounded,
                            color: kSuccess,
                            size: 14,
                          ),
                    const SizedBox(width: 4),
                    Text(
                      'Presente',
                      style: TextStyle(
                        color: kSuccess,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: (carregando || !_podeDarPresenca)
                    ? null
                    : () => _marcarPresenca(alunoId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: carregando
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
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
  final String academiaId;
  final Set<String> alunosJaMatriculados;
  const _MatriculaSheet({
    required this.turmaId,
    required this.academiaId,
    required this.alunosJaMatriculados,
  });

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
      final list = await firestoreService.getAlunos(
        widget.academiaId,
        ativosOnly: true,
      );
      final todos = list.cast<Map<String, dynamic>>();
      final disponiveis = todos
          .where(
            (a) => !widget.alunosJaMatriculados.contains(
              a['id']?.toString() ?? '',
            ),
          )
          .toList();
      if (mounted) {
        setState(() {
          _todos = disponiveis;
          _filtrar();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filtrar() {
    final q = _busca.text.trim().toLowerCase();
    setState(() {
      _filtrados = q.isEmpty
          ? List.from(_todos)
          : _todos
                .where(
                  (a) => (a['nome'] as String? ?? '').toLowerCase().contains(q),
                )
                .toList();
    });
  }

  Future<void> _matricular() async {
    if (_selecionadoId == null) return;
    setState(() => _salvando = true);
    try {
      await firestoreService.addMatricula(widget.academiaId, {
        'aluno_id': _selecionadoId,
        'turma_id': widget.turmaId,
        'data_matricula': DateTime.now().toUtc().toIso8601String(),
        'ativo': true,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao matricular aluno.'),
            backgroundColor: kDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Matricular aluno',
                style: TextStyle(
                  color: kText1,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_salvando)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: _selecionadoId == null ? null : _matricular,
                  style: TextButton.styleFrom(
                    backgroundColor: _selecionadoId != null
                        ? kPrimary.withOpacity(0.12)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Confirmar',
                    style: TextStyle(
                      color: _selecionadoId != null ? kPrimary : kText2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _busca,
            style: TextStyle(color: kText1),
            decoration: InputDecoration(
              hintText: 'Buscar aluno...',
              hintStyle: TextStyle(color: kText2),
              prefixIcon: Icon(Icons.search, color: kText2),
              filled: true,
              fillColor: kSurface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kPrimary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            )
          else if (_filtrados.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Nenhum aluno disponível.',
                style: TextStyle(color: kText2),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtrados.length,
                itemBuilder: (_, i) {
                  final a = _filtrados[i];
                  final id = a['id']?.toString() ?? '';
                  final nome = a['nome'] as String? ?? '';
                  final sel = _selecionadoId == id;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selecionadoId = sel ? null : id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary.withOpacity(0.12) : kSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? kPrimary : kBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              nome,
                              style: TextStyle(
                                color: kText1,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (sel)
                            Icon(
                              Icons.check_circle_rounded,
                              color: kPrimary,
                              size: 18,
                            ),
                        ],
                      ),
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
  final String academiaId;
  final Map<String, dynamic>? horario;
  const _HorarioFormSheet({
    required this.turmaId,
    required this.academiaId,
    this.horario,
  });

  @override
  State<_HorarioFormSheet> createState() => _HorarioFormSheetState();
}

class _HorarioFormSheetState extends State<_HorarioFormSheet> {
  static const _dias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  static const _diasFull = [
    'Domingo',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
  ];
  final _salaCtrl = TextEditingController();

  // Modo edição: um único dia
  int? _diaSemana;
  // Modo criação: múltiplos dias
  final Set<int> _diasSelecionados = {};

  TimeOfDay? _inicio;
  TimeOfDay? _fim;
  bool _salvando = false;

  bool get _editando => widget.horario != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      final h = widget.horario!;
      _diaSemana = (h['diaSemana'] ?? h['dia_semana'] as num?)?.toInt();
      _salaCtrl.text = h['sala'] as String? ?? '';
      final inicioStr = (h['horaInicio'] ?? h['hora_inicio'])?.toString() ?? '';
      final fimStr = (h['horaFim'] ?? h['hora_fim'])?.toString() ?? '';
      if (inicioStr.length >= 5) {
        final parts = inicioStr.split(':');
        _inicio = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
      if (fimStr.length >= 5) {
        final parts = fimStr.split(':');
        _fim = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
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
      initialTime: isInicio
          ? (_inicio ?? const TimeOfDay(hour: 8, minute: 0))
          : (_fim ?? const TimeOfDay(hour: 9, minute: 0)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: kPrimary, surface: kSurface),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted)
      setState(() => isInicio ? _inicio = picked : _fim = picked);
  }

  Future<void> _salvar() async {
    final dias = _editando ? [_diaSemana!] : _diasSelecionados.toList()
      ..sort();
    if (dias.isEmpty || _inicio == null || _fim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione ao menos um dia e os horários.'),
          backgroundColor: kDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final sala = _salaCtrl.text.trim();
      if (_editando) {
        await firestoreService.updateHorario(
          widget.academiaId,
          widget.horario!['id']?.toString() ?? '',
          {
            'turma_id': widget.turmaId,
            'dia_semana': _diaSemana,
            'hora_inicio': _formatTime(_inicio!),
            'hora_fim': _formatTime(_fim!),
            if (sala.isNotEmpty) 'sala': sala,
          },
        );
      } else {
        for (final dia in dias) {
          await firestoreService.addHorario(widget.academiaId, {
            'turma_id': widget.turmaId,
            'dia_semana': dia,
            'hora_inicio': _formatTime(_inicio!),
            'hora_fim': _formatTime(_fim!),
            if (sala.isNotEmpty) 'sala': sala,
          });
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      final msg = _editando
          ? 'Erro ao editar horário.'
          : 'Erro ao criar horário.';
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: kDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _editando ? 'Editar Horário' : 'Novo Horário',
                style: TextStyle(
                  color: kText1,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_salvando)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: _salvar,
                  style: TextButton.styleFrom(
                    backgroundColor: kPrimary.withOpacity(0.12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Salvar',
                    style: TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Dias da semana
          if (_editando) ...[
            DropdownButtonFormField<int>(
              value: _diaSemana,
              decoration: InputDecoration(
                labelText: 'Dia da semana',
                labelStyle: TextStyle(color: kText2, fontSize: 13),
                prefixIcon: Icon(
                  Icons.calendar_today_rounded,
                  color: kText2,
                  size: 18,
                ),
                filled: true,
                fillColor: kSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kPrimary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              dropdownColor: kSurface,
              style: TextStyle(color: kText1, fontSize: 15),
              items: List.generate(
                7,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(_diasFull[i], style: TextStyle(color: kText1)),
                ),
              ),
              onChanged: (v) => setState(() => _diaSemana = v),
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Dias da semana',
                style: TextStyle(
                  color: kText2,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(7, (i) {
                final sel = _diasSelecionados.contains(i);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                      () => sel
                          ? _diasSelecionados.remove(i)
                          : _diasSelecionados.add(i),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary : kSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? kPrimary : kBorder),
                      ),
                      child: Text(
                        _dias[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: sel ? Colors.white : kText2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 14),
          // Horários
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: kText2,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Início',
                              style: TextStyle(color: kText2, fontSize: 11),
                            ),
                            Text(
                              _inicio != null
                                  ? _formatTime(_inicio!).substring(0, 5)
                                  : '--:--',
                              style: TextStyle(
                                color: _inicio != null ? kText1 : kText2,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_filled_rounded,
                          color: kText2,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fim',
                              style: TextStyle(color: kText2, fontSize: 11),
                            ),
                            Text(
                              _fim != null
                                  ? _formatTime(_fim!).substring(0, 5)
                                  : '--:--',
                              style: TextStyle(
                                color: _fim != null ? kText1 : kText2,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _salaCtrl,
            style: TextStyle(color: kText1, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Sala (opcional)',
              labelStyle: TextStyle(color: kText2, fontSize: 13),
              prefixIcon: Icon(Icons.room_rounded, color: kText2, size: 18),
              filled: true,
              fillColor: kSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kPrimary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
