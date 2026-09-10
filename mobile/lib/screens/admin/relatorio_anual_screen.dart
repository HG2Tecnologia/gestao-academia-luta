import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/firestore_service.dart';

String _mesLongo(BuildContext c, int m) {
  final loc = Localizations.localeOf(c).languageCode;
  return toBeginningOfSentenceCase(
        DateFormat.MMMM(loc).format(DateTime(2020, m)),
      ) ??
      '';
}

String _mesCurto(BuildContext c, int m) {
  final loc = Localizations.localeOf(c).languageCode;
  return toBeginningOfSentenceCase(
        DateFormat.MMM(loc).format(DateTime(2020, m)),
      ) ??
      '';
}

class AdminRelatorioAnualScreen extends StatefulWidget {
  const AdminRelatorioAnualScreen({super.key});

  @override
  State<AdminRelatorioAnualScreen> createState() =>
      _AdminRelatorioAnualScreenState();
}

class _AdminRelatorioAnualScreenState extends State<AdminRelatorioAnualScreen> {
  AppLocalizations get _l => context.l10n;
  Map<String, dynamic>? _relatorio;
  bool _loading = true;
  bool _erro = false;
  late int _ano;
  String? _academiaId;

  final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _ano = DateTime.now().year;
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _erro = false;
    });
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId ?? '';
      if (_academiaId!.isEmpty) throw Exception('Academia não encontrada');

      final results = await Future.wait([
        firestoreService.getPagamentos(_academiaId!),
        firestoreService.getAlunos(_academiaId!),
      ]);

      final pagamentos = (results[0] as List).cast<Map<String, dynamic>>();
      final alunos = (results[1] as List).cast<Map<String, dynamic>>();

      // Filter pagamentos by year
      final pagamentosAno = pagamentos.where((p) {
        final dvStr =
            p['data_vencimento'] as String? ??
            p['dataVencimento'] as String? ??
            '';
        if (dvStr.isEmpty) return false;
        try {
          return DateTime.parse(dvStr).year == _ano;
        } catch (_) {
          return false;
        }
      }).toList();

      // Total recebido no ano (status == 1 or 'Pago')
      double totalRecebidoAno = 0;
      int qtdRecebidasAno = 0;
      for (final p in pagamentosAno) {
        final st = p['status'];
        final isPago = (st is int && st == 1) || st.toString() == 'Pago';
        if (isPago) {
          totalRecebidoAno += (p['valor'] as num? ?? 0).toDouble();
          qtdRecebidasAno++;
        }
      }

      // Active alunos
      final totalAlunosAtivos = alunos.where((a) => a['ativo'] == true).length;

      // Cadastro de alunos por id, para resolver nome/foto do inadimplente
      // quando o pagamento não traz esses campos.
      final alunosPorId = <String, Map<String, dynamic>>{
        for (final a in alunos)
          if ((a['id'] ?? '').toString().isNotEmpty) (a['id']).toString(): a,
      };

      // Inadimplentes: alunos with overdue (status == 2 / Atrasado) pagamentos
      final now = DateTime.now();
      final Map<String, Map<String, dynamic>> inadimpMap = {};
      for (final p in pagamentos) {
        final st = p['status'];
        final isAtrasado =
            (st is int && st == 2) || st.toString() == 'Atrasado';
        if (!isAtrasado) continue;
        final alunoId =
            p['aluno_id']?.toString() ?? p['alunoId']?.toString() ?? '';
        final cadastro = alunosPorId[alunoId];
        final nomeAluno = () {
          final doPagamento = (p['nome_aluno'] ?? p['nomeAluno'] ?? '')
              .toString()
              .trim();
          if (doPagamento.isNotEmpty && doPagamento != 'null') {
            return doPagamento;
          }
          final doCadastro = (cadastro?['nome'] ?? '').toString().trim();
          return doCadastro.isEmpty ? _l.raUnknownStudent : doCadastro;
        }();
        final fotoAluno =
            cadastro?['fotoBase64'] as String? ??
            cadastro?['foto_base64'] as String?;
        final dvStr =
            p['data_vencimento'] as String? ??
            p['dataVencimento'] as String? ??
            '';
        int diasAtraso = 0;
        try {
          final dv = DateTime.parse(dvStr);
          diasAtraso = now.difference(dv).inDays;
        } catch (_) {}
        final valor = (p['valor'] as num? ?? 0).toDouble();
        if (!inadimpMap.containsKey(alunoId)) {
          inadimpMap[alunoId] = {
            'alunoId': alunoId,
            'nomeAluno': nomeAluno,
            'fotoBase64': fotoAluno,
            'diasAtraso': diasAtraso,
            'totalDevido': 0.0,
          };
        }
        inadimpMap[alunoId]!['totalDevido'] =
            (inadimpMap[alunoId]!['totalDevido'] as double) + valor;
        if (diasAtraso > (inadimpMap[alunoId]!['diasAtraso'] as int)) {
          inadimpMap[alunoId]!['diasAtraso'] = diasAtraso;
        }
      }
      final inadimplentes = inadimpMap.values.toList()
        ..sort(
          (a, b) => (b['diasAtraso'] as int).compareTo(a['diasAtraso'] as int),
        );

      // Receita mensal: group pagamentosAno by month
      final Map<int, Map<String, double>> receitaPorMes = {};
      for (var m = 1; m <= 12; m++) {
        receitaPorMes[m] = {'recebido': 0, 'pendente': 0};
      }
      for (final p in pagamentosAno) {
        final dvStr =
            p['data_vencimento'] as String? ??
            p['dataVencimento'] as String? ??
            '';
        int mes = 0;
        try {
          mes = DateTime.parse(dvStr).month;
        } catch (_) {}
        if (mes < 1 || mes > 12) continue;
        final valor = (p['valor'] as num? ?? 0).toDouble();
        final st = p['status'];
        final isPago = (st is int && st == 1) || st.toString() == 'Pago';
        if (isPago) {
          receitaPorMes[mes]!['recebido'] =
              receitaPorMes[mes]!['recebido']! + valor;
        } else {
          receitaPorMes[mes]!['pendente'] =
              receitaPorMes[mes]!['pendente']! + valor;
        }
      }
      final receitaMensal = List.generate(
        12,
        (i) => {
          'mes': i + 1,
          'recebido': receitaPorMes[i + 1]!['recebido'],
          'pendente': receitaPorMes[i + 1]!['pendente'],
        },
      );

      final dados = {
        'totalRecebidoAno': totalRecebidoAno,
        'qtdRecebidasAno': qtdRecebidasAno,
        'totalAlunosAtivos': totalAlunosAtivos,
        'totalInadimplentes': inadimplentes.length,
        'receitaMensal': receitaMensal,
        'inadimplentes': inadimplentes,
        'temMovimento': pagamentosAno.isNotEmpty,
      };

      if (mounted) {
        setState(() {
          _relatorio = dados;
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

  void _navAno(int delta) {
    setState(() {
      _ano += delta;
    });
    _load();
  }

  double get _maxReceita {
    final lista = _receitaMensal;
    if (lista.isEmpty) return 1;
    return lista
        .map(
          (m) =>
              (m['recebido'] as num? ?? 0).toDouble() +
              (m['pendente'] as num? ?? 0).toDouble(),
        )
        .reduce((a, b) => a > b ? a : b);
  }

  List<Map<String, dynamic>> get _receitaMensal {
    final raw = _relatorio?['receitaMensal'];
    if (raw == null) return [];
    return (raw as List).cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> get _inadimplentes {
    final raw = _relatorio?['inadimplentes'];
    if (raw == null) return [];
    return (raw as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        surfaceTintColor: Colors.transparent,
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
          context.l10n.raTitle,
          style: TextStyle(
            color: context.c.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.c.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _erro
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: context.sem.danger,
                      size: 52,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.raLoadError,
                      style: TextStyle(color: context.c.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.l10n.commonRetry),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.c.primary,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AnoSelector(ano: _ano, onNav: _navAno),
                    const SizedBox(height: 20),
                    _SectionTitle(context.l10n.raYearOverview),
                    const SizedBox(height: 12),
                    _SummaryCards(relatorio: _relatorio ?? {}, brl: _brl),
                    if (_relatorio?['temMovimento'] == false) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.c.surfaceContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.c.outline),
                        ),
                        child: Text(
                          context.l10n.raNoMovement(_ano),
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _SectionTitle(context.l10n.raMonthlyRevenue),
                    const SizedBox(height: 12),
                    _BarChart(
                      meses: _receitaMensal,
                      maxVal: _maxReceita,
                      brl: _brl,
                      ano: _ano,
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(
                      context.l10n.raOverdueCount(_inadimplentes.length),
                    ),
                    const SizedBox(height: 12),
                    if (_inadimplentes.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.sem.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: context.sem.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: context.sem.success,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.l10n.raNoOverdue,
                                style: TextStyle(
                                  color: context.sem.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...(_inadimplentes.map(
                        (a) => _InadimplenteCard(aluno: a, brl: _brl),
                      )),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AnoSelector extends StatelessWidget {
  const _AnoSelector({required this.ano, required this.onNav});
  final int ano;
  final void Function(int) onNav;

  @override
  Widget build(BuildContext context) {
    final podeAvancar = ano < DateTime.now().year;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => onNav(-1),
            tooltip: context.l10n.raPrevYear,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: context.c.onSurface,
              size: 26,
            ),
          ),
          Expanded(
            child: Text(
              '$ano',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: podeAvancar ? () => onNav(1) : null,
            tooltip: context.l10n.raNextYear,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: podeAvancar ? context.c.onSurface : context.c.outline,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.relatorio, required this.brl});
  final Map<String, dynamic> relatorio;
  final NumberFormat brl;

  @override
  Widget build(BuildContext context) {
    final total = (relatorio['totalRecebidoAno'] as num? ?? 0).toDouble();
    final qtdReceb = relatorio['qtdRecebidasAno'] as int? ?? 0;
    final ativos = relatorio['totalAlunosAtivos'] as int? ?? 0;
    final inadimplentes = relatorio['totalInadimplentes'] as int? ?? 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Card(
              label: context.l10n.raReceivedYear,
              value: brl.format(total),
              icon: Icons.attach_money_rounded,
              color: context.sem.success,
              sub: qtdReceb > 0 ? context.l10n.raChargesCount(qtdReceb) : null,
              subIcon: Icons.receipt_long_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Card(
              label: context.l10n.dashActiveStudents,
              value: '$ativos',
              icon: Icons.sports_martial_arts_rounded,
              color: context.c.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Card(
              label: context.l10n.raOverdue,
              value: '$inadimplentes',
              icon: Icons.warning_amber_rounded,
              color: context.sem.danger,
              sub: inadimplentes > 0 ? context.l10n.raOutstanding : null,
              subIcon: Icons.schedule_rounded,
              subColor: context.sem.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sub,
    this.subIcon,
    this.subColor,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  final String? sub;
  final IconData? subIcon;
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: context.c.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (subIcon != null) ...[
                  Icon(
                    subIcon,
                    size: 11,
                    color: subColor ?? context.c.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    sub!,
                    style: TextStyle(
                      color: subColor ?? context.c.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.meses,
    required this.maxVal,
    required this.brl,
    required this.ano,
  });
  final List<Map<String, dynamic>> meses;
  final double maxVal;
  final NumberFormat brl;
  final int ano;

  static const _barH = 150.0;

  double _niceMax(double v) {
    if (v <= 0) return 1;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    final norm = v / mag;
    final nice = norm <= 1
        ? 1.0
        : norm <= 2
        ? 2.0
        : norm <= 5
        ? 5.0
        : 10.0;
    return nice * mag;
  }

  String _axisLabel(double v) {
    if (v >= 1000000) {
      final n = v / 1000000;
      return '${n.toStringAsFixed(n % 1 == 0 ? 0 : 1).replaceAll('.', ',')}M';
    }
    if (v >= 1000) {
      final n = v / 1000;
      return '${n.toStringAsFixed(n % 1 == 0 ? 0 : 1).replaceAll('.', ',')}k';
    }
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final byMonth = {for (final m in meses) (m['mes'] as int? ?? 0): m};
    final niceMax = _niceMax(maxVal);
    final semDados = maxVal <= 0;
    const linhas = 4; // divisões do eixo Y

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eixo Y
              SizedBox(
                width: 34,
                height: _barH + 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = linhas; i >= 0; i--)
                      Expanded(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            _axisLabel(niceMax * i / linhas),
                            style: TextStyle(
                              color: context.c.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: _barH,
                      child: Stack(
                        children: [
                          // Gridlines
                          Column(
                            children: [
                              for (var i = 0; i < linhas; i++)
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      height: 1,
                                      color: context.c.outline.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 1,
                              color: context.c.outline,
                            ),
                          ),
                          // Barras
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(12, (i) {
                              final data = byMonth[i + 1];
                              final recebido = (data?['recebido'] as num? ?? 0)
                                  .toDouble();
                              final pendente = (data?['pendente'] as num? ?? 0)
                                  .toDouble();
                              final total = recebido + pendente;
                              final recH = niceMax > 0
                                  ? (recebido / niceMax) * _barH
                                  : 0.0;
                              final penH = niceMax > 0
                                  ? (pendente / niceMax) * _barH
                                  : 0.0;

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: total > 0
                                      ? Tooltip(
                                          message: context.l10n.raBarTooltip(
                                            _mesLongo(context, i + 1),
                                            ano,
                                            brl.format(recebido),
                                            brl.format(pendente),
                                            brl.format(total),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              if (penH > 0)
                                                Container(
                                                  height: penH.clamp(
                                                    2.0,
                                                    _barH,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: context.sem.warning,
                                                    borderRadius: recH > 0
                                                        ? const BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  4,
                                                                ),
                                                          )
                                                        : BorderRadius.circular(
                                                            4,
                                                          ),
                                                  ),
                                                ),
                                              if (recH > 0)
                                                Container(
                                                  height: recH.clamp(
                                                    2.0,
                                                    _barH,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: context.sem.success,
                                                    borderRadius: penH > 0
                                                        ? const BorderRadius.vertical(
                                                            bottom:
                                                                Radius.circular(
                                                                  4,
                                                                ),
                                                          )
                                                        : BorderRadius.circular(
                                                            4,
                                                          ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        )
                                      : Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: context.c.outline,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        12,
                        (i) => Expanded(
                          child: Text(
                            _mesCurto(context, i + 1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.c.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (semDados)
            Text(
              context.l10n.raNoRevenueYear(ano),
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(
                  color: context.sem.success,
                  label: context.l10n.raReceived,
                ),
                const SizedBox(width: 16),
                _Legend(
                  color: context.sem.warning,
                  label: context.l10n.finPending,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }
}

class _InadimplenteCard extends StatelessWidget {
  const _InadimplenteCard({required this.aluno, required this.brl});
  final Map<String, dynamic> aluno;
  final NumberFormat brl;

  @override
  Widget build(BuildContext context) {
    final total = (aluno['totalDevido'] as num? ?? 0).toDouble();
    final dias = aluno['diasAtraso'] as int? ?? 0;
    final nome = aluno['nomeAluno']?.toString() ?? '';
    final alunoId = aluno['alunoId']?.toString() ?? '';
    final foto = aluno['fotoBase64'] as String?;
    final temFoto = foto != null && foto.contains(',');
    final iniciais = nome
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: alunoId.isEmpty
              ? null
              : () => context.push('/admin/alunos/$alunoId'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.c.outline),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: context.sem.danger.withValues(alpha: 0.15),
                  backgroundImage: temFoto
                      ? MemoryImage(base64Decode(foto.split(',').last))
                      : null,
                  child: temFoto
                      ? null
                      : Text(
                          iniciais.isEmpty ? '?' : iniciais,
                          style: TextStyle(
                            color: context.sem.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.raDaysOverdue(dias),
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      brl.format(total),
                      style: TextStyle(
                        color: context.sem.danger,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      context.l10n.raOutstanding,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.c.onSurfaceVariant,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.c.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
