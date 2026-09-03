import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/billing_period.dart';

void main() {
  test('competência possui formato estável e navegação mensal', () {
    final september = BillingPeriod.parse('2026-09');
    expect(september.value, '2026-09');
    expect(september.addMonths(1), const BillingPeriod(2026, 10));
    expect(september.addMonths(-10), const BillingPeriod(2025, 11));
  });

  test('vencimento respeita o último dia do mês', () {
    expect(const BillingPeriod(2027, 2).dueDate(31), DateTime(2027, 2, 28));
  });

  test('id mensal é determinístico por aluno e competência', () {
    final first = monthlyChargeDocumentId(
      studentId: 'student-a',
      period: const BillingPeriod(2026, 9),
    );
    final second = monthlyChargeDocumentId(
      studentId: 'student-a',
      period: BillingPeriod.parse('2026-09'),
    );
    expect(first, second);
    expect(first, 'mensalidade__student-a__2026-09');
  });

  final cases =
      (jsonDecode(
                File(
                  '../test-fixtures/domain/billing_cases.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();

  for (final testCase in cases) {
    test(testCase['name'] as String, () {
      final status = resolveChargeStatus(
        dueDate: DateTime.parse(testCase['dueDate'] as String),
        today: DateTime.parse(testCase['today'] as String),
        paid: testCase['paid'] as bool,
        disregarded: testCase['disregarded'] as bool,
      );
      expect(status.name, testCase['expected']);
    });
  }
}
