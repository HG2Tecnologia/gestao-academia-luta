import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../core/firestore_service.dart';

class ProfPresencaHistoricoScreen extends StatefulWidget {
  const ProfPresencaHistoricoScreen({
    super.key,
    required this.horarioId,
    required this.nomeTurma,
    required this.horario,
  });

  final String horarioId;
  final String nomeTurma;
  final String horario;

  @override
  State<ProfPresencaHistoricoScreen> createState() =>
      _ProfPresencaHistoricoScreenState();
}

class _ProfPresencaHistoricoScreenState
    extends State<ProfPresencaHistoricoScreen> {
  DateTime _data = DateTime.now();
  List<Map<String, dynamic>> _presencas = [];
  bool _loading = false;
  bool _erro = false;
  String? _academiaId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = false;
    });
    final fmt = DateFormat('yyyy-MM-dd');
    try {
      final user = await AuthStorage.getUser();
      if (user == null) throw Exception('sem usuario');
      _academiaId = user.academiaId;
      final list = await firestoreService.getPresencas(
        user.academiaId!,
        horarioId: widget.horarioId,
        dataStr: fmt.format(_data),
      );
      if (mounted)
        setState(() {
          _presencas = list;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _erro = true;
          _loading = false;
        });
    }
  }

  Future<void> _pickData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: context.c.primary,
            surface: context.c.surfaceContainer,
            onSurface: context.c.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _data = picked;
    });
    _load();
  }

  String _metodo(dynamic m) {
    if (m == null) return '';
    final s = m.toString();
    if (s == '2' || s.contains('QR') || s.contains('Qr') || s.contains('qr'))
      return 'QR Code';
    if (s == '1' || s.contains(context.l10n.profManual) || s.contains('manual'))
      return 'Manual';
    return s;
  }

  Future<void> _remover(Map<String, dynamic> presenca) async {
    final id = presenca['id']?.toString() ?? '';
    if (id.isEmpty || _academiaId == null) return;
    final nome = (presenca['nomeAluno'] ?? presenca['aluno_id'] ?? 'este aluno')
        .toString();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          context.l10n.profRemoveAttendance,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          context.l10n.profRemoveAttendanceThisClass(nome),
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              context.l10n.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              context.l10n.commonRemove,
              style: TextStyle(
                color: context.sem.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await firestoreService.deletePresenca(_academiaId!, id);
      if (!mounted) return;
      setState(() => _presencas.removeWhere((p) => p['id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tdAttendanceRemoved),
          backgroundColor: context.sem.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tdAttendanceRemoveError),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmtExib = DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR');

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.nomeTurma,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.horario,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: context.c.surfaceContainer,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: context.c.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fmtExib.format(_data),
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickData,
                  icon: Icon(Icons.edit_calendar_rounded, size: 14),
                  label: Text(context.l10n.profChange),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.c.primary,
                    side: BorderSide(color: context.c.primary.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
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
                          context.l10n.ctLoadError,
                          style: TextStyle(color: context.c.onSurfaceVariant),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: _load,
                          icon: Icon(Icons.refresh_rounded),
                          label: Text(context.l10n.commonRetry),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.c.primary,
                          ),
                        ),
                      ],
                    ),
                  )
                : _presencas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          color: context.c.onSurfaceVariant,
                          size: 52,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.l10n.profNoAttendanceThisClass,
                          style: TextStyle(color: context.c.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.profTapChangeDate,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Row(
                          children: [
                            Text(
                              '${_presencas.length} ${_presencas.length == 1 ? 'presente' : 'presentes'}',
                              style: TextStyle(
                                color: context.c.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: _presencas.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final p = _presencas[i];
                            final hora =
                                ((p['hora_checkin'] ?? p['horaCheckin'] ?? '')
                                        as String)
                                    .padLeft(5, '0')
                                    .substring(0, 5);
                            final metodo = _metodo(
                              p['metodo_checkin'] ?? p['metodoCheckin'],
                            );
                            final confirmado =
                                p['confirmado'] as bool? ?? false;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.c.surfaceContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.c.outline),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: confirmado
                                          ? context.sem.success.withOpacity(
                                              0.12,
                                            )
                                          : context.sem.warning.withOpacity(
                                              0.12,
                                            ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      confirmado
                                          ? Icons.check_circle_rounded
                                          : Icons.schedule_rounded,
                                      color: confirmado
                                          ? context.sem.success
                                          : context.sem.warning,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (p['nomeAluno'] ??
                                                  p['aluno_id'] ??
                                                  '')
                                              .toString(),
                                          style: TextStyle(
                                            color: context.c.onSurface,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 11,
                                              color: context.c.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              hora,
                                              style: TextStyle(
                                                color:
                                                    context.c.onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (metodo.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.phone_iphone_rounded,
                                                size: 11,
                                                color:
                                                    context.c.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                metodo,
                                                style: TextStyle(
                                                  color: context
                                                      .c
                                                      .onSurfaceVariant,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!confirmado)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.sem.warning.withOpacity(
                                          0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        context.l10n.profAbsentPending,
                                        style: TextStyle(
                                          color: context.sem.warning,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    onPressed: () => _remover(p),
                                    tooltip: context.l10n.profRemoveAttendance,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: context.sem.danger,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
