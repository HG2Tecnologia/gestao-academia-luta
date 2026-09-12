import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/firestore_service.dart';
import '../../core/frequencia_treino.dart';
import '../../core/graduacao_order.dart';
import '../../core/pagamento_status.dart';
import '../../core/perfil_switch.dart';
import '../../core/tab_refresh.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets.dart';
import 'aluno_qrcode_sheet.dart';
import 'widgets/aluno_widgets.dart';
import 'widgets/belt_icon.dart';
import 'widgets/home_cards.dart';
import 'widgets/pesei.dart';

/// Home (Início) da área do aluno — foco na jornada: graduação, próxima aula,
/// frequência, financeiro e notícias, sem poluição administrativa.
class AlunoHomeScreen extends StatefulWidget {
  const AlunoHomeScreen({super.key});

  @override
  State<AlunoHomeScreen> createState() => _AlunoHomeScreenState();
}

class _AlunoHomeScreenState extends State<AlunoHomeScreen> {
  bool _loading = true;
  bool _erro = false;

  Map<String, dynamic>? _aluno;
  List<Map<String, dynamic>> _perfis = [];
  Map<String, Map<String, dynamic>> _faixasPorModalidade = {};
  String? _modalidadeSelecionada;
  ({String turma, String quando, String professor})? _proximaAula;
  Set<String> _presencaDias = {};
  int _presencasAno = 0;
  int _faltasAno = 0;
  FinanceiroStatus _financeiro = FinanceiroStatus.semCobrancas;
  List<Map<String, dynamic>> _noticias = [];

  @override
  void initState() {
    super.initState();
    alunoTabNotifier.addListener(_onTab);
    perfilTrocadoNotifier.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    alunoTabNotifier.removeListener(_onTab);
    perfilTrocadoNotifier.removeListener(_load);
    super.dispose();
  }

