import 'package:flutter/material.dart';

/// Catálogo curado de ícones para representar modalidades.
///
/// O que é persistido no banco é sempre a `key` (string estável controlada pelo
/// Sensei Manager) — nunca o `codePoint` de um [IconData], que pode mudar entre
/// versões do Flutter / Material Icons.
class ModalidadeIcone {
  const ModalidadeIcone({
    required this.key,
    required this.label,
    required this.icon,
    required this.corSugerida,
  });

  final String key;
  final String label;
  final IconData icon;

  /// Cor sugerida (hex `#RRGGBB`) aplicada ao avatar quando a modalidade usa
  /// este ícone e ainda não tem uma cor própria definida.
  final String corSugerida;
}

const String kModalidadeIconeGenerico = 'generic';

/// Ordem do grid no formulário. "generic" vem por último como "Outro".
const List<ModalidadeIcone> kModalidadeIcones = [
  ModalidadeIcone(
    key: 'bjj',
    label: 'Jiu-Jitsu',
    icon: Icons.sports_kabaddi_rounded,
    corSugerida: '#1565C0',
  ),
  ModalidadeIcone(
    key: 'judo',
    label: 'Judô',
    icon: Icons.sports_kabaddi_rounded,
    corSugerida: '#90A4AE',
  ),
  ModalidadeIcone(
    key: 'karate',
    label: 'Karatê',
    icon: Icons.sports_martial_arts_rounded,
    corSugerida: '#F4511E',
  ),
  ModalidadeIcone(
    key: 'taekwondo',
    label: 'Taekwondo',
    icon: Icons.sports_martial_arts_rounded,
    corSugerida: '#1565C0',
  ),
  ModalidadeIcone(
    key: 'boxe',
    label: 'Boxe',
    icon: Icons.sports_mma_rounded,
    corSugerida: '#C62828',
  ),
  ModalidadeIcone(
    key: 'muay_thai',
    label: 'Muay Thai',
    icon: Icons.sports_mma_rounded,
    corSugerida: '#E64A19',
  ),
  ModalidadeIcone(
    key: 'kickboxing',
    label: 'Kickboxing',
    icon: Icons.sports_mma_rounded,
    corSugerida: '#7B1FA2',
  ),
  ModalidadeIcone(
    key: 'mma',
    label: 'MMA',
    icon: Icons.sports_mma_rounded,
    corSugerida: '#B71C1C',
  ),
  ModalidadeIcone(
    key: 'capoeira',
    label: 'Capoeira',
    icon: Icons.sports_gymnastics_rounded,
    corSugerida: '#2E7D32',
  ),
  ModalidadeIcone(
    key: 'wrestling',
    label: 'Wrestling',
    icon: Icons.sports_kabaddi_rounded,
    corSugerida: '#5D4037',
  ),
  ModalidadeIcone(
    key: 'defesa_pessoal',
    label: 'Defesa pessoal',
    icon: Icons.shield_rounded,
    corSugerida: '#455A64',
  ),
  ModalidadeIcone(
    key: 'funcional',
    label: 'Funcional',
    icon: Icons.fitness_center_rounded,
    corSugerida: '#00838F',
  ),
  ModalidadeIcone(
    key: 'fitness',
    label: 'Fitness',
    icon: Icons.directions_run_rounded,
    corSugerida: '#F9A825',
  ),
  ModalidadeIcone(
    key: kModalidadeIconeGenerico,
    label: 'Outro',
    icon: Icons.sports_martial_arts_rounded,
    corSugerida: '#C9A020',
  ),
];

ModalidadeIcone modalidadeIconePorKey(String? key) {
  return kModalidadeIcones.firstWhere(
    (e) => e.key == key,
    orElse: () => kModalidadeIcones.last, // generic
  );
}

/// Converte `#RRGGBB` (ou `RRGGBB`) em [Color]; devolve [fallback] se inválido.
Color parseHexCor(String? hex, {Color fallback = const Color(0xFFC9A020)}) {
  if (hex == null || hex.trim().isEmpty) return fallback;
  try {
    final h = hex.replaceFirst('#', '').trim();
    if (h.length != 6) return fallback;
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return fallback;
  }
}

/// Como uma modalidade deve ser representada visualmente.
enum ModalidadeVisualTipo { imagem, icone }

class ModalidadeVisual {
  const ModalidadeVisual({
    required this.tipo,
    required this.icone,
    required this.cor,
    this.imagemBase64,
  });

  final ModalidadeVisualTipo tipo;
  final ModalidadeIcone icone;
  final Color cor;

  /// Data URI `data:image/...;base64,...` quando [tipo] == imagem.
  final String? imagemBase64;
}

/// Resolve a identidade visual de uma modalidade a partir do documento cru,
/// aplicando os fallbacks (imagem → ícone → genérico) e tolerando documentos
/// antigos sem os campos novos.
ModalidadeVisual resolverVisualModalidade(Map<String, dynamic> m) {
  final tipoRaw = (m['iconeTipo'] ?? 'icone').toString();
  final key = (m['iconeKey'] ?? kModalidadeIconeGenerico).toString();
  final icone = modalidadeIconePorKey(key);
  final imagem = (m['iconeImagem'] as String?)?.trim();
  final temImagem =
      tipoRaw == 'imagem' && imagem != null && imagem.contains(',');

  // Prioridade da cor: iconeCor explícita → cor da modalidade (seed) → sugerida.
  final cor = parseHexCor(
    (m['iconeCor'] as String?) ?? (m['cor'] as String?),
    fallback: parseHexCor(icone.corSugerida),
  );

  return ModalidadeVisual(
    tipo: temImagem ? ModalidadeVisualTipo.imagem : ModalidadeVisualTipo.icone,
    icone: icone,
    cor: cor,
    imagemBase64: temImagem ? imagem : null,
  );
}
