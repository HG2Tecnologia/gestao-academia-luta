import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/auth_storage.dart';
import '../../core/firestore_service.dart';
import '../../core/relatorio_presencas_export.dart';
import '../../core/relatorio_presencas_oficial.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';

enum _TipoPeriodo { mes, ano, personalizado }

enum _OrdRel { freqDesc, freqAsc, nomeAsc, nomeDesc }

String _ordRelLabel(_OrdRel o, AppLocalizations l) {
  switch (o) {
    case _OrdRel.freqDesc:
      return l.sortAttendanceDesc;
    case _OrdRel.freqAsc:
      return l.sortAttendanceAsc;
    case _OrdRel.nomeAsc:
      return l.sortNameAsc;
    case _OrdRel.nomeDesc:
      return l.sortNameDesc;
  }
}

String _capitalizar(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Relatório oficial de presenças/faltas — pra emissão mensal/anual (ex.:
/// prestação de contas a um órgão público). Tela única usada por Admin
/// (sempre) e Professor/Secretaria (só com a permissão
/// `tela_relatorio_presencas`), igual ao padrão já usado por `/noticias`.
class RelatorioPresencasScreen extends StatefulWidget {
  const RelatorioPresencasScreen({super.key});

  @override
  State<RelatorioPresencasScreen> createState() => _RelatorioPresencasScreenState();
}

class _RelatorioPresencasScreenState extends State<RelatorioPresencasScreen> {
  bool _carregandoInicial = true;
  bool _carregandoDados = false;
  bool _erro = false;
  bool _semAcesso = false;

  String? _academiaId;
  List<Map<String, dynamic>> _turmasVisiveis = [];
  String? _turmaId; // null = todas

  _TipoPeriodo _tipoPeriodo = _TipoPeriodo.mes;
  DateTime _mesSelecionado = DateTime(DateTime.now().year, DateTime.now().month);
  int _anoSelecionado = DateTime.now().year;
  DateTimeRange _rangeCustom = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  List<LinhaRelatorioPresenca> _linhas = [];
  _OrdRel _ordenacao = _OrdRel.freqDesc;

  static const _todasAsColunas = ColunaRelatorio.values;
  final Set<ColunaRelatorio> _colunasSelecionadas = {..._todasAsColunas};

  @override
  void initState() {
    super.initState();
    _carregarTurmas();
  }

  (DateTime, DateTime) get _periodo {
    switch (_tipoPeriodo) {
      case _TipoPeriodo.mes:
        final de = DateTime(_mesSelecionado.year, _mesSelecionado.month, 1);
        final ate = DateTime(_mesSelecionado.year, _mesSelecionado.month + 1, 0, 23, 59, 59);
        return (de, ate);
      case _TipoPeriodo.ano:
        return (DateTime(_anoSelecionado, 1, 1), DateTime(_anoSelecionado, 12, 31, 23, 59, 59));
      case _TipoPeriodo.personalizado:
        return (
          _rangeCustom.start,
          DateTime(_rangeCustom.end.year, _rangeCustom.end.month, _rangeCustom.end.day, 23, 59, 59),
        );
    }
  }

  Future<void> _carregarTurmas() async {
    try {
      final user = await AuthStorage.getUser();
      if (user == null || user.academiaId == null || user.academiaId!.isEmpty) {
        if (mounted) setState(() => _carregandoInicial = false);
        return;
      }
      if (user.perfil != 'Admin' && !user.temPermissao('tela_relatorio_presencas')) {
        if (mounted) {
          setState(() {
            _semAcesso = true;
            _carregandoInicial = false;
          });
        }
        return;
      }
      _academiaId = user.academiaId;
      final verTodas = user.temPermissao('acesso_turmas_todas');
      final turmas = await firestoreService.getTurmas(
        _academiaId!,
        professorId: verTodas ? null : user.id,
        ativasOnly: false,
      );
      if (!mounted) return;
      setState(() {
        _turmasVisiveis = turmas.cast<Map<String, dynamic>>();
        _carregandoInicial = false;
      });
      await _gerarRelatorio();
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro = true;
          _carregandoInicial = false;
        });
      }
    }
  }

  Future<void> _gerarRelatorio() async {
    final academiaId = _academiaId;
    if (academiaId == null) return;
    setState(() {
      _carregandoDados = true;
      _erro = false;
    });
    try {
      final turmaIdsVisiveis = _turmasVisiveis.map((t) => t['id']?.toString() ?? '').toSet();

      final results = await Future.wait([
        firestoreService.getAcademia(academiaId),
        firestoreService.getAlunos(academiaId),
        firestoreService.getMatriculas(academiaId),
        firestoreService.getPresencas(academiaId),
        firestoreService.getHorarios(academiaId),
        firestoreService.getGraduacoes(academiaId, detalhadas: true),
      ]);
      final academia = results[0] as Map<String, dynamic>?;
      final alunos = (results[1] as List).cast<Map<String, dynamic>>();
      final matriculasTodas = (results[2] as List).cast<Map<String, dynamic>>();
      final presencas = (results[3] as List).cast<Map<String, dynamic>>();
      final horarios = (results[4] as List).cast<Map<String, dynamic>>();
      final graduacoes = (results[5] as List).cast<Map<String, dynamic>>();

      // Restringe ao escopo de turmas visíveis (professor sem "ver todas").
      final matriculasEscopo = matriculasTodas
          .where((m) => turmaIdsVisiveis.contains((m['turma_id'] ?? '').toString()))
          .toList();

      final limiteModo = academia?['limite_dias_semana_modo'] as String? ?? 'off';
      var limitesPorAluno = const <String, Map<String, int>>{};
      if (limiteModo != 'off') {
        final porAluno = <String, List<Map<String, dynamic>>>{};
        for (final m in matriculasEscopo) {
          if (m['ativo'] == false) continue;
          final alunoId = (m['aluno_id'] ?? '').toString();
          if (alunoId.isEmpty) continue;
          porAluno.putIfAbsent(alunoId, () => []).add(m);
        }
        final entradas = await Future.wait(
          porAluno.entries.map((e) async {
            final limites = await firestoreService.getLimitesDiasSemanaPorTurma(academiaId, e.value);
            return MapEntry(e.key, limites);
          }),
        );
        limitesPorAluno = {for (final e in entradas) e.key: e.value};
      }

      final (de, ate) = _periodo;
      final linhas = montarRelatorioPresencasOficial(
        alunos: alunos,
        matriculas: matriculasEscopo,
        presencas: presencas,
        horarios: horarios,
        turmas: _turmasVisiveis,
        graduacoesDetalhadas: graduacoes,
        de: de,
        ate: ate,
        turmaId: _turmaId,
        contabilizarFaltaAutomatica: academia?['falta_automatica_ativa'] as bool? ?? true,
        limitesPorTurmaPorAluno: limitesPorAluno,
      );

      if (mounted) {
        setState(() {
          _linhas = linhas;
          _carregandoDados = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro = true;
          _carregandoDados = false;
        });
      }
    }
  }

  String _periodoLabel(AppLocalizations l) {
    final fmt = DateFormat('dd/MM/yyyy');
    switch (_tipoPeriodo) {
      case _TipoPeriodo.mes:
        final locale = Localizations.localeOf(context).languageCode;
        return _capitalizar(DateFormat.yMMMM(locale).format(_mesSelecionado));
      case _TipoPeriodo.ano:
        return '$_anoSelecionado';
      case _TipoPeriodo.personalizado:
        return '${fmt.format(_rangeCustom.start)} — ${fmt.format(_rangeCustom.end)}';
    }
  }

  List<LinhaRelatorioPresenca> get _linhasOrdenadas {
    final list = [..._linhas];
    int porNome(LinhaRelatorioPresenca a, LinhaRelatorioPresenca b) =>
        a.nomeAluno.toLowerCase().compareTo(b.nomeAluno.toLowerCase());
    switch (_ordenacao) {
      case _OrdRel.freqDesc:
        list.sort((a, b) {
          final c = b.percentual.compareTo(a.percentual);
          return c != 0 ? c : porNome(a, b);
        });
      case _OrdRel.freqAsc:
        list.sort((a, b) {
          final c = a.percentual.compareTo(b.percentual);
          return c != 0 ? c : porNome(a, b);
        });
      case _OrdRel.nomeAsc:
        list.sort(porNome);
      case _OrdRel.nomeDesc:
        list.sort((a, b) => porNome(b, a));
    }
    return list;
  }

  int get _totalPresencas => _linhas.fold(0, (s, l) => s + l.presencas);
  int get _totalFaltas => _linhas.fold(0, (s, l) => s + l.faltas);
  int get _totalAulas => _linhas.fold(0, (s, l) => s + l.totalAulas);

  String _turmaLabel(AppLocalizations l) {
    if (_turmaId == null) return l.rpAllClasses;
    final t = _turmasVisiveis.firstWhere(
      (t) => t['id']?.toString() == _turmaId,
      orElse: () => const {},
    );
    return t['nome']?.toString() ?? l.rpAllClasses;
  }

  Map<ColunaRelatorio, String> _rotulosColunas(AppLocalizations l) => {
    ColunaRelatorio.nome: l.rpColumnName,
    ColunaRelatorio.telefone: l.rpColumnPhone,
    ColunaRelatorio.turma: l.rpColumnClass,
    ColunaRelatorio.faixa: l.rpColumnBelt,
    ColunaRelatorio.presencas: l.rpColumnPresences,
    ColunaRelatorio.faltas: l.rpColumnAbsences,
    ColunaRelatorio.totalAulas: l.rpColumnTotalClasses,
    ColunaRelatorio.percentual: l.rpColumnPercent,
  };

  Future<void> _abrirExportar() async {
    final l = context.l10n;
    // iOS exige uma origem válida pro share sheet (senão lança
    // PlatformException em runtime) — usa os limites da própria tela.
    final box = context.findRenderObject() as RenderBox?;
    final origem = box == null ? null : (box.localToGlobal(Offset.zero) & box.size);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.rpExportColumnsTitle,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                for (final c in _todasAsColunas)
                  CheckboxListTile(
                    value: _colunasSelecionadas.contains(c),
                    onChanged: (v) {
                      setSheetState(() {
                        if (v == true) {
                          _colunasSelecionadas.add(c);
                        } else {
                          _colunasSelecionadas.remove(c);
                        }
                      });
                      setState(() {});
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: context.c.primary,
                    title: Text(
                      _rotulosColunas(l)[c] ?? '',
                      style: TextStyle(color: context.c.onSurface, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _colunasSelecionadas.isEmpty || _linhas.isEmpty
                            ? null
                            : () async {
                                Navigator.of(sheetContext).pop();
                                await exportarRelatorioPdf(
                                  linhas: _linhas,
                                  colunas: _todasAsColunas
                                      .where(_colunasSelecionadas.contains)
                                      .toList(),
                                  rotulos: _rotulosColunas(l),
                                  tituloAcademia: l.rpTitle,
                                  periodoLabel: _periodoLabel(l),
                                  turmaLabel: _turmaLabel(l),
                                  sharePositionOrigin: origem,
                                );
                              },
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: Text(l.rpExportPdf),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.c.primary,
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _colunasSelecionadas.isEmpty || _linhas.isEmpty
                            ? null
                            : () async {
                                Navigator.of(sheetContext).pop();
                                await exportarRelatorioExcel(
                                  linhas: _linhas,
                                  colunas: _todasAsColunas
                                      .where(_colunasSelecionadas.contains)
                                      .toList(),
                                  rotulos: _rotulosColunas(l),
                                  tituloAcademia: l.rpTitle,
                                  periodoLabel: _periodoLabel(l),
                                  turmaLabel: _turmaLabel(l),
                                  sharePositionOrigin: origem,
                                );
                              },
                        icon: const Icon(Icons.table_chart_rounded, size: 18),
                        label: Text(l.rpExportExcel),
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mesAnterior() {
    setState(() => _mesSelecionado = DateTime(_mesSelecionado.year, _mesSelecionado.month - 1));
    _gerarRelatorio();
  }

  void _mesProximo() {
    final proximo = DateTime(_mesSelecionado.year, _mesSelecionado.month + 1);
    final limite = DateTime(DateTime.now().year, DateTime.now().month);
    if (proximo.isAfter(limite)) return;
    setState(() => _mesSelecionado = proximo);
    _gerarRelatorio();
  }

  void _anoAnterior() {
    setState(() => _anoSelecionado -= 1);
    _gerarRelatorio();
  }

  void _anoProximo() {
    if (_anoSelecionado >= DateTime.now().year) return;
    setState(() => _anoSelecionado += 1);
    _gerarRelatorio();
  }

  Future<void> _selecionarMes() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _mesSelecionado,
      helpText: context.l10n.rpSelectMonth,
    );
    if (picked == null) return;
    setState(() => _mesSelecionado = DateTime(picked.year, picked.month));
    _gerarRelatorio();
  }

  Future<void> _selecionarAno() async {
    final anos = List.generate(10, (i) => DateTime.now().year - i);
    final escolhido = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.c.surface,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: anos
              .map(
                (a) => ListTile(
                  title: Text('$a', style: TextStyle(color: context.c.onSurface)),
                  onTap: () => Navigator.of(context).pop(a),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (escolhido == null) return;
    setState(() => _anoSelecionado = escolhido);
    _gerarRelatorio();
  }

  Future<void> _selecionarPersonalizado() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _rangeCustom,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: context.c.primary,
            surface: context.c.surfaceContainer,
            onSurface: context.c.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (range == null) return;
    setState(() => _rangeCustom = range);
    _gerarRelatorio();
  }

  void _onTipoPeriodoChanged(_TipoPeriodo tipo) {
    setState(() => _tipoPeriodo = tipo);
    switch (tipo) {
      case _TipoPeriodo.mes:
        _gerarRelatorio();
      case _TipoPeriodo.ano:
        _gerarRelatorio();
      case _TipoPeriodo.personalizado:
        _selecionarPersonalizado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.c.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l.rpTitle,
          style: TextStyle(color: context.c.onSurface, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share_rounded, color: context.c.primary),
            tooltip: l.rpExport,
            onPressed: _linhas.isEmpty ? null : _abrirExportar,
          ),
        ],
      ),
      body: _carregandoInicial
          ? Center(child: CircularProgressIndicator(color: context.c.primary))
          : _semAcesso
          ? _MensagemCentral(icon: Icons.lock_outline_rounded, texto: l.rpNoAccess)
          : Column(
              children: [
                _filtros(l),
                Expanded(
                  child: _carregandoDados
                      ? Center(child: CircularProgressIndicator(color: context.c.primary))
                      : _erro
                      ? _EstadoErro(onRetry: _gerarRelatorio)
                      : _linhas.isEmpty
                      ? _MensagemCentral(icon: Icons.fact_check_outlined, texto: l.rpEmpty)
                      : _corpo(l),
                ),
              ],
            ),
    );
  }

  Widget _filtros(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.c.outline))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: context.c.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.c.outline),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _turmaId,
                isExpanded: true,
                dropdownColor: context.c.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.c.primary),
                style: TextStyle(color: context.c.onSurface, fontWeight: FontWeight.w700, fontSize: 15),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(l.rpAllClasses)),
                  ..._turmasVisiveis.map(
                    (t) => DropdownMenuItem<String?>(
                      value: t['id']?.toString(),
                      child: Text(t['nome']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (id) {
                  setState(() => _turmaId = id);
                  _gerarRelatorio();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.periodLabel,
            style: TextStyle(color: context.c.onSurface, fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _chip(l.rpPeriodMonth, _tipoPeriodo == _TipoPeriodo.mes, () {
                  if (_tipoPeriodo == _TipoPeriodo.mes) {
                    _selecionarMes();
                  } else {
                    _onTipoPeriodoChanged(_TipoPeriodo.mes);
                  }
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chip(l.rpPeriodYear, _tipoPeriodo == _TipoPeriodo.ano, () {
                  if (_tipoPeriodo == _TipoPeriodo.ano) {
                    _selecionarAno();
                  } else {
                    _onTipoPeriodoChanged(_TipoPeriodo.ano);
                  }
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chip(
                  l.periodCustom,
                  _tipoPeriodo == _TipoPeriodo.personalizado,
                  () => _onTipoPeriodoChanged(_TipoPeriodo.personalizado),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _periodoNavegacao(l),
        ],
      ),
    );
  }

  Widget _periodoNavegacao(AppLocalizations l) {
    if (_tipoPeriodo == _TipoPeriodo.personalizado) {
      return Text(_periodoLabel(l), style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12.5));
    }
    final ehMes = _tipoPeriodo == _TipoPeriodo.mes;
    final podeAvancar = ehMes
        ? _mesSelecionado.isBefore(DateTime(DateTime.now().year, DateTime.now().month))
        : _anoSelecionado < DateTime.now().year;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _setaPeriodo(Icons.chevron_left_rounded, ehMes ? _mesAnterior : _anoAnterior),
        GestureDetector(
          onTap: ehMes ? _selecionarMes : _selecionarAno,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: context.c.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  _periodoLabel(l),
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        _setaPeriodo(Icons.chevron_right_rounded, podeAvancar ? (ehMes ? _mesProximo : _anoProximo) : null),
      ],
    );
  }

  Widget _setaPeriodo(IconData icon, VoidCallback? onTap) {
    return IconButton(
      icon: Icon(icon, size: 20, color: onTap == null ? context.c.outline : context.c.onSurface),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.c.primary : context.c.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? context.c.primary : context.c.outline),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: selected ? Colors.black : context.c.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _corpo(AppLocalizations l) {
    return RefreshIndicator(
      onRefresh: _gerarRelatorio,
      color: context.c.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _RegistrosCard(
            count: _linhas.length,
            label: l.rpRowCount,
            presencas: _totalPresencas,
            faltas: _totalFaltas,
            totalAulas: _totalAulas,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.rpStudentsSection,
                  style: TextStyle(color: context.c.onSurface, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              _botaoOrdenar(l),
            ],
          ),
          const SizedBox(height: 12),
          ..._linhasOrdenadas.map((linha) => _LinhaCard(linha: linha)),
        ],
      ),
    );
  }

  Widget _botaoOrdenar(AppLocalizations l) {
    return PopupMenuButton<_OrdRel>(
      color: context.c.surfaceContainer,
      initialValue: _ordenacao,
      onSelected: (v) => setState(() => _ordenacao = v),
      itemBuilder: (_) => _OrdRel.values
          .map(
            (e) => PopupMenuItem<_OrdRel>(
              value: e,
              child: Text(_ordRelLabel(e, l), style: TextStyle(color: context.c.onSurface, fontSize: 13)),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: context.c.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.c.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _ordRelLabel(_ordenacao, l),
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: context.c.onSurfaceVariant, size: 16),
          ],
        ),
      ),
    );
  }
}

