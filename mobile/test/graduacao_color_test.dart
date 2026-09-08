import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/graduacao_color.dart';

void main() {
  group('parseGraduationColor', () {
    test('aceita #RRGGBB', () {
      expect(parseGraduationColor('#8E44AD'), const Color(0xFF8E44AD));
    });

    test('aceita RRGGBB sem #', () {
      expect(parseGraduationColor('8e44ad'), const Color(0xFF8E44AD));
    });

    test('aceita #AARRGGBB preservando alfa', () {
      expect(parseGraduationColor('#80FF0000'), const Color(0x80FF0000));
    });

    test('aceita forma curta #RGB', () {
      expect(parseGraduationColor('#0af'), const Color(0xFF00AAFF));
    });

    test('aceita 0xFFRRGGBB', () {
      expect(parseGraduationColor('0xFF123456'), const Color(0xFF123456));
    });

    test('retorna null para valor nulo', () {
      expect(parseGraduationColor(null), isNull);
    });

    test('retorna null para vazio / "none" / "transparent"', () {
      expect(parseGraduationColor(''), isNull);
      expect(parseGraduationColor('   '), isNull);
      expect(parseGraduationColor('none'), isNull);
      expect(parseGraduationColor('transparent'), isNull);
    });

    test('retorna null (sem lançar) para lixo', () {
      expect(parseGraduationColor('roxo'), isNull);
      expect(parseGraduationColor('#12'), isNull);
      expect(parseGraduationColor('#zzzzzz'), isNull);
    });
  });

  test('readableOn escolhe preto sobre cor clara e branco sobre escura', () {
    expect(readableOn(const Color(0xFFFFFFFF)), Colors.black);
    expect(readableOn(const Color(0xFF000000)), Colors.white);
  });
}
