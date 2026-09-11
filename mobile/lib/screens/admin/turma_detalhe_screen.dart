import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/ad_banner.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
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

String _ordLabel(_OrdAlunos o, AppLocalizations l) {
  switch (o) {
    case _OrdAlunos.manual:
      return l.tdOrdManual;
    case _OrdAlunos.nomeAsc:
      return l.sortNameAsc;
    case _OrdAlunos.nomeDesc:
      return l.sortNameDesc;
    case _OrdAlunos.graduacaoDesc:
      return l.tdOrdBeltDesc;
    case _OrdAlunos.graduacaoAsc:
      return l.tdOrdBeltAsc;
    case _OrdAlunos.matriculaAntiga:
      return l.tdOrdEnrollOld;
    case _OrdAlunos.matriculaNova:
      return l.tdOrdEnrollNew;
    case _OrdAlunos.presencasDesc:
      return l.tdOrdAttendDesc;
    case _OrdAlunos.presencasAsc:
      return l.tdOrdAttendAsc;
  }
}

class AdminTurmaDetalheScreen extends StatefulWidget {
  final String turmaId;

  /// Quando `true`, a tela é aberta pelo app do professor: esconde os controles
  /// de gestão da turma (editar/excluir turma, matricular/desmatricular, criar/
  /// editar/excluir horário) e navega para os alunos pela rota `/professor/...`.
  final bool professorMode;

  /// Aba inicial: 0 Alunos · 1 Presença · 2 Horários. Usado pelo CTA
  /// "Fazer chamada" da lista de turmas para abrir direto na chamada.
  final int initialTab;

  const AdminTurmaDetalheScreen({
    super.key,
    required this.turmaId,
    this.professorMode = false,
    this.initialTab = 0,
  });

  @override
  State<AdminTurmaDetalheScreen> createState() =>
      _AdminTurmaDetalheScreenState();
}