class _RegistrosCard extends StatelessWidget {
  const _RegistrosCard({
    required this.count,
    required this.label,
    required this.presencas,
    required this.faltas,
    required this.totalAulas,
  });
  final int count;
  final String label;
  final int presencas;
  final int faltas;
  final int totalAulas;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.sem.goldContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.c.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: context.c.surface, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.groups_rounded, color: context.sem.goldOnSurface, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(color: context.c.onSurface, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: context.c.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _ResumoItem(
                icon: Icons.check_circle_rounded,
                cor: context.sem.success,
                valor: '$presencas',
                label: l.rpColumnPresences,
              ),
              _ResumoItem(
                icon: Icons.cancel_rounded,
                cor: context.sem.danger,
                valor: '$faltas',
                label: l.rpColumnAbsences,
              ),
              _ResumoItem(
                icon: Icons.calendar_month_rounded,
                cor: context.sem.goldOnSurface,
                valor: '$totalAulas',
                label: l.rpColumnTotalClasses,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  const _ResumoItem({required this.icon, required this.cor, required this.valor, required this.label});
  final IconData icon;
  final Color cor;
  final String valor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: cor, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(valor, style: TextStyle(color: context.c.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
            Text(
              label,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 10.5),
            ),
          ],
        ),
      ],
    );
  }
}

