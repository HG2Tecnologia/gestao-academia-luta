import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../notificacoes_screen.dart';
import 'aluno_widgets.dart';

/// Cabeçalho da Home: avatar + saudação + ação de notificações.
class StudentHeader extends StatelessWidget {
  final String primeiroNome;
  final String? fotoBase64;
  final String subtitulo;
  final VoidCallback? onNotificacoes;
  final VoidCallback? onAvatar;
  final Widget? profileSwitcher;

  /// Quando `true`, mostra o sino com contador (`SinoNotificacoes`) em vez do
  /// ícone simples — `onNotificacoes` é ignorado nesse caso (o sino já cuida
  /// da navegação sozinho).
  final bool usarSinoNotificacoes;

  const StudentHeader({
    super.key,
    required this.primeiroNome,
    this.fotoBase64,
    this.subtitulo = '',
    this.onNotificacoes,
    this.onAvatar,
    this.profileSwitcher,
    this.usarSinoNotificacoes = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onAvatar,
          child: _Avatar(fotoBase64: fotoBase64, nome: primeiroNome),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primeiroNome.isEmpty
                    ? context.l10n.apHello
                    : context.l10n.apHelloName(primeiroNome),
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitulo.isEmpty ? context.l10n.apJourneyContinues : subtitulo,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (profileSwitcher != null) ...[
          const SizedBox(width: AppSpacing.xs),
          profileSwitcher!,
        ],
        if (usarSinoNotificacoes)
          const SinoNotificacoes()
        else if (onNotificacoes != null)
          IconButton(
            onPressed: onNotificacoes,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: context.c.surfaceContainer,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
              side: BorderSide(color: context.c.outline),
            ),
            icon: Icon(
              Icons.notifications_none_rounded,
              color: context.c.onSurface,
              size: 20,
            ),
            tooltip: context.l10n.apNotifications,
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? fotoBase64;
  final String nome;
  const _Avatar({this.fotoBase64, required this.nome});

  @override
  Widget build(BuildContext context) {
    final iniciais = nome
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();
    if (fotoBase64 != null && fotoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(fotoBase64!.split(',').last);
        return CircleAvatar(radius: 22, backgroundImage: MemoryImage(bytes));
      } catch (_) {}
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: context.c.primary.withValues(alpha: 0.18),
      child: Text(
        iniciais.isEmpty ? '?' : iniciais,
        style: TextStyle(
          color: context.c.primary,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Card "Próxima aula". Nunca quebra: sem aula mostra estado calmo.
class NextClassCard extends StatelessWidget {
  final String? turmaNome;
  final String? quando; // ex.: "Hoje • 20:00 — 21:30"
  final String? professor;
  final VoidCallback? onTap;

  const NextClassCard({
    super.key,
    this.turmaNome,
    this.quando,
    this.professor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vazio = turmaNome == null || turmaNome!.isEmpty;
    return AlunoCard(
      onTap: vazio ? null : onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.c.primary.withValues(alpha: 0.14),
              borderRadius: AppRadius.brSm,
            ),
            child: Icon(
              vazio ? Icons.event_available_rounded : Icons.event_rounded,
              color: context.c.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vazio ? context.l10n.apNoClassToday : turmaNome!,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!vazio && quando != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    quando!,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (!vazio && professor != null && professor!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.apProfPrefix(professor!),
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!vazio)
            Icon(
              Icons.chevron_right_rounded,
              color: context.c.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

/// Frequência da semana corrente (Seg–Sex), marcando com check os dias em que
/// houve presença registrada.
class WeeklyAttendanceCard extends StatelessWidget {
  final Set<String> diasComPresenca; // 'yyyy-MM-dd'
  final VoidCallback? onTap;

  /// Totais do ano, mostrados nos atalhos "Presenças" / "Faltas".
  final int presencasAno;
  final int faltasAno;

  /// Abre a tela de Presenças já no filtro pedido ('presencas' | 'faltas').
  final void Function(String filtro)? onAbrirDetalhe;

  const WeeklyAttendanceCard({
    super.key,
    required this.diasComPresenca,
    this.presencasAno = 0,
    this.faltasAno = 0,
    this.onTap,
    this.onAbrirDetalhe,
  });

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final hojeData = DateTime(hoje.year, hoje.month, hoje.day);
    final segunda = hojeData.subtract(Duration(days: hoje.weekday - 1));
    final nomes = [
      context.l10n.dowMon,
      context.l10n.dowTue,
      context.l10n.dowWed,
      context.l10n.dowThu,
      context.l10n.dowFri,
    ];
    final dias = List.generate(5, (i) => segunda.add(Duration(days: i)));
    final total = dias.where((d) => diasComPresenca.contains(_key(d))).length;

    return AlunoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.apWeekAttendance,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.apWorkoutsCount(total),
                style: TextStyle(
                  color: context.c.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final d = dias[i];
              final presente = diasComPresenca.contains(_key(d));
              final ehHoje = d == hojeData;
              final futuro = d.isAfter(hojeData);
              return Column(
                children: [
                  Text(
                    nomes[i],
                    style: TextStyle(
                      color: ehHoje
                          ? context.c.onSurface
                          : context.c.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: presente
                          ? context.c.primary
                          : (ehHoje
                                ? context.c.primary.withValues(alpha: 0.08)
                                : context.c.surface),
                      border: Border.all(
                        color: presente
                            ? context.c.primary
                            : (ehHoje
                                  ? context.c.primary.withValues(alpha: 0.4)
                                  : context.c.outline),
                        width: ehHoje ? 1.5 : 1,
                      ),
                    ),
                    child: presente
                        ? Icon(
                            Icons.check_rounded,
                            color: Colors.black,
                            size: 18,
                          )
                        : Center(
                            child: Text(
                              '${d.day}',
                              style: TextStyle(
                                color: futuro
                                    ? context.c.onSurfaceVariant.withValues(
                                        alpha: 0.5,
                                      )
                                    : (ehHoje
                                          ? context.c.primary
                                          : context.c.onSurfaceVariant),
                                fontSize: 11,
                                fontWeight: ehHoje
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                  ),
                ],
              );
            }),
          ),
          if (onAbrirDetalhe != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _AtalhoFrequencia(
                    texto: context.l10n.apAttendancesCount(presencasAno),
                    cor: context.sem.success,
                    onTap: () => onAbrirDetalhe!('presencas'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _AtalhoFrequencia(
                    texto: context.l10n.apAbsencesCount(faltasAno),
                    cor: context.sem.danger,
                    onTap: () => onAbrirDetalhe!('faltas'),
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

class _AtalhoFrequencia extends StatelessWidget {
  final String texto;
  final Color cor;
  final VoidCallback onTap;

  const _AtalhoFrequencia({
    required this.texto,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cor.withValues(alpha: 0.10),
      borderRadius: AppRadius.brSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brSm,
            border: Border.all(color: cor.withValues(alpha: 0.30)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cor, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

enum FinanceiroStatus { emDia, pendente, atrasado, semCobrancas }

/// Status financeiro na Home — linguagem clara, sem constranger.
class FinancialStatusCard extends StatelessWidget {
  final FinanceiroStatus status;
  final VoidCallback? onTap;

  const FinancialStatusCard({super.key, required this.status, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (cor, icone, titulo, sub) = switch (status) {
      FinanceiroStatus.emDia => (
        context.sem.success,
        Icons.verified_rounded,
        context.l10n.apTuitionOk,
        context.l10n.apTuitionOkSub,
      ),
      FinanceiroStatus.pendente => (
        context.sem.warning,
        Icons.schedule_rounded,
        context.l10n.apTuitionPending,
        context.l10n.apTuitionNeedsAttention,
      ),
      FinanceiroStatus.atrasado => (
        context.sem.danger,
        Icons.account_balance_wallet_rounded,
        context.l10n.apTuitionOverdue,
        context.l10n.apTuitionNeedsAttention,
      ),
      FinanceiroStatus.semCobrancas => (
        context.c.onSurfaceVariant,
        Icons.receipt_long_rounded,
        context.l10n.apNoCharges,
        context.l10n.apNoChargesSub,
      ),
    };

    return AlunoCard(
      onTap: onTap,
      borderColor: cor.withValues(alpha: 0.35),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: cor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: cor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.c.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Seletor horizontal de modalidade (multimodalidade). Aparece só quando há
/// mais de uma. Para muitas modalidades vira scroll horizontal.
class ModalitySelector extends StatelessWidget {
  final List<String> modalidades;
  final String selecionada;
  final ValueChanged<String> onSelect;

  const ModalitySelector({
    super.key,
    required this.modalidades,
    required this.selecionada,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (modalidades.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modalidades.length,
        separatorBuilder: (_, i) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) {
          final m = modalidades[i];
          final sel = m == selecionada;
          return GestureDetector(
            onTap: () => onSelect(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: sel ? context.c.primary : context.c.surfaceContainer,
                borderRadius: AppRadius.brSm,
                border: Border.all(
                  color: sel ? context.c.primary : context.c.outline,
                ),
              ),
              child: Text(
                m,
                style: TextStyle(
                  color: sel ? Colors.black : context.c.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
