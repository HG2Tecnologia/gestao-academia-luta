import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import 'aluno_widgets.dart';

/// Cabeçalho da Home: avatar + saudação + ação de notificações.
class StudentHeader extends StatelessWidget {
  final String primeiroNome;
  final String? fotoBase64;
  final String subtitulo;
  final VoidCallback? onNotificacoes;
  final VoidCallback? onAvatar;
  final Widget? profileSwitcher;

  const StudentHeader({
    super.key,
    required this.primeiroNome,
    this.fotoBase64,
    this.subtitulo = 'Sua jornada continua aqui.',
    this.onNotificacoes,
    this.onAvatar,
    this.profileSwitcher,
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
                primeiroNome.isEmpty ? 'Olá!' : 'Olá, $primeiroNome!',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitulo,
                style: AppText.caption,
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
        if (onNotificacoes != null)
          IconButton(
            onPressed: onNotificacoes,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.brSm,
              ),
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            tooltip: 'Notificações',
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
      backgroundColor: AppColors.primary.withValues(alpha: 0.18),
      child: Text(
        iniciais.isEmpty ? '?' : iniciais,
        style: const TextStyle(
          color: AppColors.primary,
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
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: AppRadius.brSm,
            ),
            child: Icon(
              vazio ? Icons.event_available_rounded : Icons.event_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vazio ? 'Nenhuma aula programada para hoje.' : turmaNome!,
                  style: AppText.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!vazio && quando != null) ...[
                  const SizedBox(height: 2),
                  Text(quando!, style: AppText.caption),
                ],
                if (!vazio && professor != null && professor!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Prof. ${professor!}', style: AppText.caption),
                ],
              ],
            ),
          ),
          if (!vazio)
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
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

  const WeeklyAttendanceCard({
    super.key,
    required this.diasComPresenca,
    this.onTap,
  });

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final hojeData = DateTime(hoje.year, hoje.month, hoje.day);
    final segunda = hojeData.subtract(Duration(days: hoje.weekday - 1));
    const nomes = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex'];
    final dias = List.generate(5, (i) => segunda.add(Duration(days: i)));
    final total = dias.where((d) => diasComPresenca.contains(_key(d))).length;

    return AlunoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Frequência esta semana', style: AppText.caption),
              const Spacer(),
              Text(
                total == 1 ? '1 treino' : '$total treinos',
                style: const TextStyle(
                  color: AppColors.primary,
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
                      color: ehHoje ? AppColors.textPrimary : AppColors.textSecondary,
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
                          ? AppColors.primary
                          : (ehHoje
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : AppColors.bg),
                      border: Border.all(
                        color: presente
                            ? AppColors.primary
                            : (ehHoje
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.border),
                        width: ehHoje ? 1.5 : 1,
                      ),
                    ),
                    child: presente
                        ? const Icon(Icons.check_rounded,
                            color: Colors.black, size: 18)
                        : Center(
                            child: Text(
                              '${d.day}',
                              style: TextStyle(
                                color: futuro
                                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                                    : (ehHoje
                                        ? AppColors.primary
                                        : AppColors.textSecondary),
                                fontSize: 11,
                                fontWeight:
                                    ehHoje ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                          ),
                  ),
                ],
              );
            }),
          ),
        ],
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
          AppColors.success,
          Icons.verified_rounded,
          'Mensalidade em dia',
          'Sem pendências no momento.',
        ),
      FinanceiroStatus.pendente => (
          AppColors.warning,
          Icons.schedule_rounded,
          'Mensalidade pendente',
          'Há uma mensalidade que precisa de atenção.',
        ),
      FinanceiroStatus.atrasado => (
          AppColors.danger,
          Icons.account_balance_wallet_rounded,
          'Mensalidade em atraso',
          'Há uma mensalidade que precisa de atenção.',
        ),
      FinanceiroStatus.semCobrancas => (
          AppColors.textSecondary,
          Icons.receipt_long_rounded,
          'Nenhuma cobrança',
          'Nada em aberto por aqui.',
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
                Text(sub, style: AppText.caption),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
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
                color: sel ? AppColors.primary : AppColors.surface,
                borderRadius: AppRadius.brSm,
                border: Border.all(
                  color: sel ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                m,
                style: TextStyle(
                  color: sel ? Colors.black : AppColors.textSecondary,
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
