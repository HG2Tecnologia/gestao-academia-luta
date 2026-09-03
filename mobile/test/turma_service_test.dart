import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/turma_service.dart';

void main() {
  test('estaExcluida é true só quando deleted_at está presente', () {
    expect(TurmaService.estaExcluida({'nome': 'Judo'}), isFalse);
    expect(TurmaService.estaExcluida({'nome': 'Judo', 'deleted_at': null}), isFalse);
    expect(
      TurmaService.estaExcluida({'nome': 'Judo', 'deleted_at': '2026-01-01T00:00:00Z'}),
      isTrue,
    );
  });
}
