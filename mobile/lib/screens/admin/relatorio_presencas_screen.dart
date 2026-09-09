import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';
import '../../core/relatorio_presencas.dart';
import 'widgets/dashboard_widgets.dart';

enum _Periodo { d30, d60, d90, custom }

enum _OrdRel { freqDesc, freqAsc, nomeAsc, nomeDesc }

const _labelsOrdRel = <_OrdRel, String>{
  _OrdRel.freqDesc: 'Maior frequência',
  _OrdRel.freqAsc: 'Menor frequência',
  _OrdRel.nomeAsc: 'Nome (A–Z)',
  _OrdRel.nomeDesc: 'Nome (Z–A)',
};

class AdminRelatorioPresencasScreen extends StatefulWidget {
  const AdminRelatorioPresencasScreen({super.key});

  @override
  State<AdminRelatorioPresencasScreen> createState() =>
      _AdminRelatorioPresencasScreenState();
}

class _AdminRelatorioPresencasScreenState
    extends State<AdminRelatorioPresencasScreen> {
  List<Map<String, dynamic>> _turmas = [];
  String? _turmaId;
  Map<String, dynamic>? _relatorio;
  Map<String, String?> _fotoPorAluno = {};
  bool _loadingTurmas = true;
  bool _loading = false;
  bool _erro = false;
  String? _academiaId;

  _Periodo _periodo = _Periodo.d30;
  _OrdRel _ordenacao = _OrdRel.freqDesc;
  DateTime _de = DateTime.now().subtract(const Duration(days: 30));
  DateTime _ate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTurmas();
  }

  Future<void> _loadTurmas() async {
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId ?? '';
      if (_academiaId!.isEmpty) {
        if (mounted) setState(() => _loadingTurmas = false);
        return;
      }
      final list = await firestoreService.getTurmas(_academiaId!);
      final turmas = list
          .cast<Map<String, dynamic>>()
          .where((t) => t['deleted_at'] == null)
          .toList();
      if (!mounted) return;
      setState(() {
        _turmas = turmas;
        _turmaId = turmas.isNotEmpty ? turmas.first['id']?.toString() : null;
        _loadingTurmas = false;
      });
      if (_turmaId != null) _loadRelatorio();
    } catch (_) {
      if (mounted) setState(() => _loadingTurmas = false);
    }
  }

  Future<void> _loadRelatorio() async {
    if (_turmaId == null || _academiaId == null) return;
    setState(() {
      _loading = true;
      _erro = false;
    });
    try {
      final results = await Future.wait([
        firestoreService.getPresencas(_academiaId!, turmaId: _turmaId!),
        firestoreService.getMatriculas(_academiaId!, turmaId: _turmaId!),
        firestoreService.getAlunos(_academiaId!),
      ]);
      final lista = (results[0] as List).cast<Map<String, dynamic>>();
      final matriculas = (results[1] as List).cast<Map<String, dynamic>>();
      final alunos = (results[2] as List).cast<Map<String, dynamic>>();

      // Filtro por intervalo de datas (mesma lógica de antes).
      final deStr = DateFormat('yyyy-MM-dd').format(_de);
      final ateStr = DateFormat('yyyy-MM-dd').format(_ate);
      final filtered = lista.where((p) {
        final dataStr =
            p['data'] as String? ?? p['data_presenca'] as String? ?? '';
        return dataStr.compareTo(deStr) >= 0 && dataStr.compareTo(ateStr) <= 0;
      }).toList();

      final dados = montarRelatorioPresencas(
        presencas: filtered,
        matriculas: matriculas,
        alunos: alunos,
      );

      final fotos = <String, String?>{
        for (final a in alunos)
          (a['id'] ?? '').toString():
              a['fotoBase64'] as String? ?? a['foto_base64'] as String?,
      };

      if (mounted) {
        setState(() {
          _relatorio = dados;
          _fotoPorAluno = fotos;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro = true;
          _loading = false;
        });
      }
    }
  }

  void _aplicarPreset(_Periodo p, int dias) {
    setState(() {
      _periodo = p;
      _ate = DateTime.now();
      _de = _ate.subtract(Duration(days: dias));
    });
    _loadRelatorio();
  }

  Future<void> _selecionarPeriodo() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _de, end: _ate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: kPrimary,
            surface: kSurface,
            onSurface: kText1,
          ),
        ),
        child: child!,
      ),
    );
    if (range == null) return;
    setState(() {
      _periodo = _Periodo.custom;
      _de = range.start;
      _ate = range.end;
    });
    _loadRelatorio();
  }

  List<Map<String, dynamic>> get _alunosOrdenados {
    final raw = _relatorio?['alunos'];
    if (raw == null) return const [];
    final list = List<Map<String, dynamic>>.from(
      (raw as List).cast<Map<String, dynamic>>(),
    );
    int nome(Map<String, dynamic> a, Map<String, dynamic> b) =>
        (a['nomeAluno']?.toString() ?? '').toLowerCase().compareTo(
          (b['nomeAluno']?.toString() ?? '').toLowerCase(),
        );
    double pct(Map<String, dynamic> a) =>
        (a['percentual'] as num? ?? 0).toDouble();
    switch (_ordenacao) {
      case _OrdRel.freqDesc:
        list.sort((a, b) {
          final c = pct(b).compareTo(pct(a));
          return c != 0 ? c : nome(a, b);
        });
      case _OrdRel.freqAsc:
        list.sort((a, b) {
          final c = pct(a).compareTo(pct(b));
          return c != 0 ? c : nome(a, b);
        });
      case _OrdRel.nomeAsc:
        list.sort(nome);
      case _OrdRel.nomeDesc:
        list.sort((a, b) => nome(b, a));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kText1, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Relatório de Presenças',
          style: TextStyle(
            color: kText1,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loadingTurmas
          ? Center(child: CircularProgressIndicator(color: kPrimary))
          : _turmas.isEmpty
          ? _EmptyMsg(
              icon: Icons.groups_rounded,
              texto: 'Nenhuma turma cadastrada.',
            )
          : Column(
              children: [
                _cabecalhoFiltros(),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(color: kPrimary),
                        )
                      : _erro
                      ? _EstadoErro(onRetry: _loadRelatorio)
                      : _corpo(),
                ),
              ],
            ),
    );
  }

  // ── Cabeçalho: seleção de turma + período ──────────────────────────────────

  Widget _cabecalhoFiltros() {
    final fmt = DateFormat('dd/MM/yy');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _turmaId,
                isExpanded: true,
                dropdownColor: kSurface,
                borderRadius: BorderRadius.circular(14),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: kPrimary),
                style: TextStyle(
                  color: kText1,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                items: _turmas.map((t) {
                  return DropdownMenuItem<String>(
                    value: t['id']?.toString(),
                    child: Text(
                      t['nome']?.toString() ?? '',
                      style: TextStyle(color: kText1, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() => _turmaId = id);
                  _loadRelatorio();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Período',
            style: TextStyle(
              color: kText1,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _periodoChip(
                  '30 dias',
                  _Periodo.d30,
                  () => _aplicarPreset(_Periodo.d30, 30),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _periodoChip(
                  '60 dias',
                  _Periodo.d60,
                  () => _aplicarPreset(_Periodo.d60, 60),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _periodoChip(
                  '90 dias',
                  _Periodo.d90,
                  () => _aplicarPreset(_Periodo.d90, 90),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _periodoChip(
                  'Personalizado',
                  _Periodo.custom,
                  _selecionarPeriodo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _selecionarPeriodo,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: kText2, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${fmt.format(_de)} — ${fmt.format(_ate)}',
                  style: TextStyle(color: kText2, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodoChip(String label, _Periodo p, VoidCallback onTap) {
    final sel = _periodo == p;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? kPrimary : kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? kPrimary : kBorder),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: sel ? Colors.black : kText2,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ── Corpo do relatório ────────────────────────────────────────────────────

  Widget _corpo() {
    final rel = _relatorio;
    if (rel == null) return const SizedBox();
    final totalAulas = rel['totalAulas'] as int? ?? 0;
    final media = (rel['mediaFrequencia'] as num? ?? 0).toDouble();
    final alunos = _alunosOrdenados;

    return RefreshIndicator(
      onRefresh: _loadRelatorio,
      color: kPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: DashMetricCard(
                  icon: Icons.calendar_month_rounded,
                  value: '$totalAulas',
                  label: 'Total de Aulas',
                  tone: DashTone.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashMetricCard(
                  icon: Icons.insights_rounded,
                  value: totalAulas == 0 ? '—' : '${media.toStringAsFixed(1)}%',
                  label: 'Frequência média',
                  tone: _toneFreq(media),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Frequência dos alunos (${alunos.length})',
                  style: TextStyle(
                    color: kText1,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _botaoOrdenar(),
            ],
          ),
          const SizedBox(height: 12),
          if (totalAulas == 0)
            _EmptyBox(
              texto:
                  'Não há aulas registradas neste período.\nSelecione outro intervalo para ver a frequência.',
            )
          else if (alunos.isEmpty)
            _EmptyBox(texto: 'Nenhum aluno matriculado nesta turma.')
          else
            ...alunos.map(
              (a) => _ResumoAlunoCard(
                aluno: a,
                foto: _fotoPorAluno[(a['alunoId'] ?? '').toString()],
                onTap: () {
                  final id = (a['alunoId'] ?? '').toString();
                  if (id.isNotEmpty) context.push('/admin/alunos/$id');
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _botaoOrdenar() {
    return PopupMenuButton<_OrdRel>(
      color: kSurface,
      initialValue: _ordenacao,
      onSelected: (v) => setState(() => _ordenacao = v),
      itemBuilder: (_) => _labelsOrdRel.entries
          .map(
            (e) => PopupMenuItem<_OrdRel>(
              value: e.key,
              child: Text(
                e.value,
                style: TextStyle(color: kText1, fontSize: 13),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ordenar por',
              style: TextStyle(
                color: kText2,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: kText2, size: 16),
          ],
        ),
      ),
    );
  }

  DashTone _toneFreq(double pct) {
    if (pct >= 75) return DashTone.success;
    if (pct >= 50) return DashTone.warning;
    return DashTone.danger;
  }
}

// ── Card de frequência por aluno ─────────────────────────────────────────────

class _ResumoAlunoCard extends StatelessWidget {
  const _ResumoAlunoCard({
    required this.aluno,
    required this.foto,
    required this.onTap,
  });

  final Map<String, dynamic> aluno;
  final String? foto;
  final VoidCallback onTap;

  Color _cor(double pct) {
    if (pct >= 75) return kSuccess;
    if (pct >= 50) return kWarning;
    return kDanger;
  }

  @override
  Widget build(BuildContext context) {
    final nome = aluno['nomeAluno']?.toString() ?? '';
    final pct = (aluno['percentual'] as num? ?? 0).toDouble();
    final presencas = aluno['presencas'] as int? ?? 0;
    final faltas = aluno['faltas'] as int? ?? 0;
    final cor = _cor(pct);
    final iniciais = nome
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    final temFoto = foto != null && foto!.contains(',');

    return Semantics(
      button: true,
      label:
          '$nome, ${pct.toStringAsFixed(0)}% de frequência, '
          '$presencas presenças, $faltas faltas',
      child: Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: cor.withValues(alpha: 0.18),
                      backgroundImage: temFoto
                          ? MemoryImage(base64Decode(foto!.split(',').last))
                          : null,
                      child: temFoto
                          ? null
                          : Text(
                              iniciais.isEmpty ? '?' : iniciais,
                              style: TextStyle(
                                color: cor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        nome,
                        style: TextStyle(
                          color: kText1,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: cor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: kText2, size: 18),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    backgroundColor: kBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(cor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: kSuccess),
                    const SizedBox(width: 4),
                    Text(
                      '$presencas presenças',
                      style: TextStyle(color: kText2, fontSize: 11.5),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.cancel_rounded, size: 14, color: kDanger),
                    const SizedBox(width: 4),
                    Text(
                      '$faltas faltas',
                      style: TextStyle(color: kText2, fontSize: 11.5),
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
}

// ── Estados ─────────────────────────────────────────────────────────────────

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Center(
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: kText2, fontSize: 13),
        ),
      ),
    );
  }
}

class _EmptyMsg extends StatelessWidget {
  const _EmptyMsg({required this.icon, required this.texto});
  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kText2, size: 44),
          const SizedBox(height: 12),
          Text(texto, style: TextStyle(color: kText2, fontSize: 14)),
        ],
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
            Icon(Icons.wifi_off_rounded, color: kDanger, size: 44),
            const SizedBox(height: 14),
            Text(
              'Não foi possível carregar as informações.',
              style: TextStyle(color: kText2, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                minimumSize: const Size(0, 46),
                side: BorderSide(color: kPrimary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
