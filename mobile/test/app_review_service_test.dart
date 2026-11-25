import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/app_review_service.dart';

void main() {
  final agora = DateTime(2026, 12, 1);
  bool avalia({
    int dias = 20,
    int aberturas = 6,
    int tentativas = 0,
    int? diasDesdeUltimo,
    bool concluido = false,
  }) => AppReviewService.deveSolicitar(
    agora: agora,
    primeiraAbertura: agora.subtract(Duration(days: dias)),
    aberturas: aberturas,
    tentativas: tentativas,
    ultimoPedido: diasDesdeUltimo == null
        ? null
        : agora.subtract(Duration(days: diasDesdeUltimo)),
    concluido: concluido,
  );

  test('pede quando cumpre os critérios', () => expect(avalia(), isTrue));
  test('não pede cedo demais', () => expect(avalia(dias: 5), isFalse));
  test('não pede com poucas aberturas', () => expect(avalia(aberturas: 2), isFalse));
  test('não pede se já concluiu', () => expect(avalia(concluido: true), isFalse));
  test('respeita o intervalo', () {
    expect(avalia(tentativas: 1, diasDesdeUltimo: 10), isFalse);
    expect(avalia(tentativas: 1, diasDesdeUltimo: 31), isTrue);
  });
  test('limita a 3 tentativas', () => expect(avalia(tentativas: 3, diasDesdeUltimo: 60), isFalse));
}
