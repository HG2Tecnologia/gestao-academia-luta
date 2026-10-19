import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../core/firestore_service.dart';

class AlunoQrCodeSheet extends StatefulWidget {
  const AlunoQrCodeSheet({super.key});

  @override
  State<AlunoQrCodeSheet> createState() => _AlunoQrCodeSheetState();
}

class _AlunoQrCodeSheetState extends State<AlunoQrCodeSheet>
    with SingleTickerProviderStateMixin {
  TabController? _tab;
  bool _checkinManualAtivo = false;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarFlagAcademia();
  }

  Future<void> _carregarFlagAcademia() async {
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user?.academiaId;
      if (academiaId != null && academiaId.isNotEmpty) {
        final academia = await firestoreService.getAcademia(academiaId);
        _checkinManualAtivo = academia?['checkin_manual_ativo'] as bool? ?? false;
      }
    } catch (_) {
      // Sem conseguir confirmar a configuração, mantém o comportamento de
      // hoje (só QR) — nunca libera o check-in manual por engano.
      _checkinManualAtivo = false;
    }
    if (!mounted) return;
    setState(() {
      _tab = TabController(length: _checkinManualAtivo ? 3 : 2, vsync: this);
      _carregando = false;
    });
  }

  @override
  void dispose() {
    _tab?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tab;
    return Container(
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.c.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_carregando || tab == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: context.c.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: tab,
                  indicator: BoxDecoration(
                    color: context.c.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: context.c.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(text: context.l10n.apQrMyCode),
                    Tab(text: context.l10n.apQrScanAcademy),
                    if (_checkinManualAtivo)
                      Tab(text: context.l10n.apQrManualCheckin),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: tab,
                children: [
                  const _MeuQrTab(),
                  const _EscanearTab(),
                  if (_checkinManualAtivo) const _CheckinManualTab(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MeuQrTab extends StatefulWidget {
  const _MeuQrTab();

  @override
  State<_MeuQrTab> createState() => _MeuQrTabState();
}

class _MeuQrTabState extends State<_MeuQrTab> {
  String? _token;
  bool _loading = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
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
      if (user == null) throw Exception('sem usuario');
      // Generate QR data directly from local user — no API call needed
      final token = '${user.academiaId}:${user.id}';
      if (mounted)
        setState(() {
          _token = token;
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.c.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: context.c.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.apQrShowInstructor,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: context.c.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_erro)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: context.sem.danger,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.apQrGenFailed,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: context.c.primary.withOpacity(0.18),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: _token!,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            context.l10n.apQrShowInstructorLong,
            style: TextStyle(
              color: context.c.onSurfaceVariant.withOpacity(0.6),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EscanearTab extends StatefulWidget {
  const _EscanearTab();

  @override
  State<_EscanearTab> createState() => _EscanearTabState();
}

class _EscanearTabState extends State<_EscanearTab> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _processando = false;
  bool? _sucesso;
  String? _mensagem;

  Future<void> _processar(String codigo) async {
    if (_processando) return;
    setState(() {
      _processando = true;
      _sucesso = null;
      _mensagem = null;
    });
    await _ctrl.stop();

    try {
      final user = await AuthStorage.getUser();
      if (user == null) throw Exception('Usuário não autenticado');
      final academiaId = user.academiaId!;
      final now = DateTime.now();
      final dataStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final horaStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      String turmaId = '';
      String horarioId = '';
      if (codigo.startsWith('TURMA:')) {
        turmaId = codigo.substring('TURMA:'.length);
      }

      String? aviso;
      if (turmaId.isNotEmpty) {
        aviso = await firestoreService.avisoLimiteDiasSemana(
          academiaId,
          user.id,
          turmaId,
        );
      }

      await firestoreService.addPresenca(academiaId, {
        'aluno_id': user.id,
        'turma_id': turmaId,
        'horario_id': horarioId,
        'data': dataStr,
        'hora_checkin': horaStr,
        'metodo_checkin': 1,
        'confirmado': true,
        'academia_id': academiaId,
      });

      setState(() {
        _sucesso = true;
        _mensagem = aviso ?? context.l10n.apQrCheckinSuccess;
      });
    } catch (e) {
      setState(() {
        _sucesso = false;
        _mensagem = e is CheckinBloqueadoException
            ? e.mensagem
            : context.l10n.apQrCheckinError;
      });
    }
  }

  Future<void> _reiniciar() async {
    setState(() {
      _processando = false;
      _sucesso = null;
      _mensagem = null;
    });
    await _ctrl.start();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_processando) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_mensagem == null) ...[
              CircularProgressIndicator(color: context.c.primary),
              const SizedBox(height: 16),
              Text(
                context.l10n.apQrCheckingIn,
                style: TextStyle(color: context.c.onSurfaceVariant),
              ),
            ] else ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_sucesso! ? context.sem.success : context.sem.danger)
                      .withOpacity(0.15),
                ),
                child: Icon(
                  _sucesso! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: _sucesso! ? context.sem.success : context.sem.danger,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _mensagem!,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _reiniciar,
                icon: Icon(Icons.qr_code_scanner_rounded),
                label: Text(context.l10n.apQrScanAgain),
                style: FilledButton.styleFrom(
                  backgroundColor: context.c.primary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                MobileScanner(
                  controller: _ctrl,
                  onDetect: (capture) {
                    final code = capture.barcodes.firstOrNull?.rawValue;
                    if (code != null && code.isNotEmpty) _processar(code);
                  },
                ),
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: context.c.primary, width: 2.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.l10n.apQrPointAtAcademy,
            style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _CheckinManualTab extends StatefulWidget {
  const _CheckinManualTab();

  @override
  State<_CheckinManualTab> createState() => _CheckinManualTabState();
}

class _CheckinManualTabState extends State<_CheckinManualTab> {
  bool _carregando = true;
  Map<String, dynamic>? _proxima;
  String? _erroCarregamento;
  Timer? _ticker;

  bool _processando = false;
  bool? _sucesso;
  String? _mensagem;

  @override
  void initState() {
    super.initState();
    _carregarProximaAula();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _carregarProximaAula() async {
    setState(() {
      _carregando = true;
      _erroCarregamento = null;
    });
    try {
      final user = await AuthStorage.getUser();
      if (user == null) throw Exception('sem usuario');
      final proxima = await firestoreService.proximaAulaCheckinManual(
        user.academiaId!,
        user.id,
      );
      if (!mounted) return;
      setState(() {
        _proxima = proxima;
        _carregando = false;
      });
      _agendarAtualizacao();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erroCarregamento = context.l10n.apManualCheckinLoadError;
        _carregando = false;
      });
    }
  }

  /// Enquanto a janela ainda não abriu (ou já tem uma próxima aula
  /// carregada), reavalia periodicamente pra habilitar o botão sozinho
  /// assim que entrar no horário — sem o aluno precisar puxar pra atualizar.
  void _agendarAtualizacao() {
    _ticker?.cancel();
    if (_proxima == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {}); // só reavalia _dentroDaJanela com o relógio atual
    });
  }

  bool get _dentroDaJanela {
    final p = _proxima;
    if (p == null) return false;
    final agora = DateTime.now();
    final disponivelEm = p['disponivelEm'] as DateTime;
    final indisponivelApos = p['indisponivelApos'] as DateTime;
    return !agora.isBefore(disponivelEm) && !agora.isAfter(indisponivelApos);
  }

  Future<void> _confirmar() async {
    final proxima = _proxima;
    if (_processando || proxima == null) return;
    setState(() {
      _processando = true;
      _sucesso = null;
      _mensagem = null;
    });
    _ticker?.cancel();
    try {
      final user = await AuthStorage.getUser();
      if (user == null) throw Exception('Usuário não autenticado');
      final academiaId = user.academiaId!;
      final now = DateTime.now();
      final dataStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final horaStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final turmaId = proxima['turmaId'] as String? ?? '';

      String? aviso;
      if (turmaId.isNotEmpty) {
        aviso = await firestoreService.avisoLimiteDiasSemana(
          academiaId,
          user.id,
          turmaId,
        );
      }

      await firestoreService.addPresenca(academiaId, {
        'aluno_id': user.id,
        'turma_id': turmaId,
        'horario_id': proxima['horarioId'] as String? ?? '',
        'data': dataStr,
        'hora_checkin': horaStr,
        'metodo_checkin': 4,
        'confirmado': true,
        'academia_id': academiaId,
      });

      setState(() {
        _sucesso = true;
        _mensagem = aviso ?? context.l10n.apQrCheckinSuccess;
      });
    } catch (e) {
      setState(() {
        _sucesso = false;
        _mensagem = e is CheckinBloqueadoException
            ? e.mensagem
            : context.l10n.apQrCheckinError;
      });
    }
  }

  void _reiniciar() {
    setState(() {
      _processando = false;
      _sucesso = null;
      _mensagem = null;
    });
    _carregarProximaAula();
  }

  String _fmtHora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _fmtClasseEm(DateTime d) {
    final hoje = DateTime.now();
    final mesmoDia =
        d.year == hoje.year && d.month == hoje.month && d.day == hoje.day;
    if (mesmoDia) return context.l10n.apManualCheckinClassAt(_fmtHora(d));
    return context.l10n.apManualCheckinClassOn(
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
      _fmtHora(d),
    );
  }

  String _fmtDisponivelEm(DateTime d) {
    final hoje = DateTime.now();
    final mesmoDia =
        d.year == hoje.year && d.month == hoje.month && d.day == hoje.day;
    if (mesmoDia) return context.l10n.apManualCheckinAvailableAtToday(_fmtHora(d));
    return context.l10n.apManualCheckinAvailableAt(
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
      _fmtHora(d),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_processando) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_mensagem == null) ...[
              CircularProgressIndicator(color: context.c.primary),
              const SizedBox(height: 16),
              Text(
                context.l10n.apQrCheckingIn,
                style: TextStyle(color: context.c.onSurfaceVariant),
              ),
            ] else ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_sucesso! ? context.sem.success : context.sem.danger)
                      .withOpacity(0.15),
                ),
                child: Icon(
                  _sucesso! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: _sucesso! ? context.sem.success : context.sem.danger,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _mensagem!,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _sucesso!
                    ? () => Navigator.of(context).maybePop()
                    : _reiniciar,
                icon: Icon(
                  _sucesso! ? Icons.check_rounded : Icons.refresh_rounded,
                ),
                label: Text(
                  _sucesso! ? context.l10n.commonClose : context.l10n.commonRetry,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.c.primary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erroCarregamento != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: context.sem.danger, size: 40),
            const SizedBox(height: 12),
            Text(
              _erroCarregamento!,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _carregarProximaAula,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.commonRetry),
              style: OutlinedButton.styleFrom(foregroundColor: context.c.primary),
            ),
          ],
        ),
      );
    }

    final proxima = _proxima;
    if (proxima == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              color: context.c.onSurfaceVariant,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.apManualCheckinNoClassNow,
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _carregarProximaAula,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.commonRetry),
              style: OutlinedButton.styleFrom(foregroundColor: context.c.primary),
            ),
          ],
        ),
      );
    }

    final nomeTurma = (proxima['nomeTurma'] as String?)?.isNotEmpty == true
        ? proxima['nomeTurma'] as String
        : context.l10n.apManualCheckinClassFallback;
    final inicio = proxima['inicio'] as DateTime;
    final disponivel = _dentroDaJanela;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.c.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_martial_arts_rounded,
              color: context.c.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nomeTurma,
            style: TextStyle(
              color: context.c.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _fmtClasseEm(inicio),
            style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (disponivel)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _confirmar,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(context.l10n.apManualCheckinConfirm),
                style: FilledButton.styleFrom(
                  backgroundColor: context.c.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else ...[
            Icon(Icons.lock_clock_rounded, color: context.c.onSurfaceVariant, size: 22),
            const SizedBox(height: 8),
            Text(
              _fmtDisponivelEm(proxima['disponivelEm'] as DateTime),
              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
