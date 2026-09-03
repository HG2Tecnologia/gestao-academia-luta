import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/phone_normalizer.dart';

void main() {
  final cases =
      (jsonDecode(
                File(
                  '../test-fixtures/domain/phone_normalization_cases.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();

  for (final testCase in cases) {
    test(testCase['name'] as String, () {
      expect(
        PhoneNormalizer.canonicalize(testCase['input'] as String?),
        testCase['expected'],
      );
    });
  }

  test('digits remove apenas o sinal do valor canônico', () {
    expect(PhoneNormalizer.digits('(21) 99999-9999'), '5521999999999');
  });
}