class _LinhaCard extends StatelessWidget {
  const _LinhaCard({required this.linha});
  final LinhaRelatorioPresenca linha;

  Color _cor(BuildContext context, double pct) {
    if (pct >= 75) return context.sem.success;
    if (pct >= 50) return context.sem.warning;
    return context.sem.danger;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cor = _cor(context, linha.percentual);
    final temAulas = linha.totalAulas > 0;
    final iniciais = linha.nomeAluno
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cor.withValues(alpha: 0.18),
                child: Text(
                  iniciais.isEmpty ? '?' : iniciais,
                  style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      linha.nomeAluno,
                      style: TextStyle(color: context.c.onSurface, fontSize: 14.5, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        linha.nomeTurma,
                        if (linha.faixaNome.isNotEmpty) linha.faixaNome,
                      ].join(' · '),
                      style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                temAulas ? '${linha.percentual.toStringAsFixed(0)}%' : '—',
                style: TextStyle(color: cor, fontSize: 16, fontWeight: FontWeight.w900),
              ),
              Icon(Icons.chevron_right_rounded, color: context.c.onSurfaceVariant, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statItem('${linha.presencas}', l.rpColumnPresences, context),
              _statItem('${linha.faltas}', l.rpColumnAbsences, context),
              _statItem('${linha.totalAulas}', l.rpColumnTotalClasses, context),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: temAulas ? (linha.percentual / 100).clamp(0.0, 1.0) : 0,
              backgroundColor: context.c.outline,
              valueColor: AlwaysStoppedAnimation<Color>(cor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String valor, String label, BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor, style: TextStyle(color: context.c.onSurface, fontSize: 14, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _MensagemCentral extends StatelessWidget {
  const _MensagemCentral({required this.icon, required this.texto});
  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: context.c.onSurfaceVariant, size: 44),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoErro extends StatelessWidget {
  const _EstadoErro({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: context.sem.danger, size: 44),
            const SizedBox(height: 14),
            Text(
              context.l10n.classesLoadError,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.commonRetry),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.c.primary,
                minimumSize: const Size(0, 46),
                side: BorderSide(color: context.c.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