  void _onTab() {
    if (alunoTabNotifier.value == 0) _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _erro = false);
    try {
      final user = await AuthStorage.getUser();
      if (user == null || user.academiaId == null) {
        if (mounted)
          setState(() {
            _erro = true;
            _loading = false;
          });
        return;
      }
      final academiaId = user.academiaId!;

      final results = await Future.wait([
        firestoreService.getAluno(academiaId, user.id),
        firestoreService
            .getGraduacoes(academiaId, alunoId: user.id, detalhadas: true)
            .catchError((_) => <Map<String, dynamic>>[]),
        firestoreService
            .getMeusHorarios(academiaId, user.id)
            .catchError((_) => <Map<String, dynamic>>[]),
        firestoreService
            .getMatriculas(academiaId, alunoId: user.id, ativasOnly: true)
            .catchError((_) => <Map<String, dynamic>>[]),
        firestoreService
            .getTurmas(academiaId)
            .catchError((_) => <Map<String, dynamic>>[]),
        firestoreService
            .getPresencas(academiaId, alunoId: user.id)
            .catchError((_) => <Map<String, dynamic>>[]),
        firestoreService
            .getPagamentos(academiaId, alunoId: user.id)
            .catchError((_) => <Map<String, dynamic>>[]),
        firestoreService
            .getNoticias(academiaId)
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final aluno = results[0] as Map<String, dynamic>?;
      final graduacoes = (results[1] as List).cast<Map<String, dynamic>>();
      final horarios = (results[2] as List).cast<Map<String, dynamic>>();
      final matriculas = (results[3] as List).cast<Map<String, dynamic>>();
      final turmas = (results[4] as List).cast<Map<String, dynamic>>();
      final presencas = (results[5] as List).cast<Map<String, dynamic>>();
      final pagamentos = (results[6] as List).cast<Map<String, dynamic>>();
      final noticias = (results[7] as List).cast<Map<String, dynamic>>();

      final faixasPorId =
          montarFaixasAtuaisPorAluno(graduacoes)[user.id] ?? const {};
      // Reindexa pelo NOME da modalidade para exibição (a chave original pode
      // ser um id cru). Nome ausente cai no id.
      final faixas = <String, Map<String, dynamic>>{};
      faixasPorId.forEach((id, dados) {
        final nome = (dados['modalidadeNome'] ?? '').toString().trim();
        faixas[nome.isEmpty ? id : nome] = dados;
      });
      final turmaNome = {
        for (final t in turmas)
          t['id'].toString(): (t['nome'] ?? '').toString(),
      };

      if (!mounted) return;
      setState(() {
        _aluno = aluno;
        _perfis = user.perfis;
        _faixasPorModalidade = Map<String, Map<String, dynamic>>.from(faixas);
        _modalidadeSelecionada = _faixasPorModalidade.keys.isEmpty
            ? null
            : (_faixasPorModalidade.containsKey(_modalidadeSelecionada)
                  ? _modalidadeSelecionada
                  : _faixasPorModalidade.keys.first);
        _proximaAula = _calcularProximaAula(horarios, turmaNome, context.l10n);
        _presencaDias = _diasComPresenca(presencas);
        final freq = calcularFrequencia(
          presencas: presencas,
          matriculas: matriculas,
          horarios: horarios,
        );
        _presencasAno = freq.totalPresencas;
        _faltasAno = freq.totalFaltas;
        _financeiro = _statusFinanceiro(pagamentos);
        _noticias = noticias.take(2).toList();
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

  ({String turma, String quando, String professor})? _calcularProximaAula(
    List<Map<String, dynamic>> horarios,
    Map<String, String> turmaNome,
    AppLocalizations l,
  ) {
    final now = DateTime.now();
    final hojeFs = now.weekday % 7; // 0=Dom .. 6=Sáb
    final agoraMin = now.hour * 60 + now.minute;

    int? melhorDelta;
    Map<String, dynamic>? melhor;
    int melhorInicioMin = 0;

    for (final h in horarios) {
      final diaRaw = h['dia_semana'] ?? h['diaSemana'];
      int dia;
      if (diaRaw is num) {
        dia = diaRaw.toInt();
      } else {
        const nomes = [
          'domingo',
          'segunda',
          'terça',
          'quarta',
          'quinta',
          'sexta',
          'sábado',
        ];
        dia = nomes.indexOf((diaRaw ?? '').toString().toLowerCase());
      }
      if (dia < 0 || dia > 6) continue;

      final inicio = ((h['hora_inicio'] ?? h['horaInicio']) ?? '').toString();
      final partes = inicio.split(':');
      final inicioMin = partes.length >= 2
          ? (int.tryParse(partes[0]) ?? 0) * 60 + (int.tryParse(partes[1]) ?? 0)
          : 0;

      var delta = (dia - hojeFs + 7) % 7;
      if (delta == 0 && inicioMin <= agoraMin) delta = 7;

      if (melhorDelta == null ||
          delta < melhorDelta ||
          (delta == melhorDelta && inicioMin < melhorInicioMin)) {
        melhorDelta = delta;
        melhor = h;
        melhorInicioMin = inicioMin;
      }
    }

    if (melhor == null || melhorDelta == null) return null;

    String fmt(String? t) =>
        (t != null && t.length >= 5) ? t.substring(0, 5) : (t ?? '');
    final ini = fmt(
      (melhor['hora_inicio'] ?? melhor['horaInicio'])?.toString(),
    );
    final fim = fmt((melhor['hora_fim'] ?? melhor['horaFim'])?.toString());
    final diasCurtos = [
      l.dowSun,
      l.dowMon,
      l.dowTue,
      l.dowWed,
      l.dowThu,
      l.dowFri,
      l.dowSat,
    ];
    final diaLabel = melhorDelta == 0
        ? l.tdToday
        : melhorDelta == 1
        ? l.commonTomorrow
        : diasCurtos[(hojeFs + melhorDelta) % 7];
    final quando = fim.isEmpty ? '$diaLabel • $ini' : '$diaLabel • $ini — $fim';
    final turmaId = (melhor['turma_id'] ?? '').toString();

    return (
      turma: turmaNome[turmaId] ?? l.apClassFallback,
      quando: quando,
      professor: (melhor['nomeProfessor'] ?? melhor['nome_professor'] ?? '')
          .toString(),
    );
  }

  Set<String> _diasComPresenca(List<Map<String, dynamic>> presencas) {
    final set = <String>{};
    for (final p in presencas) {
      final raw = (p['data'] ?? '').toString();
      if (raw.length >= 10) set.add(raw.substring(0, 10));
    }
    return set;
  }

  // Mesma regra do financeiro do aluno (aluno_financeiro_screen.dart): uma
  // pendência de mês FUTURO (cobrança já gerada com antecedência) não é uma
  // pendência ATUAL — não deve acender o alerta na Home. Só conta pendência
  // (ou atraso) do mês corrente ou anterior.
  FinanceiroStatus _statusFinanceiro(List<Map<String, dynamic>> pagamentos) {
    if (pagamentos.isEmpty) return FinanceiroStatus.semCobrancas;
    final now = DateTime.now();
    final mesRefHoje =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    var temPendente = false;
    for (final p in pagamentos) {
      final status = pagamentoStatusEfetivo(
        rawStatus: p['status'],
        dataVencimento: p['data_vencimento'] ?? p['dataVencimento'],
      );
      if (!pagamentoEhPendenciaAberta(status)) continue;
      if (status == PagamentoStatus.atrasado) return FinanceiroStatus.atrasado;
      if (pagamentoMesReferencia(p).compareTo(mesRefHoje) <= 0) {
        temPendente = true;
      }
    }
    return temPendente ? FinanceiroStatus.pendente : FinanceiroStatus.emDia;
  }

  Widget? _profileSwitcher() {
    if (_perfis.length < 2) return null;
    return Material(
      color: context.c.surfaceContainer,
      borderRadius: AppRadius.brSm,
      child: InkWell(
        borderRadius: AppRadius.brSm,
        onTap: () async {
          await mostrarTrocarPerfil(context);
          _load();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brSm,
            border: Border.all(color: context.c.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.switch_account_rounded,
                size: 16,
                color: context.c.primary,
              ),
              SizedBox(width: 5),
              Text(
                context.l10n.apSwitchShort,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.c.surface,
        body: Center(
          child: CircularProgressIndicator(color: context.c.primary),
        ),
      );
    }
    if (_erro && _aluno == null) {
      return Scaffold(
        backgroundColor: context.c.surface,
        body: SafeArea(
          child: ErroConexao(
            onRetry: () {
              setState(() => _loading = true);
              _load();
            },
          ),
        ),
      );
    }

    final nome = (_aluno?['nome'] ?? '').toString();
    final primeiro = nome.split(' ').first;
    final foto = _aluno?['fotoBase64'] as String?;
    final graduacaoAtual = _modalidadeSelecionada == null
        ? null
        : _faixasPorModalidade[_modalidadeSelecionada];

    return Scaffold(
      backgroundColor: context.c.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.c.primary,
        child: SafeArea(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.lg,
              AppSpacing.screenH,
              AppSpacing.xxl,
            ),
            children: [
              StudentHeader(
                primeiroNome: primeiro,
                fotoBase64: foto,
                profileSwitcher: _profileSwitcher(),
                onNotificacoes: () => context.push('/noticias'),
                onAvatar: () => context.go('/aluno/perfil'),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Graduação ──────────────────────────────
              _graduacaoCard(graduacaoAtual),
              const SizedBox(height: AppSpacing.md),

              // ── Aviso de mensalidade (só quando precisa de atenção) ──
              if (_financeiro == FinanceiroStatus.atrasado ||
                  _financeiro == FinanceiroStatus.pendente) ...[
                FinancialStatusCard(
                  status: _financeiro,
                  onTap: () => context.go('/aluno/financeiro'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Atalhos 2x2 ────────────────────────────
              _atalhoRow(
                StudentQuickActionCard(
                  icon: Icons.calendar_month_rounded,
                  label: context.l10n.apMyLessons,
                  onTap: () => context.go('/aluno/horarios'),
                ),
                StudentQuickActionCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: context.l10n.apMyAttendance,
                  onTap: () => context.push('/aluno/presencas'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _atalhoRow(
                StudentQuickActionCard(
                  icon: Icons.workspace_premium_outlined,
                  iconBuilder: (c) => BeltIcon(size: 22, color: c),
                  label: context.l10n.apMyPromotions,
                  onTap: () => context.go('/aluno/graduacoes'),
                ),
                StudentQuickActionCard(
                  icon: Icons.qr_code_rounded,
                  label: context.l10n.apAttendanceQr,
                  onTap: _abrirQr,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              SectionHeader(
                context.l10n.apNextClass,
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              ),
              NextClassCard(
                turmaNome: _proximaAula?.turma,
                quando: _proximaAula?.quando,
                professor: _proximaAula?.professor,
                onTap: () => context.go('/aluno/horarios'),
              ),
              const SizedBox(height: AppSpacing.md),

              WeeklyAttendanceCard(
                diasComPresenca: _presencaDias,
                presencasAno: _presencasAno,
                faltasAno: _faltasAno,
                onTap: () => context.push('/aluno/presencas'),
                onAbrirDetalhe: (filtro) =>
                    context.push('/aluno/presencas?filtro=$filtro'),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Mensalidade em dia (discreto, fora do topo) ──
              if (_financeiro == FinanceiroStatus.emDia) ...[
                FinancialStatusCard(
                  status: _financeiro,
                  onTap: () => context.go('/aluno/financeiro'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── PESEI (entre a jornada e as notícias) ──
              const PeseiCard(),
              const SizedBox(height: AppSpacing.lg),

              if (_noticias.isNotEmpty) ...[
                SectionHeader(
                  context.l10n.menuNews,
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  trailing: GestureDetector(
                    onTap: () => context.push('/noticias'),
                    child: Text(
                      context.l10n.commonSeeAll,
                      style: TextStyle(
                        color: context.c.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                ..._noticias.map(_noticiaPreview),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _atalhoRow(Widget a, Widget b) => SizedBox(
    height: 116,
    child: Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: b),
      ],
    ),
  );

  Widget _graduacaoCard(Map<String, dynamic>? graduacao) {
    if (graduacao == null) {
      return AlunoCard(
        onTap: () => context.go('/aluno/graduacoes'),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.c.primary.withValues(alpha: 0.14),
                borderRadius: AppRadius.brSm,
              ),
              child: const BeltIcon(size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.apCurrentGrad,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    context.l10n.apJourneyStarts,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final view = GraduacaoView.fromMap(graduacao);
    return AlunoCard(
      onTap: () => context.go('/aluno/graduacoes'),
      gradient: LinearGradient(
        colors: [
          context.c.surfaceContainer,
          context.c.surfaceContainer.withValues(alpha: 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_faixasPorModalidade.length > 1) ...[
            ModalitySelector(
              modalidades: _faixasPorModalidade.keys.toList(),
              selecionada: _modalidadeSelecionada ?? '',
              onSelect: (m) => setState(() => _modalidadeSelecionada = m),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          GraduacaoDisplay(
            graduacao: view,
            size: GraduacaoDisplaySize.full,
            overline: context.l10n.apCurrentGrad,
          ),
        ],
      ),
    );
  }

  Widget _noticiaPreview(Map<String, dynamic> n) {
    final titulo = (n['titulo'] ?? '').toString();
    final resumo = (n['resumo'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AlunoCard(
        onTap: () => context.push('/noticias'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (resumo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                resumo,
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
    );
  }

  void _abrirQr() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AlunoQrCodeSheet(),
    );
  }
}
