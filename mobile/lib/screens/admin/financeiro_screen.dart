import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/ad_banner.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';
import '../../core/tab_refresh.dart';

class AdminFinanceiroScreen extends StatefulWidget {
  const AdminFinanceiroScreen({super.key});

  @override
  State<AdminFinanceiroScreen> createState() => _AdminFinanceiroScreenState();
}

class _AdminFinanceiroScreenState extends State<AdminFinanceiroScreen> {
  Map<String, dynamic>? _resumo;
  List<Map<String, dynamic>> _cobrancas = [];
  bool _loading = true;
  String? _academiaId;

  late int _ano;
  late int _mes;

  static const _meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
  static const _statusMap = {0: 'Pendente', 1: 'Pago', 2: 'Atrasado', 3: 'Previsto'};

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

      final todos = await firestoreService.getPagamentos(_academiaId!);

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

      // Compute resumo client-side
      double recebido = 0, pendente = 0, atrasado = 0;
      final Set<String> inadimplentesSet = {};
      final now = DateTime.now();

      for (final p in todos) {
        final statusRaw = p['status'];
        final statusInt = statusRaw is int ? statusRaw : int.tryParse(statusRaw.toString()) ?? 0;
        final statusStr = _statusMap[statusInt] ?? 'Pendente';
        final valor = (p['valor'] as num? ?? 0).toDouble();
        final venc = p['data_vencimento'] as String? ?? '';
        DateTime? vencDt;
        try { vencDt = DateTime.parse(venc); } catch (_) {}

        if (statusStr == 'Pago') {
          if (vencDt != null && vencDt.year == _ano && vencDt.month == _mes) recebido += valor;
        } else if (statusStr == 'Pendente' || statusStr == 'Previsto') {
          if (vencDt != null && vencDt.year == _ano && vencDt.month == _mes) pendente += valor;
          if (vencDt != null && vencDt.isBefore(now)) {
            atrasado += valor;
            final alunoId = p['aluno_id']?.toString() ?? '';
            if (alunoId.isNotEmpty) inadimplentesSet.add(alunoId);
          }
        }
      }

