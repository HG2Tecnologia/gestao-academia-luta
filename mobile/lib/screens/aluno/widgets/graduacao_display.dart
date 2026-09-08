import 'package:flutter/material.dart';
import '../../../core/graduacao_color.dart';
import '../../../core/theme/app_tokens.dart';

/// Dados mínimos de uma graduação para exibição, extraídos do domínio
/// existente (`Map<String, dynamic>` de `getGraduacoes` /
/// `montarFaixasAtuaisPorAluno`). Não é um novo model de negócio — só um
/// recorte imutável para a camada visual.
@immutable
class GraduacaoView {
  final String modalidadeNome;
  final String graduacaoNome;
  final String? corHex;
  final String? corBarraHex;
  final bool temGraus;
  final int grau;

  /// Máximo de graus da graduação. `0`/`null` = desconhecido — nunca
  /// assumimos 4.
  final int maxGraus;

  const GraduacaoView({
    required this.modalidadeNome,
    required this.graduacaoNome,
    this.corHex,
    this.corBarraHex,
    this.temGraus = false,
    this.grau = 0,
    this.maxGraus = 0,
  });

  factory GraduacaoView.fromMap(Map<String, dynamic> g) {
    int asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return GraduacaoView(
      modalidadeNome:
          (g['nomeModalidade'] ?? g['modalidadeNome'] ?? g['modalidade'] ?? '')
              .toString(),
      graduacaoNome:
          (g['nomeFaixa'] ?? g['faixaNome'] ?? g['graduacao'] ?? '').toString(),
      corHex: (g['corFaixa'] ?? g['faixaCor'] ?? g['cor'])?.toString(),
      corBarraHex:
          (g['corBarraFaixa'] ?? g['faixaCorBarra'] ?? g['corBarra'])?.toString(),
      temGraus: g['faixaTemGraus'] == true || asInt(g['grau']) > 0,
      grau: asInt(g['grau']),
      maxGraus: asInt(g['faixaMaxGraus']),
    );
  }

  bool get temCor => parseGraduationColor(corHex) != null;
  bool get mostrarGraus => temGraus && grau > 0;

  /// Limite efetivo só para desenhar marcadores individuais. O fallback `4`
  /// só é usado quando não há marcadores para mostrar de qualquer forma.
  int get _maxEfetivo => maxGraus > 0 ? maxGraus : (grau > 0 ? grau : 4);
}

enum GraduacaoDisplaySize { compact, full }

/// Representação polimórfica da graduação do aluno.
///
///  * Modalidade **com cor** → bloco colorido da faixa + área de graus.
///  * Modalidade **sem cor** (nível/corda/categoria) → apresentação textual
///    elegante, sem inventar faixa colorida.
///  * **Sem graus** → nenhum espaço reservado para graus.
class GraduacaoDisplay extends StatelessWidget {
  final GraduacaoView graduacao;
  final GraduacaoDisplaySize size;

  /// Rótulo pequeno acima (ex.: "Graduação atual"). `null` esconde.
  final String? overline;

  const GraduacaoDisplay({
    super.key,
    required this.graduacao,
    this.size = GraduacaoDisplaySize.compact,
    this.overline,
  });

  bool get _full => size == GraduacaoDisplaySize.full;

  @override
  Widget build(BuildContext context) {
    final cor = parseGraduationColor(graduacao.corHex);
    final nomeStyle = TextStyle(
      color: cor != null ? Color.lerp(cor, Colors.white, 0.35) : AppColors.textPrimary,
      fontSize: _full ? 22 : 17,
      fontWeight: FontWeight.w900,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (overline != null) ...[
          Text(overline!, style: AppText.sectionLabel),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (graduacao.modalidadeNome.isNotEmpty) ...[
          Text(
            graduacao.modalidadeNome,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: _full ? 13 : 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (cor != null) ...[
              _BeltVisual(
                cor: cor,
                corBarra: parseGraduationColor(graduacao.corBarraHex) ??
                    Colors.black,
                grau: graduacao.mostrarGraus ? graduacao.grau : 0,
                maxGraus: graduacao._maxEfetivo,
                height: _full ? 24 : 16,
                width: _full ? 58 : 44,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                graduacao.graduacaoNome.isEmpty
                    ? 'Sem graduação'
                    : graduacao.graduacaoNome,
                style: nomeStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (graduacao.mostrarGraus) ...[
          const SizedBox(height: AppSpacing.xs),
          _GrauLabel(
            grau: graduacao.grau,
            maxGraus: graduacao.maxGraus,
            cor: cor,
          ),
        ],
      ],
    );
  }
}

/// Bloco da cor da faixa + ponteira com marcadores de grau.
/// Acima de 6 graus os marcadores individuais são omitidos (o número fica no
/// [_GrauLabel]) para não quebrar o layout.
class _BeltVisual extends StatelessWidget {
  final Color cor;
  final Color corBarra;
  final int grau;
  final int maxGraus;
  final double height;
  final double width;

  const _BeltVisual({
    required this.cor,
    required this.corBarra,
    required this.grau,
    required this.maxGraus,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final desenharMarcadores = grau > 0 && maxGraus <= 6;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: width, color: cor),
              if (desenharMarcadores)
                Container(
                  color: corBarra,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      maxGraus.clamp(1, 6),
                      (i) => Container(
                        width: 3,
                        height: height * 0.65,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: i < grau
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrauLabel extends StatelessWidget {
  final int grau;
  final int maxGraus;
  final Color? cor;

  const _GrauLabel({required this.grau, required this.maxGraus, this.cor});

  @override
  Widget build(BuildContext context) {
    final texto = maxGraus > 0 ? '$grauº grau de $maxGraus' : '$grauº grau';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: AppRadius.brSm,
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
