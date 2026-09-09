import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/modalidade_icones.dart';

/// Avatar reutilizável de uma modalidade.
///
/// Aplica a regra única de exibição: imagem personalizada válida → ícone padrão
/// do catálogo → ícone genérico. Nunca deixa espaço quebrado.
class ModalidadeAvatar extends StatelessWidget {
  const ModalidadeAvatar({super.key, required this.modalidade, this.size = 44});

  final Map<String, dynamic> modalidade;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = resolverVisualModalidade(modalidade);
    final nome = (modalidade['nome'] ?? 'Modalidade').toString();
    final radius = size * 0.28;

    Widget conteudo;
    if (visual.tipo == ModalidadeVisualTipo.imagem) {
      conteudo = _imagem(visual, radius);
    } else {
      conteudo = _iconeQuadrado(visual, radius);
    }

    return Semantics(
      label: 'Modalidade $nome',
      image: true,
      excludeSemantics: true,
      child: SizedBox(width: size, height: size, child: conteudo),
    );
  }

  Widget _iconeQuadrado(ModalidadeVisual visual, double radius) {
    return Container(
      decoration: BoxDecoration(
        color: visual.cor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: visual.cor.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Icon(visual.icone.icon, color: visual.cor, size: size * 0.52),
    );
  }

  Widget _imagem(ModalidadeVisual visual, double radius) {
    try {
      final b64 = visual.imagemBase64!.split(',').last;
      final bytes = base64Decode(b64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _iconeQuadrado(visual, radius),
        ),
      );
    } catch (_) {
      return _iconeQuadrado(visual, radius);
    }
  }
}
