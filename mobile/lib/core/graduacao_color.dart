import 'package:flutter/material.dart';

/// Converte uma cor de graduação persistida (como vem do cadastro da
/// academia) em [Color], de forma segura.
///
/// Aceita:
///  * `#RRGGBB`  / `RRGGBB`
///  * `#AARRGGBB` / `AARRGGBB`
///  * `#RGB` (forma curta) / `RGB`
///  * `0xFFRRGGBB`
///
/// Retorna `null` quando o valor é nulo, vazio, `"none"`/`"transparent"` ou
/// inválido — assim a UI decide o fallback (faixa neutra ou modo textual)
/// em vez de estourar. NUNCA lança exceção.
Color? parseGraduationColor(String? value) {
  if (value == null) return null;
  var hex = value.trim().toLowerCase();
  if (hex.isEmpty) return null;
  if (hex == 'none' || hex == 'transparent' || hex == 'null') return null;

  if (hex.startsWith('0x')) hex = hex.substring(2);
  hex = hex.replaceFirst('#', '');

  // Forma curta #RGB -> #RRGGBB
  if (hex.length == 3 && RegExp(r'^[0-9a-f]{3}$').hasMatch(hex)) {
    hex = hex.split('').map((c) => '$c$c').join();
  }

  if (hex.length == 6) hex = 'ff$hex';
  if (hex.length != 8) return null;
  if (!RegExp(r'^[0-9a-f]{8}$').hasMatch(hex)) return null;

  final intValue = int.tryParse(hex, radix: 16);
  if (intValue == null) return null;
  return Color(intValue);
}

/// Cor de texto legível (preto ou branco) sobre [background], via luminância
/// relativa. Garante contraste acessível em cima de qualquer cor de faixa.
Color readableOn(Color background) {
  return background.computeLuminance() > 0.55 ? Colors.black : Colors.white;
}
