import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/firestore_service.dart';
import '../../core/frequencia_treino.dart';
import '../../core/graduacao_order.dart';
import '../../core/perfil_switch.dart';
import '../../core/tab_refresh.dart';
import '../../core/theme/app_tokens.dart';
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

  static const _diasCurtos = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

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
        _proximaAula = _calcularProximaAula(horarios, turmaNome);
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
    final diaLabel = melhorDelta == 0
        ? 'Hoje'
        : melhorDelta == 1
        ? 'Amanhã'
        : _diasCurtos[(hojeFs + melhorDelta) % 7];
    final quando = fim.isEmpty ? '$diaLabel • $ini' : '$diaLabel • $ini — $fim';
    final turmaId = (melhor['turma_id'] ?? '').toString();

    return (
      turma: turmaNome[turmaId] ?? 'Aula',
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

  FinanceiroStatus _statusFinanceiro(List<Map<String, dynamic>> pagamentos) {
    if (pagamentos.isEmpty) return FinanceiroStatus.semCobrancas;
    var temPendente = false;
    for (final p in pagamentos) {
      final raw = p['status'];
      final s = raw is int ? raw : int.tryParse('$raw') ?? 0;
      if (s == 2) return FinanceiroStatus.atrasado; // 2 = Atrasado
      if (s == 0) temPendente = true; // 0 = Pendente
    }
    return temPendente ? FinanceiroStatus.pendente : FinanceiroStatus.emDia;
  }

  Widget? _profileSwitcher() {
    if (_perfis.length < 2) return null;
    return Material(
      color: AppColors.surface,
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
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.switch_account_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 5),
              Text(
                'Trocar',
                style: TextStyle(
                  color: AppColors.primary,
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
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_erro && _aluno == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
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
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
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
                  label: 'Minhas aulas',
                  onTap: () => context.go('/aluno/horarios'),
                ),
                StudentQuickActionCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Minha frequência',
                  onTap: () => context.push('/aluno/presencas'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _atalhoRow(
                StudentQuickActionCard(
                  icon: Icons.workspace_premium_outlined,
                  iconBuilder: (c) => BeltIcon(size: 22, color: c),
                  label: 'Minhas graduações',
                  onTap: () => context.go('/aluno/graduacoes'),
                ),
                StudentQuickActionCard(
                  icon: Icons.qr_code_rounded,
                  label: 'QR de presença',
                  onTap: _abrirQr,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              SectionHeader(
                'Próxima aula',
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
                  'Notícias',
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  trailing: GestureDetector(
                    onTap: () => context.push('/noticias'),
                    child: const Text(
                      'Ver todas',
                      style: TextStyle(
                        color: AppColors.primary,
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
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: AppRadius.brSm,
              ),
              child: const BeltIcon(size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Graduação atual', style: AppText.sectionLabel),
                  SizedBox(height: 2),
                  Text('Sua trajetória começa aqui.', style: AppText.bodyMuted),
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
        colors: [AppColors.surface, AppColors.surface.withValues(alpha: 0.6)],
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
            overline: 'Graduação atual',
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
              style: AppText.cardTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (resumo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                resumo,
                style: AppText.caption,
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