      // Convert status for display
      final cobrancasComStatus = doMes.map((p) {
        final statusRaw = p['status'];
        final statusInt = statusRaw is int ? statusRaw : int.tryParse(statusRaw.toString()) ?? 0;
        final statusStr = _statusMap[statusInt] ?? 'Pendente';
        final rawNome = (p['nome_aluno'] ?? p['nomeAluno'] ?? p['aluno_nome'] ?? '').toString();
        final rawTipo = p['tipo']?.toString() ?? '';
        return {
          ...p,
          'status': statusStr,
          'nomeAluno': rawNome == 'null' ? '' : rawNome,
          'dataVencimento': p['data_vencimento'] ?? p['dataVencimento'] ?? '',
          'tipo': (rawTipo.isEmpty || rawTipo == 'null') ? 'Mensalidade' : rawTipo,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _resumo = {
            'totalRecebidoMes': recebido,
            'totalPendenteMes': pendente,
            'totalAtrasado': atrasado,
            'alunosInadimplentes': inadimplentesSet.length,
          };
          _cobrancas = cobrancasComStatus.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navMes(int delta) {
    setState(() {
      _mes += delta;
      if (_mes > 12) { _mes = 1; _ano++; }
      if (_mes < 1) { _mes = 12; _ano--; }
    });
    _load();
  }

  static final _brl = NumberFormat('#,##0.00', 'pt_BR');
  static final _brlInt = NumberFormat('#,##0', 'pt_BR');

  String _fmtVal(num v) => 'R\$ ${_brl.format(v)}';
  String _fmtInt(num v) => 'R\$ ${_brlInt.format(v)}';

  Color _statusCor(String? s) {
    if (s == 'Pago') return kSuccess;
    if (s == 'Pendente') return kWarning;
    if (s == 'Previsto') return kText2;
    return kDanger;
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
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
              Row(children: [
                Icon(Icons.add_circle_outline_rounded, color: kPrimary, size: 22),
                const SizedBox(width: 10),
                Text('Nova cobrança', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 20),
              Text('Aluno', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                child: DropdownButton<String>(
                  value: alunoId,
                  isExpanded: true,
                  dropdownColor: kSurface,
                  underline: const SizedBox(),
                  hint: Text('Selecione o aluno', style: TextStyle(color: kText2, fontSize: 13)),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: kText2),
                  items: alunos.map((a) => DropdownMenuItem<String>(
                    value: a['id']?.toString(),
                    child: Text(a['nome']?.toString() ?? '', style: TextStyle(color: kText1, fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setModal(() => alunoId = v),
                ),
              ),
              const SizedBox(height: 14),
              Text('Tipo', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                child: DropdownButton<int>(
                  value: tipo,
                  isExpanded: true,
                  dropdownColor: kSurface,
                  underline: const SizedBox(),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: kText2),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Mensalidade')),
                    DropdownMenuItem(value: 2, child: Text('Taxa de Matrícula')),
                  ],
                  onChanged: (v) => setModal(() => tipo = v ?? 1),
                ),
              ),
              const SizedBox(height: 14),
              Text('Valor (R\$)', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: valorCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: kText1, fontSize: 15),
                decoration: InputDecoration(
                  hintText: '0,00',
                  hintStyle: TextStyle(color: kText2),
                  filled: true,
                  fillColor: kBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                ),
              ),
              const SizedBox(height: 14),
              Text('Vencimento', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: vencimento,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('pt', 'BR'),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(colorScheme: ColorScheme.dark(primary: kPrimary, surface: kSurface, onSurface: kText1)),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => vencimento = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded, color: kText2, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${vencimento.day.toString().padLeft(2,'0')}/${vencimento.month.toString().padLeft(2,'0')}/${vencimento.year}',
                      style: TextStyle(color: kText1, fontSize: 14),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: alunoId == null ? null : () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: kPrimary.withOpacity(0.3),
                ),
                child: const Text('Gerar cobrança', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kText2,
                  side: BorderSide(color: kBorder),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar'),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Informe um valor válido.'),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final dataStr = '${vencimento.year}-${vencimento.month.toString().padLeft(2,'0')}-${vencimento.day.toString().padLeft(2,'0')}';
    // Find aluno name
    final alunoSel = alunos.firstWhere((a) => a['id']?.toString() == alunoId, orElse: () => {});
    final nomeAluno = alunoSel['nome']?.toString() ?? '';
    final tipoStr = tipo == 1 ? 'Mensalidade' : 'Taxa de Matrícula';
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
          backgroundColor: kSurface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (c) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
              Container(width: 52, height: 52,
                  decoration: BoxDecoration(color: kSuccess.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(Icons.check_circle_rounded, color: kSuccess, size: 28)),
              const SizedBox(height: 12),
              Text('Cobrança criada!', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('$nomeAluno · $tipoStr · ${_fmtVal(valor)}',
                  style: TextStyle(color: kText2, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              if (tel.replaceAll(RegExp(r'\D'), '').length >= 10) ...[
                FilledButton.icon(
                  onPressed: () { Navigator.of(c).pop(); _abrirWhatsApp(tel, nomeAluno); },
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                  label: const Text('Cobrar via WhatsApp', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: () => Navigator.of(c).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kText2,
                  side: BorderSide(color: kBorder),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Fechar'),
              ),
            ]),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Erro ao criar cobrança.'),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _abrirWhatsApp(String? telefone, String nome) async {
    if (telefone == null || telefone.isEmpty) return;
    final digits = telefone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return;
    final ddi = digits.startsWith('55') ? digits : '55$digits';
    final msg = Uri.encodeComponent('Olá $nome, ');
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Erro ao carregar dados.'),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!mounted) return;

    final alunosComCobrancaMes = _cobrancas
        .map((c) => c['aluno_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    const statusPriority = {'Atrasado': 3, 'Pendente': 2, 'Previsto': 1, 'Pago': 0};
    final statusMap = <String, String>{};
    final vencMap = <String, DateTime>{};
    final now = DateTime.now();

    for (final p in todosPagamentos) {
      final alunoId = p['aluno_id']?.toString() ?? '';
      if (alunoId.isEmpty) continue;
      final statusRaw = p['status'];
      final statusInt = statusRaw is int ? statusRaw : int.tryParse(statusRaw.toString()) ?? 0;
      final statusStr = _statusMap[statusInt] ?? 'Pendente';
      DateTime? vencDt;
      try { vencDt = DateTime.parse(p['data_vencimento']?.toString() ?? ''); } catch (_) {}

      final prev = statusMap[alunoId];
      if (prev == null || (statusPriority[statusStr] ?? 0) > (statusPriority[prev] ?? 0)) {
        statusMap[alunoId] = statusStr;
      }
      if (vencDt != null) {
        final existing = vencMap[alunoId];
        if (existing == null || vencDt.isBefore(existing)) vencMap[alunoId] = vencDt;
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
          return base.where((a) => !alunosComCobrancaMes.contains(a['id']?.toString() ?? '')).toList();
        case 'atrasados':
          return base.where((a) => statusMap[a['id']?.toString() ?? ''] == 'Atrasado').toList();
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
      {'key': 'gerar', 'label': 'Sem cobrança este mês', 'icon': Icons.add_circle_outline_rounded},
      {'key': 'atrasados', 'label': 'Atrasados', 'icon': Icons.warning_rounded},
      {'key': 'pendentes', 'label': 'Pendentes', 'icon': Icons.schedule_rounded},
      {'key': 'proximo', 'label': 'Venc. em até 7 dias', 'icon': Icons.event_rounded},
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final isGerar = filtro == 'gerar';

          final dragHandle = Center(child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
          ));

          // ── Step 0: escolher modo ─────────────────────
          if (step == 0) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 32),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                dragHandle,
                Row(children: [
                  Icon(Icons.receipt_long_rounded, color: kPrimary, size: 22),
                  const SizedBox(width: 10),
                  Text('Gerar cobranças', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 6),
                Text('Escolha quem deve ser cobrado:', style: TextStyle(color: kText2, fontSize: 13)),
                const SizedBox(height: 16),
                _modeCard(
                  icon: Icons.group_rounded, title: 'Por turma',
                  subtitle: 'Cobrar alunos de uma turma específica',
                  onTap: () => setModal(() { mode = 'turma'; step = 1; }),
                ),
                const SizedBox(height: 10),
                _modeCard(
                  icon: Icons.groups_rounded, title: 'Todos os ativos',
                  subtitle: 'Cobrar todos os alunos ativos da academia',
                  onTap: () => setModal(() { mode = 'todos'; step = 1; }),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(foregroundColor: kText2, side: BorderSide(color: kBorder),
                      minimumSize: const Size.fromHeight(44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Cancelar'),
                ),
              ]),
            );
          }

          // ── Step 1: turma + filtro ───────────────────
          if (step == 1) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 32),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                dragHandle,
                Row(children: [
                  GestureDetector(onTap: () => setModal(() => step = 0), child: Icon(Icons.arrow_back_rounded, color: kText1, size: 20)),
                  const SizedBox(width: 10),
                  Text(mode == 'turma' ? 'Por turma' : 'Todos os ativos',
                      style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 16),
                if (mode == 'turma') ...[
                  Text('Turma', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                    child: DropdownButton<String>(
                      value: turmaId, isExpanded: true, dropdownColor: kSurface, underline: const SizedBox(),
                      hint: Text('Selecione a turma', style: TextStyle(color: kText2, fontSize: 13)),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: kText2),
                      items: turmasList.map((t) => DropdownMenuItem<String>(
                        value: t['id']?.toString(),
                        child: Text(t['nome']?.toString() ?? '', style: TextStyle(color: kText1, fontSize: 13)),
                      )).toList(),
                      onChanged: (v) => setModal(() => turmaId = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('Filtrar por situação', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: filtroOpcoes.map((f) {
                  final sel = filtro == f['key'];
                  return GestureDetector(
                    onTap: () => setModal(() => filtro = f['key'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary : kBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? kPrimary : kBorder),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(f['icon'] as IconData, size: 13, color: sel ? Colors.white : kText2),
                        const SizedBox(width: 5),
                        Text(f['label'] as String, style: TextStyle(
                            color: sel ? Colors.white : kText2, fontSize: 12,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                      ]),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: (mode == 'turma' && turmaId == null) || stepLoading ? null : () async {
                    setModal(() => stepLoading = true);
                    List<Map<String, dynamic>> base = todosAlunos;
                    if (mode == 'turma' && turmaId != null) {
                      try {
                        final matriculas = await firestoreService.getMatriculas(_academiaId!, turmaId: turmaId!, ativasOnly: true);
                        final ids = matriculas.map((m) => m['aluno_id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();
                        base = todosAlunos.where((a) => ids.contains(a['id']?.toString() ?? '')).toList();
                      } catch (_) { base = []; }
                    }
                    final prev = applyFilter(base);
                    setModal(() { previewAlunos = prev; stepLoading = false; step = 2; });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: kPrimary.withOpacity(0.3),
                  ),
                  child: stepLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Ver alunos afetados', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => setModal(() => step = 0),
                  style: OutlinedButton.styleFrom(foregroundColor: kText2, side: BorderSide(color: kBorder),
                      minimumSize: const Size.fromHeight(44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Voltar'),
                ),
              ]),
            );
          }

          // ── Step 2: preview ──────────────────────────
          if (step == 2) {
            final count = previewAlunos.length;
            final actionLabel = isGerar
                ? 'Gerar $count cobrança${count != 1 ? 's' : ''}'
                : 'Cobrar via WhatsApp ($count)';
            return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              dragHandle,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  GestureDetector(onTap: () => setModal(() => step = 1), child: Icon(Icons.arrow_back_rounded, color: kText1, size: 20)),
                  const SizedBox(width: 10),
                  Text('$count aluno${count != 1 ? 's' : ''} afetado${count != 1 ? 's' : ''}',
                      style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(height: 12),
              if (previewAlunos.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Icon(Icons.check_circle_rounded, color: kSuccess, size: 48),
                    const SizedBox(height: 12),
                    Text('Nenhum aluno corresponde a este filtro.',
                        style: TextStyle(color: kText2, fontSize: 14), textAlign: TextAlign.center),
                  ]),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
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
                        child: Row(children: [
                          CircleAvatar(radius: 14, backgroundColor: kPrimary.withOpacity(0.15),
                            child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                                style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700))),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(nome, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600)),
                            if (s != null && !isGerar)
                              Text(s, style: TextStyle(color: _statusCor(s), fontSize: 11)),
                          ])),
                          if (!isGerar && tel.replaceAll(RegExp(r'\D'), '').length >= 10)
                            const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 16),
                        ]),
                      );
                    },
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
                child: Column(children: [
                  if (previewAlunos.isNotEmpty)
                    FilledButton(
                      onPressed: stepLoading ? null : () async {
                        setModal(() => stepLoading = true);
                        try {
                          if (isGerar) {
                            for (final a in previewAlunos) {
                              final id = a['id']?.toString() ?? '';
                              if (id.isEmpty) continue;
                              final valor = (a['valor_mensalidade'] as num? ?? a['valorMensalidade'] as num? ?? 0).toDouble();
                              final dia = a['dia_vencimento'] as int? ?? 10;
                              final dataStr = '$_ano-${_mes.toString().padLeft(2, '0')}-${dia.toString().padLeft(2, '0')}';
                              await firestoreService.addPagamento(_academiaId!, {
                                'aluno_id': id,
                                'nome_aluno': a['nome']?.toString() ?? '',
                                'tipo': 'Mensalidade',
                                'valor': valor,
                                'data_vencimento': dataStr,
                                'status': 0,
                              });
                            }
                            _load();
                          }
                          successAlunos = previewAlunos;
                          setModal(() { stepLoading = false; step = 3; });
                        } catch (_) {
                          setModal(() => stepLoading = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Erro ao processar cobranças.'),
                            backgroundColor: kDanger,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isGerar ? kPrimary : const Color(0xFF25D366),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: stepLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => setModal(() { step = 1; stepLoading = false; }),
                    style: OutlinedButton.styleFrom(foregroundColor: kText2, side: BorderSide(color: kBorder),
                        minimumSize: const Size.fromHeight(44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Voltar'),
                  ),
                ]),
              ),
            ]);
          }

          // ── Step 3: sucesso + WhatsApp ───────────────
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              dragHandle,
              Center(child: Column(children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: (isGerar ? kSuccess : const Color(0xFF25D366)).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: isGerar
                      ? Icon(Icons.check_circle_rounded, color: kSuccess, size: 32)
                      : const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  isGerar
                      ? '${successAlunos.length} cobrança${successAlunos.length != 1 ? 's' : ''} gerada${successAlunos.length != 1 ? 's' : ''}!'
                      : 'Pronto para cobrar via WhatsApp!',
                  style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Toque em cada aluno para abrir o WhatsApp com uma mensagem pronta.',
                  style: TextStyle(color: kText2, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ])),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: hasTel ? const Color(0xFF25D366).withOpacity(0.08) : kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: hasTel ? const Color(0xFF25D366).withOpacity(0.3) : kBorder),
                      ),
                      child: Row(children: [
                        CircleAvatar(radius: 14, backgroundColor: kPrimary.withOpacity(0.15),
                          child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                              style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700))),
                        const SizedBox(width: 10),
                        Expanded(child: Text(nome, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600))),
                        if (hasTel)
                          Icon(Icons.chat_rounded, color: const Color(0xFF25D366), size: 20)
                        else
                          Text('Sem telefone', style: TextStyle(color: kText2, fontSize: 11)),
                      ]),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(backgroundColor: kPrimary,
                    minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Fechar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ]),
          );
        },
      ),
    );
  }

  Future<void> _marcarPago(Map<String, dynamic> c) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20, left: 0),
                decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
            Text('Marcar como pago', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('${c['nomeAluno']} · ${c['tipo']}', style: TextStyle(color: kText2, fontSize: 13)),
            Text(_fmtVal((c['valor'] as num?) ?? 0),
                style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: kSuccess,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirmar pagamento', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: kText2,
                side: BorderSide(color: kBorder),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted || _academiaId == null) return;
    try {
      final now = DateTime.now();
      final dataStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await firestoreService.updatePagamento(_academiaId!, c['id'].toString(), {
        'status': 1,
        'data_pagamento': dataStr,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${c['nomeAluno']} marcado como pago!'),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
        ));
        _load();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Erro ao atualizar pagamento.'),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _resumo;
    final isAtual = DateTime.now().year == _ano && DateTime.now().month == _mes;
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton(
        onPressed: _criarCobrancaAvulsa,
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
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
                              Text('Financeiro', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
                              const Spacer(),
                              GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.push('/admin/financeiro/relatorio'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: kSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bar_chart_rounded, color: kText2, size: 14),
                                      const SizedBox(width: 5),
                                      Text('Relatório', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _abrirModalCobrancas,
                                icon: Icon(Icons.receipt_long_rounded, size: 16, color: kPrimary),
                                label: Text('Gerar cobranças',
                                    style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                style: TextButton.styleFrom(
                                  backgroundColor: kPrimary.withOpacity(0.10),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => _navMes(-1),
                              icon: Icon(Icons.chevron_left, color: kText1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Column(
                              children: [
                                Text(
                                  '${_meses[_mes - 1]} $_ano',
                                  style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                                if (isAtual)
                                  Text('Mês atual', style: TextStyle(color: kPrimary, fontSize: 11)),
                              ],
                            ),
                            IconButton(
                              onPressed: isAtual ? null : () => _navMes(1),
                              icon: Icon(Icons.chevron_right, color: isAtual ? kBorder : kText1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
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
                        childAspectRatio: 1.6,
                        children: [
                          _met('Recebido', _fmtInt((r['totalRecebidoMes'] as num?) ?? 0), kSuccess),
                          _met('Pendente', _fmtInt((r['totalPendenteMes'] as num?) ?? 0), kWarning),
                          _met('Atrasado', _fmtInt((r['totalAtrasado'] as num?) ?? 0), kDanger),
                          _met('Inadimplentes', '${r['alunosInadimplentes'] ?? 0}', kDanger),
                        ],
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Text(
                        _cobrancas.isEmpty ? 'Nenhuma cobrança neste período.' : 'Cobranças · ${_cobrancas.length}',
                        style: TextStyle(color: kText2, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final c = _cobrancas[i];
                        final status = c['status'] as String?;
                        String? dataStr;
                        final rawVenc = c['dataVencimento'] ?? c['data_vencimento'];
                        if (rawVenc != null) {
                          try {
                            final dt = DateTime.parse(rawVenc.toString());
                            dataStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                          } catch (_) {}
                        }
                        final isPago = status == 'Pago';
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: !isPago ? _statusCor(status).withOpacity(0.3) : kBorder),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c['nomeAluno'] ?? '', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
                                          Text(
                                            [c['tipo'], if (dataStr != null) 'Venc. $dataStr'].join(' · '),
                                            style: TextStyle(color: kText2, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _fmtVal((c['valor'] as num?) ?? 0),
                                          style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700),
                                        ),
                                        Text(status ?? '', style: TextStyle(color: _statusCor(status), fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!isPago)
                                InkWell(
                                  onTap: () => _marcarPago(c),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: kSuccess.withOpacity(0.08),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_outline_rounded, color: kSuccess, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Marcar como pago', style: TextStyle(color: kSuccess, fontSize: 13, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                      childCount: _cobrancas.length,
                    ),
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

  Widget _modeCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(subtitle, style: TextStyle(color: kText2, fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: kText2, size: 14),
        ]),
      ),
    );
  }

  Widget _met(String label, String value, Color color) => Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: kText2, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      );
}
