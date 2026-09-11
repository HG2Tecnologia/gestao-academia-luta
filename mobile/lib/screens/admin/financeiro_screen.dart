import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/ad_banner.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/drawer_helper.dart';
import '../../core/finance_service.dart';
import '../../core/financeiro_resumo.dart';
import '../../core/firestore_service.dart';
import '../../core/pagamento_status.dart';
import '../../core/tab_refresh.dart';

class AdminFinanceiroScreen extends StatefulWidget {
  const AdminFinanceiroScreen({super.key});

  @override
  State<AdminFinanceiroScreen> createState() => _AdminFinanceiroScreenState();
}

class _AdminFinanceiroScreenState extends State<AdminFinanceiroScreen> {
  AppLocalizations get _l => context.l10n;

  String _mesCurto(int m) {
    final loc = Localizations.localeOf(context).languageCode;
    return toBeginningOfSentenceCase(
          DateFormat.MMM(loc).format(DateTime(2020, m)),
        ) ??
        '';
  }

  String _statusLabel(String? st) {
    switch (st) {
      case 'Pago':
        return _l.fiStPaid;
      case 'Atrasado':
        return _l.fiStOverdue;
      case 'Previsto':
        return _l.fiStForecast;
      case 'Desconsiderado':
        return _l.fiStDismissed;
      default:
        return _l.fiStPending;
    }
  }

  String _tipoLabel(String? t) =>
      t == 'Taxa de Matrícula' ? _l.fiTypeEnrollment : _l.fiTypeMonthly;

  Map<String, dynamic>? _resumo;
  List<Map<String, dynamic>> _cobrancas = [];
  bool _loading = true;
  String? _academiaId;

  late int _ano;
  late int _mes;

  String _busca = '';
  final TextEditingController _buscaCtrl = TextEditingController();
  String _tabFiltro =
      'todos'; // todos | pendente | atrasado | pago | desconsiderado

  bool _taxaAtrasoAtiva = false;
  int _taxaAtrasoTipo = 0;
  double _taxaAtrasoValor = 0.0;

  static const _statusMap = {
    0: 'Pendente',
    1: 'Pago',
    2: 'Atrasado',
    3: 'Previsto',
    4: 'Desconsiderado',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _ano = now.year;
    _mes = now.month;
    adminTabNotifier.addListener(_onTabChanged);
    _load();
  }

