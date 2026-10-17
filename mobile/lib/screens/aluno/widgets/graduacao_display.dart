import 'package:flutter/material.dart';
import '../../../core/graduacao_color.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';

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

  /// Cor individual de cada grau (índice 0 = 1º grau), pro recurso opcional
  /// de "graus coloridos". Vazia = faixa não configurou isso, mantém o
  /// visual de sempre (uma única cor de ponteira).
  final List<String> grauCoresHex;

  const GraduacaoView({
    required this.modalidadeNome,
    required this.graduacaoNome,
    this.corHex,
    this.corBarraHex,
    this.temGraus = false,
    this.grau = 0,
    this.maxGraus = 0,
    this.grauCoresHex = const [],
  });

  factory GraduacaoView.fromMap(Map<String, dynamic> g) {
    int asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    final grauCoresRaw = g['grauCoresFaixa'] ?? g['faixaGrauCores'];
    return GraduacaoView(
      modalidadeNome:
          (g['nomeModalidade'] ?? g['modalidadeNome'] ?? g['modalidade'] ?? '')
              .toString(),
      graduacaoNome: (g['nomeFaixa'] ?? g['faixaNome'] ?? g['graduacao'] ?? '')
          .toString(),
      corHex: (g['corFaixa'] ?? g['faixaCor'] ?? g['cor'])?.toString(),
      corBarraHex: (g['corBarraFaixa'] ?? g['faixaCorBarra'] ?? g['corBarra'])
          ?.toString(),
      temGraus: g['faixaTemGraus'] == true || asInt(g['grau']) > 0,
      grau: asInt(g['grau']),
      maxGraus: asInt(g['faixaMaxGraus']),
      grauCoresHex: grauCoresRaw is List
          ? grauCoresRaw.map((e) => e.toString()).toList()
          : const [],
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
      color: cor != null
          ? Color.lerp(cor, Colors.white, 0.35)
          : context.c.onSurface,
      fontSize: _full ? 22 : 17,
      fontWeight: FontWeight.w900,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (overline != null) ...[
          Text(
            overline!,
            style: TextStyle(
              color: context.c.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (graduacao.modalidadeNome.isNotEmpty) ...[
          Text(
            graduacao.modalidadeNome,
            style: TextStyle(
              color: context.c.onSurfaceVariant,
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
                corBarra:
                    parseGraduationColor(graduacao.corBarraHex) ?? Colors.black,
                grau: graduacao.mostrarGraus ? graduacao.grau : 0,
                maxGraus: graduacao._maxEfetivo,
                grauCores: graduacao.grauCoresHex
                    .map(parseGraduationColor)
                    .toList(),
                height: _full ? 24 : 16,
                width: _full ? 58 : 44,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                graduacao.graduacaoNome.isEmpty
                    ? context.l10n.sdNoGraduation
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

  /// Cor individual de cada marcador (índice 0 = 1º grau). `null`/vazia
  /// mantém o visual de sempre (marcador branco fixo).
  final List<Color?>? grauCores;

  const _BeltVisual({
    required this.cor,
    required this.corBarra,
    required this.grau,
    required this.maxGraus,
    required this.height,
    required this.width,
    this.grauCores,
  });

  @override
  Widget build(BuildContext context) {
    // Faixas sem cor por grau mantêm o limite de 6 marcadores (acima disso
    // só o texto do _GrauLabel é mostrado, pra não quebrar o layout).
    // Faixas COM cor por grau configurada (ex.: sistema de 11-12 graus da
    // IBJJF/CBJJ infantil) precisam desenhar todos os marcadores — é
    // exatamente o caso de uso da feature — então o limite sobe pra 12.
    final temCoresPorGrau = grauCores != null && grauCores!.isNotEmpty;
    final limiteMarcadores = temCoresPorGrau ? 12 : 6;
    final desenharMarcadores = grau > 0 && maxGraus <= limiteMarcadores;
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
            // Ambas as seções (cor lisa + tarja de graus) ocupam a altura
            // total: sem isto a tarja encolhe para a altura dos risquinhos e o
            // lado esquerdo (liso) fica visualmente mais "gordo" que o direito.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: width, color: cor),
              if (desenharMarcadores)
                Container(
                  color: corBarra,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      maxGraus.clamp(1, limiteMarcadores),
                      (i) {
                        final earned = i < grau;
                        final corDoGrau =
                            (grauCores != null && i < grauCores!.length)
                            ? grauCores![i]
                            : null;
                        return Container(
                          width: 3,
                          height: height * 0.65,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: earned
                                ? (corDoGrau ?? Colors.white).withValues(
                                    alpha: corDoGrau != null ? 1.0 : 0.9,
                                  )
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      },
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
        color: context.c.primary.withValues(alpha: 0.15),
        borderRadius: AppRadius.brSm,
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: context.c.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