class _AdminTurmaDetalheScreenState extends State<AdminTurmaDetalheScreen>
    with SingleTickerProviderStateMixin {
  AppLocalizations get _l => context.l10n;
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
  final _presCtrl = TextEditingController();
  bool _marcandoTodos = false;

  Set<String> _aptosGraduar = {};

  // Ordenação / reordenação manual da lista de alunos
  _OrdAlunos _ordenacao = _OrdAlunos.nomeAsc;
  bool _ordenacaoInicializada = false;
  bool _temOrdemManual = false;
  bool _podeReordenar = false;
  bool _reordenando = false;
  bool _salvandoOrdem = false;

  // Ordenação da aba Presença — independente da aba Alunos: uma pessoa pode
  // querer ver os alunos da turma em ordem alfabética, mas filtrar quem já
  // presenciou por outro critério (ex.: mais faltoso primeiro).
  _OrdAlunos _ordenacaoPresenca = _OrdAlunos.nomeAsc;
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
    _tabCtrl = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 1 && !_tabCtrl.indexIsChanging) _loadPresencaData();
    });
    _ctrl.addListener(_filtrar);
    _load();
    // O listener do TabController não dispara para o índice inicial.
    if (_tabCtrl.index == 1) _loadPresencaData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ctrl.dispose();
    _presCtrl.dispose();
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
      if (turmaData == null) throw Exception(_l.tdClassNotFound);

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
          _podeReordenar =
              !_pm ||
              (user?.temPermissao('acesso_turmas_todas') ?? false) ||
              (turmaData['professorId']?.toString() == meuId);
          if (!_ordenacaoInicializada) {
            _ordenacao = temOrdemManual
                ? _OrdAlunos.manual
                : _OrdAlunos.nomeAsc;
            _ordenacaoInicializada = true;
          }
          _reordenando = false;
          _recomputarFiltrados();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _erro = _l.tdClassLoadError);
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
    final nome = _turma?['nome']?.toString() ?? _l.tdThisClass;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.c.surfaceContainer,
            title: Text(
              _l.tdDeleteClassConfirm(nome),
              style: TextStyle(
                color: context.c.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            content: Text(
              _l.tdDeleteClassBody,
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  _l.commonCancel,
                  style: TextStyle(color: context.c.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
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
                ? _l.tdClassDeletedWithEnroll(resultado.matriculasEncerradas)
                : _l.tdClassDeleted,
          ),
          backgroundColor: context.sem.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      rootNavigator.pop(); // fecha o loading
      String msg = _l.tdClassDeleteError;
      if (e is FirebaseFunctionsException) msg = e.message ?? msg;
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _mostrarQrTurma() async {
    final turmaId = widget.turmaId;
    final qrData = turmaId;
    if (!mounted) return;

    final nomeTurma = _turma?['nome'] ?? _l.tdClassFallback;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.c.surfaceContainer,
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
                color: context.c.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _l.tdClassQrTitle,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              nomeTurma,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 13),
            ),
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
              _l.tdQrSubtitle,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            Text(
              _l.tdQrValidity,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 11),
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
        : _alunos.where((a) => _nomeDe(a).toLowerCase().contains(q)).toList();
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

  List<Map<String, dynamic>> _ordenar(List<Map<String, dynamic>> src) =>
      _ordenarPor(_ordenacao, src);

  List<Map<String, dynamic>> _ordenarPor(
    _OrdAlunos criterio,
    List<Map<String, dynamic>> src,
  ) {
    final l = List<Map<String, dynamic>>.from(src);
    int tie(int c, Map<String, dynamic> a, Map<String, dynamic> b) =>
        c != 0 ? c : _cmpNome(a, b);
    switch (criterio) {
      case _OrdAlunos.manual:
        l.sort((a, b) => tie(_pesoManual(a).compareTo(_pesoManual(b)), a, b));
      case _OrdAlunos.nomeAsc:
        l.sort(_cmpNome);
      case _OrdAlunos.nomeDesc:
        l.sort((a, b) => _cmpNome(b, a));
      case _OrdAlunos.graduacaoDesc:
        l.sort(
          (a, b) => tie(_pesoGraduacao(b).compareTo(_pesoGraduacao(a)), a, b),
        );
      case _OrdAlunos.graduacaoAsc:
        l.sort(
          (a, b) => tie(_pesoGraduacao(a).compareTo(_pesoGraduacao(b)), a, b),
        );
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
      backgroundColor: context.c.surfaceContainer,
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
                _l.tdSortStudents,
                style: TextStyle(
                  color: context.c.onSurface,
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
                    color: _ordenacao == o
                        ? context.c.primary
                        : context.c.onSurfaceVariant,
                    size: 20,
                  ),
                  title: Text(
                    _ordLabel(o, _l),
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 13.5,
                    ),
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
                  leading: Icon(
                    Icons.swap_vert_rounded,
                    color: context.c.primary,
                  ),
                  title: Text(
                    _l.tdReorderByDrag,
                    style: TextStyle(
                      color: context.c.primary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _l.tdReorderHint,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 11,
                    ),
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

  /// Igual a [_abrirMenuOrdenacao], mas para o critério próprio da aba
  /// Presença (_ordenacaoPresenca) — sem a opção de reordenar por arrastar,
  /// que é só da aba Alunos.
  void _abrirMenuOrdenacaoPresenca() {
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
      backgroundColor: context.c.surfaceContainer,
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
                _l.tdSortStudents,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              for (final o in opcoes)
                ListTile(
                  dense: true,
                  leading: Icon(
                    _ordenacaoPresenca == o
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _ordenacaoPresenca == o
                        ? context.c.primary
                        : context.c.onSurfaceVariant,
                    size: 20,
                  ),
                  title: Text(
                    _ordLabel(o, _l),
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 13.5,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _ordenacaoPresenca = o);
                  },
                ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l.tdOrderSaved)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l.tdOrderSaveError)));
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
    if (diff == 0) return _l.tdToday;
    if (diff == 1) return _l.tdYesterday;
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
          colorScheme: ColorScheme.dark(
            primary: context.c.primary,
            surface: context.c.surfaceContainer,
          ),
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

  List<String> get _diasNomes => [
    _l.dowFullSun,
    _l.dowFullMon,
    _l.dowFullTue,
    _l.dowFullWed,
    _l.dowFullThu,
    _l.dowFullFri,
    _l.dowFullSat,
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
          backgroundColor: context.c.surfaceContainer,
          title: Text(
            _l.tdOffScheduleDay,
            style: TextStyle(
              color: context.c.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            _l.tdOffScheduleOneBody(diaLabel),
            style: TextStyle(color: context.c.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                _l.commonCancel,
                style: TextStyle(color: context.c.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                _l.tdConfirmAnyway,
                style: TextStyle(
                  color: context.c.primary,
                  fontWeight: FontWeight.w700,
                ),
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
            content: Text(_l.tdAttendanceMarked),
            backgroundColor: context.sem.success,
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
                  : _l.tdAttendanceMarkError,
            ),
            backgroundColor: context.sem.danger,
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
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.tdUndoAttendance,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          _l.tdUndoAttendanceBody(nome),
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              _l.commonRemove,
              style: TextStyle(
                color: context.sem.danger,
                fontWeight: FontWeight.w700,
              ),
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
            content: Text(_l.tdAttendanceRemoved),
            backgroundColor: context.sem.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.tdAttendanceRemoveError),
            backgroundColor: context.sem.danger,
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
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.c.onSurface,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t?['nome'] ?? _l.tdClassFallback,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (!_pm && t != null && _academiaId != null)
            IconButton(
              icon: Icon(
                Icons.edit_rounded,
                color: context.c.onSurfaceVariant,
                size: 20,
              ),
              tooltip: _l.editClass,
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
                color: context.sem.danger,
                size: 20,
              ),
              tooltip: _l.tdDeleteClass,
              onPressed: _excluirTurma,
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: context.c.primary,
          unselectedLabelColor: context.c.onSurfaceVariant,
          indicatorColor: context.c.primary,
          tabs: [
            Tab(text: _l.navStudents),
            Tab(text: _l.tdTabAttendance),
            Tab(text: _l.tdTabSchedule),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.c.primary))
          : _erro != null
          ? Center(
              child: Text(_erro!, style: TextStyle(color: context.sem.danger)),
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
    final capRaw = _turma?['capacidadeMaxima'] ?? _turma?['capacidade_maxima'];
    final cap = (capRaw as num?)?.toInt() ?? 0;
    final matriculados =
        (_turma?['totalAlunos'] as num?)?.toInt() ?? _alunos.length;
    return Column(
      children: [
        if (!_reordenando)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _ctrl,
              style: TextStyle(color: context.c.onSurface),
              decoration: InputDecoration(
                hintText: _l.studentsSearchHint,
                hintStyle: TextStyle(color: context.c.onSurfaceVariant),
                prefixIcon: Icon(
                  Icons.search,
                  color: context.c.onSurfaceVariant,
                ),
                filled: true,
                fillColor: context.c.surfaceContainer,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                  borderSide: BorderSide(color: context.c.primary),
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
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: _l.tdEnrolledStudents,
                        style: TextStyle(color: context.c.onSurfaceVariant),
                      ),
                      TextSpan(
                        text: cap > 0
                            ? ' — $matriculados/$cap'
                            : ' — $matriculados',
                        style: TextStyle(
                          color: context.c.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _mostrarQrTurma,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.sem.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_rounded,
                          color: context.sem.success,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'QR',
                          style: TextStyle(
                            color: context.sem.success,
                            fontSize: 13,
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
        if (!_reordenando && _filtrados.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Material(
              color: context.c.surfaceContainer,
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
                    border: Border.all(color: context.c.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        color: context.c.onSurfaceVariant,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _l.tdSortPrefix,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _ordLabel(_ordenacao, _l),
                          style: TextStyle(
                            color: context.c.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        color: context.c.primary,
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
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_martial_arts_rounded,
                          color: context.c.onSurfaceVariant,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _ctrl.text.trim().isEmpty
                              ? _l.noStudentsInClass
                              : _l.studentsEmpty,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : _reordenando
              ? ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _filtrados.length,
                  onReorder: _onReorder,
                  itemBuilder: (_, i) => _buildReorderTile(_filtrados[i], i),
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
        if (!_pm && !_reordenando)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _abrirMatricula,
                icon: Icon(Icons.person_add_rounded, size: 18),
                label: Text(_l.tdAddStudent),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.c.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
        color: context.c.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.c.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator_rounded,
            color: context.c.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _l.tdDragToReorder,
              style: TextStyle(color: context.c.onSurface, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: _salvandoOrdem ? null : _cancelarReordenar,
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: _salvandoOrdem ? null : _salvarOrdemManual,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.c.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: _salvandoOrdem
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_l.commonSave),
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
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.c.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator_rounded, color: context.c.onSurfaceVariant),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: context.c.primary.withValues(alpha: 0.2),
            backgroundImage: foto != null && foto.contains(',')
                ? MemoryImage(base64Decode(foto.split(',').last))
                : null,
            child: foto == null || !foto.contains(',')
                ? Text(
                    initials.isEmpty ? '?' : initials,
                    style: TextStyle(
                      color: context.c.primary,
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
                color: context.c.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${index + 1}',
            style: TextStyle(
              color: context.c.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
      return context.c.primary;
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
          color: apto
              ? context.sem.success.withValues(alpha: 0.05)
              : context.c.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: apto
                ? context.sem.success.withValues(alpha: 0.4)
                : context.c.outline,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: (apto ? context.sem.success : context.c.primary)
                  .withValues(alpha: 0.2),
              backgroundImage: foto != null && foto.contains(',')
                  ? MemoryImage(base64Decode(foto.split(',').last))
                  : null,
              child: foto == null || !foto.contains(',')
                  ? Text(
                      initials.isEmpty ? '?' : initials,
                      style: TextStyle(
                        color: apto ? context.sem.success : context.c.primary,
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
                      color: context.c.onSurface,
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
                              color: context.c.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '+${faixasCount - 1}',
                              style: TextStyle(
                                color: context.c.primary,
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
                                ? '$faixaNome · ${_l.stripeLabel(grauAtual)}'
                                : faixaNome,
                            style: TextStyle(
                              color: apto
                                  ? context.sem.success
                                  : context.c.onSurfaceVariant,
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
                          _l.tdEligibleToPromote,
                          style: TextStyle(
                            color: context.sem.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (faixaNome == null && !apto)
                        Text(
                          _l.studentNoBelt,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.c.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: context.c.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _l.tdAttendancesLabel,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: context.c.onSurfaceVariant,
              size: 18,
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
          color: context.sem.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.person_remove_rounded, color: context.sem.danger),
      ),
      confirmDismiss: (_) async {
        await _desmatricularAluno(a);
        return false;
      },
      child: card,
    );
  }

  // ── ABA PRESENÇA ──────────────────────────────────────

  // Critério de ordenação PRÓPRIO desta aba (_ordenacaoPresenca) —
  // independente do que estiver selecionado na aba Alunos: uma pessoa pode
  // querer ver os alunos da turma em ordem alfabética ali, e aqui filtrar
  // quem já presenciou por outro critério (ex.: mais faltoso primeiro).
  List<Map<String, dynamic>> get _alunosPresFiltrados {
    final q = _presCtrl.text.trim().toLowerCase();
    final base = q.isEmpty
        ? _alunos
        : _alunos
              .where(
                (a) => (a['nomeAluno'] ?? a['nome_aluno'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(q),
              )
              .toList();
    return _ordenarPor(_ordenacaoPresenca, base);
  }

  Widget _miniStatPresenca({
    required IconData icon,
    required String valor,
    required String label,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: cor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _abaPresenca() {
    final total = _alunos.length;
    final presentes = _presentesNaData.length;
    final pct = total == 0 ? 0 : (presentes / total * 100).round();
    final corFreq = pct >= 75
        ? context.sem.success
        : (pct >= 50
              ? context.sem.warning
              : (presentes == 0
                    ? context.c.onSurfaceVariant
                    : context.sem.danger));
    final pendentes = _alunos
        .map((a) => (a['alunoId'] ?? a['aluno_id'] ?? '').toString())
        .where((id) => id.isNotEmpty && !_presentesNaData.contains(id))
        .length;
    final podeMarcarTodos =
        !_pm && _podeDarPresenca && pendentes > 0 && !_loadingPresenca;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: context.c.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.c.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _prevDay,
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: context.c.primary,
                    size: 26,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: context.c.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _dataLabel,
                              style: TextStyle(
                                color: context.c.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.expand_more_rounded,
                            color: context.c.primary,
                            size: 18,
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
                    color: _isHoje ? context.c.outline : context.c.primary,
                    size: 26,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _miniStatPresenca(
                  icon: Icons.groups_rounded,
                  valor: '$presentes / $total',
                  label: _l.tdPresentToday,
                  cor: context.c.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStatPresenca(
                  icon: Icons.insights_rounded,
                  valor: '$pct%',
                  label: _l.tdDayAttendanceRate,
                  cor: corFreq,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _presCtrl,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: context.c.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _l.studentsSearchHint,
                      hintStyle: TextStyle(color: context.c.onSurfaceVariant),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: context.c.onSurfaceVariant,
                        size: 20,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: context.c.surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                        borderSide: BorderSide(color: context.c.primary),
                      ),
                    ),
                  ),
                ),
              ),
              if (podeMarcarTodos) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _marcandoTodos ? null : _marcarTodos,
                    icon: _marcandoTodos
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.done_all_rounded,
                            size: 16,
                            color: context.c.primary,
                          ),
                    label: Text(
                      _l.tdMarkAll,
                      style: TextStyle(
                        color: context.c.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: context.c.primary.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_alunos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Material(
              color: context.c.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _abrirMenuOrdenacaoPresenca,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.c.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        color: context.c.onSurfaceVariant,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _l.tdSortPrefix,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _ordLabel(_ordenacaoPresenca, _l),
                          style: TextStyle(
                            color: context.c.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        color: context.c.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_loadingPresenca)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: _alunos.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        _l.tdNoStudentsForAttendance,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Builder(
                    builder: (_) {
                      final lista = _alunosPresFiltrados;
                      if (lista.isEmpty) {
                        return Center(
                          child: Text(
                            _l.studentsEmpty,
                            style: TextStyle(color: context.c.onSurfaceVariant),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: lista.length,
                        itemBuilder: (_, i) => _buildPresencaCard(lista[i]),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Future<void> _marcarTodos() async {
    if (_marcandoTodos || _academiaId == null) return;
    final pendentes = _alunos
        .map((a) => (a['alunoId'] ?? a['aluno_id'] ?? '').toString())
        .where((id) => id.isNotEmpty && !_presentesNaData.contains(id))
        .toList();
    if (pendentes.isEmpty) return;

    // Confirmação de "dia fora do horário" uma única vez (mesma regra do
    // fluxo individual), não por aluno.
    if (!_dataNoDiaDaTurma) {
      final diaLabel = _diasNomes[_dartDiaToFirestore(_dataSel.weekday)];
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.c.surfaceContainer,
          title: Text(
            _l.tdOffScheduleDay,
            style: TextStyle(
              color: context.c.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            _l.tdOffScheduleAllBody(diaLabel),
            style: TextStyle(color: context.c.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                _l.commonCancel,
                style: TextStyle(color: context.c.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                _l.commonConfirm,
                style: TextStyle(
                  color: context.c.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    setState(() => _marcandoTodos = true);
    var falhou = 0;
    for (final alunoId in pendentes) {
      if (!mounted) break;
      if (_presentesNaData.contains(alunoId)) continue;
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
        }
      } catch (_) {
        falhou++;
      } finally {
        if (mounted) setState(() => _marcando.remove(alunoId));
      }
    }
    if (mounted) {
      setState(() => _marcandoTodos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            falhou == 0
                ? _l.tdAttendanceAllMarked
                : _l.tdAttendanceSomeFailed(falhou),
          ),
          backgroundColor: falhou == 0
              ? context.sem.success
              : context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          content: Text(_l.tdEnrollIdNotFound),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.tdRemoveStudent,
          style: TextStyle(color: context.c.onSurface),
        ),
        content: Text(
          _l.tdRemoveStudentBody(nome),
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              _l.commonRemove,
              style: TextStyle(
                color: context.sem.danger,
                fontWeight: FontWeight.w700,
              ),
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
            content: Text(_l.tdStudentRemoved(nome)),
            backgroundColor: context.sem.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _load();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.tdRemoveStudentError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ── ABA HORÁRIOS ──────────────────────────────────────

  List<String> get _diasSemana => [
    _l.dowSun,
    _l.dowMon,
    _l.dowTue,
    _l.dowWed,
    _l.dowThu,
    _l.dowFri,
    _l.dowSat,
  ];

  List<String> get _diasExtenso => [
    _l.dowFullSun,
    _l.dowFullMon,
    _l.dowFullTue,
    _l.dowFullWed,
    _l.dowFullThu,
    _l.dowFullFri,
    _l.dowFullSat,
  ];

  int _diaIdxHorario(Map<String, dynamic> h) =>
      (h['diaSemana'] ?? h['dia_semana'] as num?)?.toInt() ?? 0;

  /// Ordena os horários pela sequência da semana (Seg → Dom).
  List<Map<String, dynamic>> get _horariosOrdenados {
    final l = [..._horarios];
    l.sort((a, b) {
      int key(Map<String, dynamic> h) => (_diaIdxHorario(h) + 6) % 7;
      final c = key(a).compareTo(key(b));
      if (c != 0) return c;
      final ha = (a['horaInicio'] ?? a['hora_inicio'] ?? '').toString();
      final hb = (b['horaInicio'] ?? b['hora_inicio'] ?? '').toString();
      return ha.compareTo(hb);
    });
    return l;
  }

  String _duracaoHorario(String inicio, String fim) {
    int mins(String s) {
      final p = s.split(':');
      if (p.length < 2) return -1;
      final hh = int.tryParse(p[0]);
      final mm = int.tryParse(p[1]);
      if (hh == null || mm == null) return -1;
      return hh * 60 + mm;
    }

    final a = mins(inicio);
    final b = mins(fim);
    if (a < 0 || b < 0 || b <= a) return '';
    final d = b - a;
    final h = d ~/ 60;
    final m = d % 60;
    if (h > 0 && m > 0) return '${h}h ${m}min';
    if (h > 0) return '${h}h';
    return '${m}min';
  }

  Widget _abaHorarios() {
    final ordenados = _horariosOrdenados;
    final n = ordenados.length;
    final ativa = _turma?['ativo'] == true;
    final diasResumo = () {
      final nomes = ordenados
          .map((h) {
            final d = _diaIdxHorario(h);
            return (d >= 0 && d < 7) ? _diasExtenso[d] : '';
          })
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      if (nomes.isEmpty) return '';
      if (nomes.length == 1) return nomes.first;
      return '${nomes.sublist(0, nomes.length - 1).join(', ')}${_l.tdListAnd}${nomes.last}';
    }();

    return Column(
      children: [
        if (n > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.c.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.c.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event_repeat_rounded,
                    color: context.c.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _l.tdWeeklyScheduleCount(n),
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (diasResumo.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          diasResumo,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (ativa
                                ? context.sem.success
                                : context.c.onSurfaceVariant)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ativa ? _l.classStatusActive : _l.classStatusInactive,
                    style: TextStyle(
                      color: ativa
                          ? context.sem.success
                          : context.c.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                _l.tdClassSchedule,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
                      color: context.c.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: context.c.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _l.tdNewSchedule,
                          style: TextStyle(
                            color: context.c.primary,
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
          child: ordenados.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          color: context.c.onSurfaceVariant,
                          size: 44,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _l.tdNoSchedules,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (!_pm) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _abrirHorarioForm(),
                            icon: Icon(Icons.add_rounded, size: 18),
                            label: Text(_l.tdAddFirstSchedule),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.c.primary,
                              minimumSize: const Size(0, 46),
                              side: BorderSide(
                                color: context.c.primary.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: ordenados.length,
                  itemBuilder: (_, i) => _buildHorarioCard(ordenados[i]),
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
    final duracao = _duracaoHorario(inicio, fim);
    final sala = h['sala'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.c.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  diaLabel,
                  style: TextStyle(
                    color: context.c.primary,
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
                    color: context.c.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (duracao.isNotEmpty) duracao,
                    if (sala != null && sala.isNotEmpty) _l.tdRoomN(sala),
                  ].join(' · '),
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 12,
                  ),
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
                      color: context.c.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: context.c.primary,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deletarHorario(h),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.sem.danger.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: context.sem.danger,
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
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.tdDeleteScheduleTitle,
          style: TextStyle(color: context.c.onSurface),
        ),
        content: Text(
          _l.tdDeleteScheduleBody,
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
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
            content: Text(_l.tdScheduleRemoveError),
            backgroundColor: context.sem.danger,
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
        color: presente
            ? context.sem.success.withValues(alpha: 0.05)
            : context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: presente
              ? context.sem.success.withValues(alpha: 0.4)
              : context.c.outline,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: presente
                ? context.sem.success.withValues(alpha: 0.2)
                : context.c.primary.withValues(alpha: 0.2),
            backgroundImage: foto != null && foto.contains(',')
                ? MemoryImage(base64Decode(foto.split(',').last))
                : null,
            child: foto == null || !foto.contains(',')
                ? Text(
                    initials.isEmpty ? '?' : initials,
                    style: TextStyle(
                      color: presente ? context.sem.success : context.c.primary,
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
                color: context.c.onSurface,
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
                  color: context.sem.success.withValues(alpha: 0.15),
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
                            color: context.sem.success,
                            size: 14,
                          ),
                    const SizedBox(width: 4),
                    Text(
                      _l.tdPresent,
                      style: TextStyle(
                        color: context.sem.success,
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
                  backgroundColor: context.c.primary,
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
                    : Text(_l.tdMark),
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
  AppLocalizations get _l => context.l10n;
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
            content: Text(_l.tdEnrollError),
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
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
              color: context.c.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _l.tdEnrollStudent,
                style: TextStyle(
                  color: context.c.onSurface,
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
                        ? context.c.primary.withValues(alpha: 0.12)
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
                    _l.commonConfirm,
                    style: TextStyle(
                      color: _selecionadoId != null
                          ? context.c.primary
                          : context.c.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _busca,
            style: TextStyle(color: context.c.onSurface),
            decoration: InputDecoration(
              hintText: _l.studentsSearchHint,
              hintStyle: TextStyle(color: context.c.onSurfaceVariant),
              prefixIcon: Icon(Icons.search, color: context.c.onSurfaceVariant),
              filled: true,
              fillColor: context.c.surfaceContainer,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
                borderSide: BorderSide(color: context.c.primary),
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
                _l.tdNoStudentsAvailable,
                style: TextStyle(color: context.c.onSurfaceVariant),
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
                        color: sel
                            ? context.c.primary.withValues(alpha: 0.12)
                            : context.c.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? context.c.primary : context.c.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              nome,
                              style: TextStyle(
                                color: context.c.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (sel)
                            Icon(
                              Icons.check_circle_rounded,
                              color: context.c.primary,
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
  AppLocalizations get _l => context.l10n;
  List<String> get _dias => [
    _l.dowSun,
    _l.dowMon,
    _l.dowTue,
    _l.dowWed,
    _l.dowThu,
    _l.dowFri,
    _l.dowSat,
  ];
  List<String> get _diasFull => [
    _l.dowFullSun,
    _l.dowFullMon,
    _l.dowFullTue,
    _l.dowFullWed,
    _l.dowFullThu,
    _l.dowFullFri,
    _l.dowFullSat,
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
          colorScheme: ColorScheme.dark(
            primary: context.c.primary,
            surface: context.c.surfaceContainer,
          ),
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
          content: Text(_l.tdSelectDayAndTime),
          backgroundColor: context.sem.danger,
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
      final msg = _editando ? _l.tdScheduleEditError : _l.tdScheduleCreateError;
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
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
              color: context.c.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _editando ? _l.tdEditScheduleTitle : _l.tdNewScheduleTitle,
                style: TextStyle(
                  color: context.c.onSurface,
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
                    backgroundColor: context.c.primary.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _l.commonSave,
                    style: TextStyle(
                      color: context.c.primary,
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
                labelText: _l.tdWeekday,
                labelStyle: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.calendar_today_rounded,
                  color: context.c.onSurfaceVariant,
                  size: 18,
                ),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              dropdownColor: context.c.surfaceContainer,
              style: TextStyle(color: context.c.onSurface, fontSize: 15),
              items: List.generate(
                7,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    _diasFull[i],
                    style: TextStyle(color: context.c.onSurface),
                  ),
                ),
              ),
              onChanged: (v) => setState(() => _diaSemana = v),
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _l.tdWeekdays,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
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
                        color: sel
                            ? context.c.primary
                            : context.c.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? context.c.primary : context.c.outline,
                        ),
                      ),
                      child: Text(
                        _dias[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: sel
                              ? Colors.white
                              : context.c.onSurfaceVariant,
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
                      color: context.c.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: context.c.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _l.tdStart,
                              style: TextStyle(
                                color: context.c.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              _inicio != null
                                  ? _formatTime(_inicio!).substring(0, 5)
                                  : '--:--',
                              style: TextStyle(
                                color: _inicio != null
                                    ? context.c.onSurface
                                    : context.c.onSurfaceVariant,
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
                      color: context.c.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_filled_rounded,
                          color: context.c.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fim',
                              style: TextStyle(
                                color: context.c.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              _fim != null
                                  ? _formatTime(_fim!).substring(0, 5)
                                  : '--:--',
                              style: TextStyle(
                                color: _fim != null
                                    ? context.c.onSurface
                                    : context.c.onSurfaceVariant,
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
            style: TextStyle(color: context.c.onSurface, fontSize: 15),
            decoration: InputDecoration(
              labelText: _l.tdRoomOptional,
              labelStyle: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.room_rounded,
                color: context.c.onSurfaceVariant,
                size: 18,
              ),
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