  @override
  void dispose() {
    adminTabNotifier.removeListener(_onTabChanged);
    _buscaCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (adminTabNotifier.value == 4) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId ?? '';
      if (_academiaId!.isEmpty) return;

      // Garantia server-side: nunca gera mensalidade só no cliente. Falha
      // de rede/permite aqui não trava a tela — só mostra o que já existe.
      final periodo = '$_ano-${_mes.toString().padLeft(2, '0')}';
      try {
        await FinanceService.ensureChargesForPeriod(
          academiaId: _academiaId!,
          period: periodo,
        );
      } catch (_) {}

      final results = await Future.wait([
        firestoreService.getPagamentos(_academiaId!),
        firestoreService.getAcademia(_academiaId!).catchError((_) => null),
      ]);

      final todos = results[0] as List<Map<String, dynamic>>;
      final acadData = results[1] as Map<String, dynamic>? ?? {};

      _taxaAtrasoAtiva = acadData['taxa_atraso_ativa'] as bool? ?? false;
      _taxaAtrasoTipo = (acadData['taxa_atraso_tipo'] as num?)?.toInt() ?? 0;
      _taxaAtrasoValor =
          (acadData['taxa_atraso_valor'] as num?)?.toDouble() ?? 0.0;

      final now = DateTime.now();
      final hoje = DateTime(now.year, now.month, now.day);

      // Filter for selected month
      final doMes = todos.where((p) {
        final venc = p['data_vencimento'] as String? ?? '';
        if (venc.isEmpty) return false;
        try {
          final dt = DateTime.parse(venc);
          return dt.year == _ano && dt.month == _mes;
        } catch (_) {
          return false;
        }
      }).toList();

      // Resumo client-side — fonte única compartilhada com os testes
      // (financeiro_resumo.dart). Ignora Desconsiderado por completo.
      final resumo = resumoFinanceiroAcademia(
        todos,
        ano: _ano,
        mes: _mes,
        hoje: hoje,
      );

      // Convert status for display; compute effective status (Atrasado if pending+overdue)
      final cobrancasComStatus = doMes.map((p) {
        // Status efetivo: fonte única compartilhada com o app do aluno
        // (Pendente/Previsto vencido → Atrasado; Pago/Desconsiderado intactos).
        final stEf = pagamentoStatusEfetivo(
          rawStatus: p['status'],
          dataVencimento: p['data_vencimento'],
          hoje: hoje,
        );
        final statusStr = switch (stEf) {
          PagamentoStatus.pago => 'Pago',
          PagamentoStatus.atrasado => 'Atrasado',
          PagamentoStatus.previsto => 'Previsto',
          PagamentoStatus.desconsiderado => 'Desconsiderado',
          PagamentoStatus.pendente => 'Pendente',
        };
        final rawNome =
            (p['nome_aluno'] ?? p['nomeAluno'] ?? p['aluno_nome'] ?? '')
                .toString();
        final rawTipo = p['tipo']?.toString() ?? '';
        return {
          ...p,
          'status': statusStr,
          'nomeAluno': rawNome == 'null' ? '' : rawNome,
          'dataVencimento': p['data_vencimento'] ?? p['dataVencimento'] ?? '',
          'tipo': (rawTipo.isEmpty || rawTipo == 'null')
              ? 'Mensalidade'
              : rawTipo,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _resumo = resumo.toMap();
          _cobrancas = cobrancasComStatus.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _cobrancasFiltradas {
    final busca = _busca.toLowerCase().trim();
    return _cobrancas.where((c) {
      final nome = (c['nomeAluno'] as String? ?? '').toLowerCase();
      if (busca.isNotEmpty && !nome.contains(busca)) return false;
      final status = c['status'] as String? ?? '';
      switch (_tabFiltro) {
        case 'pendente':
          return status == 'Pendente';
        case 'atrasado':
          return status == 'Atrasado';
        case 'pago':
          return status == 'Pago';
        case 'desconsiderado':
          return status == 'Desconsiderado';
        default:
          return status !=
              'Desconsiderado'; // "todos" oculta desconsiderados por padrão
      }
    }).toList();
  }

  void _navMes(int delta) {
    setState(() {
      _mes += delta;
      if (_mes > 12) {
        _mes = 1;
        _ano++;
      }
      if (_mes < 1) {
        _mes = 12;
        _ano--;
      }
    });
    _load();
  }

  void _irParaMesAtual() {
    final now = DateTime.now();
    if (_ano == now.year && _mes == now.month) return;
    setState(() {
      _ano = now.year;
      _mes = now.month;
    });
    _load();
  }

  static final _brl = NumberFormat('#,##0.00', 'pt_BR');
  static final _brlInt = NumberFormat('#,##0', 'pt_BR');

  String _fmtVal(num v) => 'R\$ ${_brl.format(v)}';
  String _fmtInt(num v) => 'R\$ ${_brlInt.format(v)}';

  Color _statusCor(String? s) {
    if (s == 'Pago') return context.sem.success;
    if (s == 'Pendente') return context.sem.warning;
    if (s == 'Previsto') return context.c.onSurfaceVariant;
    if (s == 'Desconsiderado') return context.c.onSurfaceVariant;
    return context.sem.danger; // Atrasado
  }

  Future<void> _criarCobrancaAvulsa() async {
    if (_academiaId == null) return;
    List<Map<String, dynamic>> alunos = [];
    try {
      alunos = await firestoreService.getAlunos(_academiaId!, ativosOnly: true);
    } catch (_) {}

    if (!mounted) return;

    String? alunoId;
    int tipo = 1;
    final valorCtrl = TextEditingController();
    DateTime vencimento = DateTime.now().add(const Duration(days: 5));

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.c.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: context.c.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _l.fiNewCharge,
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _l.sdTitleFallback,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.c.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.c.outline),
                ),
                child: DropdownButton<String>(
                  value: alunoId,
                  isExpanded: true,
                  dropdownColor: context.c.surfaceContainer,
                  underline: const SizedBox(),
                  hint: Text(
                    _l.fiSelectStudent,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: context.c.onSurfaceVariant,
                  ),
                  items: alunos
                      .map(
                        (a) => DropdownMenuItem<String>(
                          value: a['id']?.toString(),
                          child: Text(
                            a['nome']?.toString() ?? '',
                            style: TextStyle(
                              color: context.c.onSurface,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setModal(() => alunoId = v),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _l.fiType,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.c.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.c.outline),
                ),
                child: DropdownButton<int>(
                  value: tipo,
                  isExpanded: true,
                  dropdownColor: context.c.surfaceContainer,
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: context.c.onSurfaceVariant,
                  ),
                  items: [
                    DropdownMenuItem(value: 1, child: Text(_l.fiTypeMonthly)),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('Taxa de Matrícula'),
                    ),
                  ],
                  onChanged: (v) => setModal(() => tipo = v ?? 1),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _l.caAmountHint,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: valorCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(color: context.c.onSurface, fontSize: 15),
                decoration: InputDecoration(
                  hintText: '0,00',
                  hintStyle: TextStyle(color: context.c.onSurfaceVariant),
                  filled: true,
                  fillColor: context.c.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.c.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.c.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.c.primary),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _l.sdDueDate,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: vencimento,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('pt', 'BR'),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: context.c.primary,
                          surface: context.c.surfaceContainer,
                          onSurface: context.c.onSurface,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => vencimento = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.c.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.c.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: context.c.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${vencimento.day.toString().padLeft(2, '0')}/${vencimento.month.toString().padLeft(2, '0')}/${vencimento.year}',
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: alunoId == null
                    ? null
                    : () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: context.c.primary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: context.c.primary.withOpacity(0.3),
                ),
                child: Text(
                  _l.fiGenerateCharge,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.c.onSurfaceVariant,
                  side: BorderSide(color: context.c.outline),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_l.commonCancel),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true || alunoId == null || !mounted) return;
    final valorStr = valorCtrl.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(valorStr) ?? 0;
    if (valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l.commonEnterValidValue),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final dataStr =
        '${vencimento.year}-${vencimento.month.toString().padLeft(2, '0')}-${vencimento.day.toString().padLeft(2, '0')}';
    // Find aluno name
    final alunoSel = alunos.firstWhere(
      (a) => a['id']?.toString() == alunoId,
      orElse: () => {},
    );
    final nomeAluno = alunoSel['nome']?.toString() ?? '';
    final tipoStr = tipo == 1 ? 'Mensalidade' : 'Taxa de Matrícula';
    final tipoLabelStr = tipo == 1 ? _l.fiTypeMonthly : _l.fiTypeEnrollment;
    try {
      await firestoreService.addPagamento(_academiaId!, {
        'aluno_id': alunoId,
        'nome_aluno': nomeAluno,
        'tipo': tipoStr,
        'valor': valor,
        'data_vencimento': dataStr,
        'status': 0,
      });
      if (mounted) {
        _load();
        final tel = alunoSel['telefone']?.toString() ?? '';
        showModalBottomSheet(
          context: context,
          backgroundColor: context.c.surfaceContainer,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (c) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    decoration: BoxDecoration(
                      color: context.c.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: context.sem.success.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: context.sem.success,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _l.fiChargeCreated,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$nomeAluno · $tipoLabelStr · ${_fmtVal(valor)}',
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (tel.replaceAll(RegExp(r'\D'), '').length >= 10) ...[
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(c).pop();
                      _abrirWhatsApp(tel, nomeAluno);
                    },
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                    label: Text(
                      _l.fiChargeViaWhatsapp,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton(
                  onPressed: () => Navigator.of(c).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.c.onSurfaceVariant,
                    side: BorderSide(color: context.c.outline),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_l.commonClose),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.fiCreateError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _abrirWhatsApp(String? telefone, String nome) async {
    if (telefone == null || telefone.isEmpty) return;
    final digits = telefone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return;
    final ddi = digits.startsWith('55') ? digits : '55$digits';
    final msg = Uri.encodeComponent(_l.fiWhatsappGreeting(nome));
    final url = Uri.parse('https://wa.me/$ddi?text=$msg');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _abrirModalCobrancas() async {
    if (_academiaId == null) return;

    List<Map<String, dynamic>> turmasList = [];
    List<Map<String, dynamic>> todosAlunos = [];
    List<Map<String, dynamic>> todosPagamentos = [];

    try {
      final results = await Future.wait([
        firestoreService.getTurmas(_academiaId!),
        firestoreService.getAlunos(_academiaId!, ativosOnly: true),
        firestoreService.getPagamentos(_academiaId!),
      ]);
      turmasList = List<Map<String, dynamic>>.from(results[0] as List);
      todosAlunos = List<Map<String, dynamic>>.from(results[1] as List);
      todosPagamentos = List<Map<String, dynamic>>.from(results[2] as List);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.fiLoadError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    if (!mounted) return;

    final alunosComCobrancaMes = _cobrancas
        .map((c) => c['aluno_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    const statusPriority = {
      'Atrasado': 3,
      'Pendente': 2,
      'Previsto': 1,
      'Pago': 0,
    };
    final statusMap = <String, String>{};
    final vencMap = <String, DateTime>{};
    final now = DateTime.now();

    for (final p in todosPagamentos) {
      final alunoId = p['aluno_id']?.toString() ?? '';
      if (alunoId.isEmpty) continue;
      final statusRaw = p['status'];
      final statusInt = statusRaw is int
          ? statusRaw
          : int.tryParse(statusRaw.toString()) ?? 0;
      final statusStr = _statusMap[statusInt] ?? 'Pendente';
      DateTime? vencDt;
      try {
        vencDt = DateTime.parse(p['data_vencimento']?.toString() ?? '');
      } catch (_) {}

      final prev = statusMap[alunoId];
      if (prev == null ||
          (statusPriority[statusStr] ?? 0) > (statusPriority[prev] ?? 0)) {
        statusMap[alunoId] = statusStr;
      }
      if (vencDt != null) {
        final existing = vencMap[alunoId];
        if (existing == null || vencDt.isBefore(existing))
          vencMap[alunoId] = vencDt;
      }
    }

    int step = 0;
    String mode = 'turma';
    String? turmaId;
    String filtro = 'gerar';
    List<Map<String, dynamic>> previewAlunos = [];
    List<Map<String, dynamic>> successAlunos = [];
    bool stepLoading = false;

    List<Map<String, dynamic>> applyFilter(List<Map<String, dynamic>> base) {
      switch (filtro) {
        case 'gerar':
          return base
              .where(
                (a) =>
                    !alunosComCobrancaMes.contains(a['id']?.toString() ?? ''),
              )
              .toList();
        case 'atrasados':
          return base
              .where((a) => statusMap[a['id']?.toString() ?? ''] == 'Atrasado')
              .toList();
        case 'pendentes':
          return base.where((a) {
            final s = statusMap[a['id']?.toString() ?? ''];
            return s == 'Pendente' || s == 'Previsto';
          }).toList();
        case 'proximo':
          return base.where((a) {
            final venc = vencMap[a['id']?.toString() ?? ''];
            if (venc == null) return false;
            final diff = venc.difference(now).inDays;
            return diff >= -1 && diff <= 7;
          }).toList();
        default:
          return base;
      }
    }

    final filtroOpcoes = [
      {
        'key': 'gerar',
        'label': _l.fiOptNoChargeMonth,
        'icon': Icons.add_circle_outline_rounded,
      },
      {
        'key': 'atrasados',
        'label': _l.fiTabOverdue,
        'icon': Icons.warning_rounded,
      },
      {
        'key': 'pendentes',
        'label': _l.fiTabPending,
        'icon': Icons.schedule_rounded,
      },
      {
        'key': 'proximo',
        'label': _l.fiOptDueWithin7,
        'icon': Icons.event_rounded,
      },
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final isGerar = filtro == 'gerar';

          final dragHandle = Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.c.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );

          // ── Step 0: escolher modo ─────────────────────
          if (step == 0) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dragHandle,
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        color: context.c.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _l.fiGenerateCharges,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _l.fiChooseWhoToCharge,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _modeCard(
                    icon: Icons.group_rounded,
                    title: _l.fiByClass,
                    subtitle: _l.fiByClassHint,
                    onTap: () => setModal(() {
                      mode = 'turma';
                      step = 1;
                    }),
                  ),
                  const SizedBox(height: 10),
                  _modeCard(
                    icon: Icons.groups_rounded,
                    title: _l.fiAllActive,
                    subtitle: _l.fiAllActiveHint,
                    onTap: () => setModal(() {
                      mode = 'todos';
                      step = 1;
                    }),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.c.onSurfaceVariant,
                      side: BorderSide(color: context.c.outline),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_l.commonCancel),
                  ),
                ],
              ),
            );
          }

          // ── Step 1: turma + filtro ───────────────────
          if (step == 1) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dragHandle,
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setModal(() => step = 0),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: context.c.onSurface,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        mode == 'turma' ? _l.fiByClass : _l.fiAllActive,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (mode == 'turma') ...[
                    Text(
                      'Turma',
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.c.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.c.outline),
                      ),
                      child: DropdownButton<String>(
                        value: turmaId,
                        isExpanded: true,
                        dropdownColor: context.c.surfaceContainer,
                        underline: const SizedBox(),
                        hint: Text(
                          _l.fiSelectClass,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: context.c.onSurfaceVariant,
                        ),
                        items: turmasList
                            .map(
                              (t) => DropdownMenuItem<String>(
                                value: t['id']?.toString(),
                                child: Text(
                                  t['nome']?.toString() ?? '',
                                  style: TextStyle(
                                    color: context.c.onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setModal(() => turmaId = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    _l.fiFilterBySituation,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filtroOpcoes.map((f) {
                      final sel = filtro == f['key'];
                      return GestureDetector(
                        onTap: () =>
                            setModal(() => filtro = f['key'] as String),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? context.c.primary : context.c.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? context.c.primary
                                  : context.c.outline,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                f['icon'] as IconData,
                                size: 13,
                                color: sel
                                    ? Colors.white
                                    : context.c.onSurfaceVariant,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                f['label'] as String,
                                style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : context.c.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed:
                        (mode == 'turma' && turmaId == null) || stepLoading
                        ? null
                        : () async {
                            setModal(() => stepLoading = true);
                            List<Map<String, dynamic>> base = todosAlunos;
                            if (mode == 'turma' && turmaId != null) {
                              try {
                                final matriculas = await firestoreService
                                    .getMatriculas(
                                      _academiaId!,
                                      turmaId: turmaId!,
                                      ativasOnly: true,
                                    );
                                final ids = matriculas
                                    .map((m) => m['aluno_id']?.toString() ?? '')
                                    .where((id) => id.isNotEmpty)
                                    .toSet();
                                base = todosAlunos
                                    .where(
                                      (a) => ids.contains(
                                        a['id']?.toString() ?? '',
                                      ),
                                    )
                                    .toList();
                              } catch (_) {
                                base = [];
                              }
                            }
                            final prev = applyFilter(base);
                            setModal(() {
                              previewAlunos = prev;
                              stepLoading = false;
                              step = 2;
                            });
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: context.c.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: context.c.primary.withOpacity(
                        0.3,
                      ),
                    ),
                    child: stepLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _l.fiSeeAffected,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => setModal(() => step = 0),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.c.onSurfaceVariant,
                      side: BorderSide(color: context.c.outline),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_l.commonBack),
                  ),
                ],
              ),
            );
          }

          // ── Step 2: preview ──────────────────────────
          if (step == 2) {
            final count = previewAlunos.length;
            final actionLabel = isGerar
                ? _l.fiGenerateNCharges(count)
                : _l.fiChargeViaWhatsappN(count);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dragHandle,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setModal(() => step = 1),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: context.c.onSurface,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _l.fiAffectedStudents(count),
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (previewAlunos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: context.sem.success,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _l.fiNoStudentsForFilter,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.35,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: previewAlunos.length,
                      itemBuilder: (_, i) {
                        final a = previewAlunos[i];
                        final nome = a['nome']?.toString() ?? '';
                        final tel = a['telefone']?.toString() ?? '';
                        final s = statusMap[a['id']?.toString() ?? ''];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: context.c.primary.withOpacity(
                                  0.15,
                                ),
                                child: Text(
                                  nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: context.c.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nome,
                                      style: TextStyle(
                                        color: context.c.onSurface,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (s != null && !isGerar)
                                      Text(
                                        s,
                                        style: TextStyle(
                                          color: _statusCor(s),
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!isGerar &&
                                  tel.replaceAll(RegExp(r'\D'), '').length >=
                                      10)
                                const FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: Color(0xFF25D366),
                                  size: 16,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    MediaQuery.of(ctx).viewInsets.bottom + 32,
                  ),
                  child: Column(
                    children: [
                      if (previewAlunos.isNotEmpty)
                        FilledButton(
                          onPressed: stepLoading
                              ? null
                              : () async {
                                  setModal(() => stepLoading = true);
                                  try {
                                    if (isGerar) {
                                      // Ferramenta manual/excepcional: usa o
                                      // mesmo caminho idempotente e
                                      // server-side da garantia automática —
                                      // nunca duplica nem sobrescreve
                                      // cobrança já existente na competência.
                                      final periodo =
                                          '$_ano-${_mes.toString().padLeft(2, '0')}';
                                      await FinanceService.ensureChargesForPeriod(
                                        academiaId: _academiaId!,
                                        period: periodo,
                                      );
                                      _load();
                                    }
                                    successAlunos = previewAlunos;
                                    setModal(() {
                                      stepLoading = false;
                                      step = 3;
                                    });
                                  } catch (_) {
                                    setModal(() => stepLoading = false);
                                    if (mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(_l.fiProcessError),
                                          backgroundColor: context.sem.danger,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: isGerar
                                ? context.c.primary
                                : const Color(0xFF25D366),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: stepLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  actionLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => setModal(() {
                          step = 1;
                          stepLoading = false;
                        }),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.c.onSurfaceVariant,
                          side: BorderSide(color: context.c.outline),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_l.commonBack),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // ── Step 3: sucesso + WhatsApp ───────────────
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dragHandle,
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color:
                              (isGerar
                                      ? context.sem.success
                                      : const Color(0xFF25D366))
                                  .withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: isGerar
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: context.sem.success,
                                size: 32,
                              )
                            : const FaIcon(
                                FontAwesomeIcons.whatsapp,
                                color: Color(0xFF25D366),
                                size: 32,
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isGerar
                            ? _l.fiNChargesGenerated(successAlunos.length)
                            : _l.fiReadyForWhatsapp,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _l.fiTapEachStudent,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...successAlunos.map((a) {
                  final nome = a['nome']?.toString() ?? '';
                  final tel = a['telefone']?.toString() ?? '';
                  final hasTel = tel.replaceAll(RegExp(r'\D'), '').length >= 10;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: hasTel ? () => _abrirWhatsApp(tel, nome) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: hasTel
                              ? const Color(0xFF25D366).withOpacity(0.08)
                              : context.c.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasTel
                                ? const Color(0xFF25D366).withOpacity(0.3)
                                : context.c.outline,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: context.c.primary.withOpacity(
                                0.15,
                              ),
                              child: Text(
                                nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: context.c.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                nome,
                                style: TextStyle(
                                  color: context.c.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (hasTel)
                              Icon(
                                Icons.chat_rounded,
                                color: const Color(0xFF25D366),
                                size: 20,
                              )
                            else
                              Text(
                                _l.fiNoPhone,
                                style: TextStyle(
                                  color: context.c.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.c.primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _l.commonClose,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _marcarPago(Map<String, dynamic> c) async {
    final valorBase = (c['valor'] as num? ?? 0).toDouble();
    final descontoCtrl = TextEditingController();
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) {
          double desconto =
              double.tryParse(descontoCtrl.text.replaceAll(',', '.')) ?? 0.0;
          final valorPago = (valorBase - desconto).clamp(0.0, double.infinity);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: context.c.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  _l.fiMarkPaid,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${c['nomeAluno']} · ${c['tipo']}',
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _l.fiBaseValue,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _fmtVal(valorBase),
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (desconto > 0) ...[
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _l.fiToReceive,
                            style: TextStyle(
                              color: context.c.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            _fmtVal(valorPago),
                            style: TextStyle(
                              color: context.sem.success,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descontoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: context.c.onSurface),
                  onChanged: (_) => setM(() {}),
                  decoration: InputDecoration(
                    hintText: _l.fiDiscountOptional,
                    hintStyle: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    prefixText: 'R\$ ',
                    prefixStyle: TextStyle(color: context.c.onSurfaceVariant),
                    filled: true,
                    fillColor: context.c.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
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
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(
                    ctx,
                  ).pop({'desconto': desconto, 'valorPago': valorPago}),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.sem.success,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _l.fiConfirmPayment,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.c.onSurfaceVariant,
                    side: BorderSide(color: context.c.outline),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_l.commonCancel),
                ),
              ],
            ),
          );
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => descontoCtrl.dispose());
    if (result == null || !mounted || _academiaId == null) return;
    try {
      final now = DateTime.now();
      final dataStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final desconto = (result['desconto'] as double? ?? 0.0);
      final valorPago = (result['valorPago'] as double? ?? valorBase);
      await firestoreService.updatePagamento(_academiaId!, c['id'].toString(), {
        'status': 1,
        'data_pagamento': dataStr,
        if (desconto > 0) 'desconto': desconto,
        if (desconto > 0) 'valor_pago': valorPago,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.fiMarkedPaid(c['nomeAluno']?.toString() ?? '')),
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
            content: Text(_l.fiUpdateError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _estornar(Map<String, dynamic> c) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.c.surfaceContainer,
            title: Text(
              _l.fiRefundTitle,
              style: TextStyle(
                color: context.c.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            content: Text(
              _l.fiRefundBody(c['nomeAluno']?.toString() ?? ''),
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
                  _l.fiRefundShort,
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
    if (!ok || !mounted || _academiaId == null) return;
    try {
      await firestoreService.updatePagamento(_academiaId!, c['id'].toString(), {
        'status': 0,
        'data_pagamento': null,
        'desconto': null,
        'valor_pago': null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.fiRefundDone),
            backgroundColor: context.sem.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _load();
      }
    } catch (_) {}
  }

  Future<void> _desconsiderar(Map<String, dynamic> c) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.c.surfaceContainer,
            title: Text(
              _l.fiDismissTitle,
              style: TextStyle(
                color: context.c.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            content: Text(
              _l.fiDismissBody(c['nomeAluno']?.toString() ?? ''),
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
                  _l.fiDismiss,
                  style: TextStyle(
                    color: context.sem.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted || _academiaId == null) return;
    try {
      await firestoreService.updatePagamento(_academiaId!, c['id'].toString(), {
        'status': 4,
      });
      if (mounted) {
        _load();
      }
    } catch (_) {}
  }

  Future<void> _restaurar(Map<String, dynamic> c) async {
    if (!mounted || _academiaId == null) return;
    try {
      await firestoreService.updatePagamento(_academiaId!, c['id'].toString(), {
        'status': 0,
      });
      if (mounted) {
        _load();
      }
    } catch (_) {}
  }

  Future<void> _excluirCobranca(Map<String, dynamic> c) async {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.fiDeleteCharge,
          style: TextStyle(
            color: context.c.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          _l.fiDeleteChargeBody,
          style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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
    if (ok != true || !mounted || _academiaId == null) return;
    try {
      await firestoreService.deletePagamento(_academiaId!, c['id'].toString());
      if (mounted) {
        _load();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final r = _resumo;
    final isAtual = DateTime.now().year == _ano && DateTime.now().month == _mes;
    return Scaffold(
      backgroundColor: context.c.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: _criarCobrancaAvulsa,
        backgroundColor: context.c.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.c.primary,
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _l.navBilling,
                              style: TextStyle(
                                color: context.c.onSurface,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: openAppDrawer,
                              child: Icon(
                                Icons.menu_rounded,
                                color: context.c.onSurface,
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    context.push('/admin/financeiro/relatorio'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.c.surfaceContainer,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: context.c.outline,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bar_chart_rounded,
                                        color: context.c.onSurfaceVariant,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _l.fiReportTab,
                                        style: TextStyle(
                                          color: context.c.onSurfaceVariant,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    context.push('/admin/financeiro/contas'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.c.surfaceContainer,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: context.c.outline,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_rounded,
                                        color: context.c.onSurfaceVariant,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _l.fiBillsShort,
                                        style: TextStyle(
                                          color: context.c.onSurfaceVariant,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _abrirModalCobrancas,
                                icon: Icon(
                                  Icons.receipt_long_rounded,
                                  size: 16,
                                  color: context.c.primary,
                                ),
                                label: Text(
                                  _l.fiGenerateCharges,
                                  style: TextStyle(
                                    color: context.c.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: context.c.primary
                                      .withOpacity(0.10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.c.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.c.outline),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => _navMes(-1),
                                icon: Icon(
                                  Icons.chevron_left,
                                  color: context.c.onSurface,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_mesCurto(_mes)} $_ano',
                                    style: TextStyle(
                                      color: context.c.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (isAtual)
                                    Text(
                                      _l.fiCurrentMonth,
                                      style: TextStyle(
                                        color: context.c.primary,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                // Financeiro automático gera a competência
                                // atual + a próxima (Fase 7) — não faz sentido
                                // travar a navegação no mês atual.
                                onPressed: () => _navMes(1),
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: context.c.onSurface,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        if (!isAtual)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _irParaMesAtual,
                                icon: const Icon(
                                  Icons.keyboard_return_rounded,
                                  size: 16,
                                ),
                                label: Text(_l.fiBackToCurrentMonth),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: context.c.primary,
                                  side: BorderSide(
                                    color: context.c.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (r != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    sliver: SliverGrid.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.0,
                      children: [
                        _met(
                          label: _l.raReceived,
                          value: _fmtInt((r['totalRecebidoMes'] as num?) ?? 0),
                          color: context.sem.success,
                          icon: Icons.attach_money_rounded,
                          sub: _labelCobrancas((r['qtdRecebido'] as int?) ?? 0),
                        ),
                        _met(
                          label: _l.fiStPending,
                          value: _fmtInt((r['totalPendenteMes'] as num?) ?? 0),
                          color: context.sem.warning,
                          icon: Icons.schedule_rounded,
                          sub: _labelCobrancas((r['qtdPendente'] as int?) ?? 0),
                        ),
                        _met(
                          label: _l.fiStOverdue,
                          value: _fmtInt((r['totalAtrasado'] as num?) ?? 0),
                          color: context.sem.danger,
                          icon: Icons.warning_amber_rounded,
                          sub: _labelCobrancas((r['qtdAtrasado'] as int?) ?? 0),
                        ),
                        _met(
                          label: _l.raOverdue,
                          value: '${r['alunosInadimplentes'] ?? 0}',
                          color: context.c.onSurface,
                          icon: Icons.groups_rounded,
                        ),
                      ],
                    ),
                  ),
                // ── Busca ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: TextField(
                      controller: _buscaCtrl,
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontSize: 14,
                      ),
                      onChanged: (v) => setState(() => _busca = v),
                      decoration: InputDecoration(
                        hintText: _l.studentsSearchHint,
                        hintStyle: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: context.c.onSurfaceVariant,
                          size: 20,
                        ),
                        suffixIcon: _busca.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: context.c.onSurfaceVariant,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _buscaCtrl.clear();
                                  setState(() => _busca = '');
                                },
                              )
                            : null,
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
                ),
                // ── Tabs de status ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final tab in [
                            ('todos', _l.fiTabAll),
                            ('pendente', _l.fiTabPending),
                            ('atrasado', _l.fiTabOverdue),
                            ('pago', _l.fiTabPaid),
                            ('desconsiderado', _l.fiTabDismissed),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _tabFiltro = tab.$1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _tabFiltro == tab.$1
                                        ? context.c.primary
                                        : context.c.surfaceContainer,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _tabFiltro == tab.$1
                                          ? context.c.primary
                                          : context.c.outline,
                                    ),
                                  ),
                                  child: Text(
                                    tab.$2,
                                    style: TextStyle(
                                      color: _tabFiltro == tab.$1
                                          ? Colors.white
                                          : context.c.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: _tabFiltro == tab.$1
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: Builder(
                      builder: (_) {
                        final lista = _cobrancasFiltradas;
                        return Text(
                          lista.isEmpty
                              ? _l.fiNoCharges
                              : _l.fiChargesCount(lista.length),
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // ── Lista de cobranças ──────────────────────────────────
                Builder(
                  builder: (_) {
                    final lista = _cobrancasFiltradas;
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((_, i) {
                        final c = lista[i];
                        final status = c['status'] as String?;
                        final isDesconsiderado = status == 'Desconsiderado';
                        String? dataStr;
                        final rawVenc =
                            c['dataVencimento'] ?? c['data_vencimento'];
                        if (rawVenc != null) {
                          try {
                            final dt = DateTime.parse(rawVenc.toString());
                            dataStr =
                                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                          } catch (_) {}
                        }
                        final isPago = status == 'Pago';
                        final valorBase = (c['valor'] as num? ?? 0).toDouble();
                        final desconto =
                            (c['desconto'] as num?)?.toDouble() ?? 0.0;
                        final valorPago = (c['valor_pago'] as num?)?.toDouble();
                        // Taxa de atraso (só exibe se pendente/atrasado e taxa ativa)
                        final isOverdue = status == 'Atrasado';
                        double taxaValor = 0.0;
                        if (_taxaAtrasoAtiva && isOverdue) {
                          taxaValor = _taxaAtrasoTipo == 0
                              ? valorBase * _taxaAtrasoValor / 100
                              : _taxaAtrasoValor;
                        }

                        return Opacity(
                          opacity: isDesconsiderado ? 0.5 : 1.0,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            decoration: BoxDecoration(
                              color: context.c.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDesconsiderado
                                    ? context.c.outline
                                    : (!isPago
                                          ? _statusCor(status).withOpacity(0.3)
                                          : context.c.outline),
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c['nomeAluno'] ?? '',
                                              style: TextStyle(
                                                color: context.c.onSurface,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              [
                                                _tipoLabel(
                                                  c['tipo']?.toString(),
                                                ),
                                                if (dataStr != null)
                                                  _l.fiDueOn(dataStr),
                                              ].join(' · '),
                                              style: TextStyle(
                                                color:
                                                    context.c.onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                            // Breakdown (taxa + desconto)
                                            if (taxaValor > 0 ||
                                                desconto > 0) ...[
                                              const SizedBox(height: 6),
                                              if (taxaValor > 0)
                                                Text(
                                                  _l.fiLateFee(
                                                    _fmtVal(taxaValor),
                                                  ),
                                                  style: TextStyle(
                                                    color: context.sem.danger,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              if (desconto > 0)
                                                Text(
                                                  _l.fiDiscount(
                                                    _fmtVal(desconto),
                                                  ),
                                                  style: TextStyle(
                                                    color: context.sem.success,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              if (valorPago != null)
                                                Text(
                                                  _l.fiReceivedAmount(
                                                    _fmtVal(valorPago),
                                                  ),
                                                  style: TextStyle(
                                                    color: context.sem.success,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _fmtVal(valorBase),
                                            style: TextStyle(
                                              color: context.c.onSurface,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              decoration: desconto > 0
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              decorationColor:
                                                  context.c.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            _statusLabel(status),
                                            style: TextStyle(
                                              color: _statusCor(status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Menu "..."
                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert_rounded,
                                          color: context.c.onSurfaceVariant,
                                          size: 18,
                                        ),
                                        color: context.c.surfaceContainer,
                                        padding: EdgeInsets.zero,
                                        itemBuilder: (_) => [
                                          if (isPago)
                                            PopupMenuItem(
                                              value: 'estornar',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.undo_rounded,
                                                    size: 16,
                                                    color: context.sem.danger,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _l.fiRefund,
                                                    style: TextStyle(
                                                      color:
                                                          context.c.onSurface,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (!isPago && !isDesconsiderado)
                                            PopupMenuItem(
                                              value: 'desconsiderar',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.block_rounded,
                                                    size: 16,
                                                    color: context.sem.warning,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _l.fiDismiss,
                                                    style: TextStyle(
                                                      color:
                                                          context.c.onSurface,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (isDesconsiderado)
                                            PopupMenuItem(
                                              value: 'restaurar',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.restore_rounded,
                                                    size: 16,
                                                    color: context.sem.success,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _l.fiRestoreCharge,
                                                    style: TextStyle(
                                                      color:
                                                          context.c.onSurface,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          PopupMenuItem(
                                            value: 'excluir',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 16,
                                                  color: context.sem.danger,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _l.fiDeleteCharge,
                                                  style: TextStyle(
                                                    color: context.sem.danger,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (v) {
                                          if (v == 'estornar') _estornar(c);
                                          if (v == 'desconsiderar')
                                            _desconsiderar(c);
                                          if (v == 'restaurar') _restaurar(c);
                                          if (v == 'excluir')
                                            _excluirCobranca(c);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isPago && !isDesconsiderado)
                                  InkWell(
                                    onTap: () => _marcarPago(c),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.sem.success.withOpacity(
                                          0.08,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline_rounded,
                                            color: context.sem.success,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _l.fiMarkPaid,
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
                        );
                      }, childCount: lista.length),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: AdBannerWidget()),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ], // end else
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.c.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.c.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: context.c.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: context.c.onSurfaceVariant,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  String _labelCobrancas(int n) => _l.raChargesCount(n);

  Widget _met({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    String? sub,
  }) => Container(
    decoration: BoxDecoration(
      color: context.c.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.c.outline),
    ),
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // linha de cima: ícone à esquerda · valor à direita
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // linha de baixo: rótulo à esquerda · nº de cobranças à direita
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sub != null) ...[
              const SizedBox(width: 6),
              Text(
                sub,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ],
    ),
  );
}
