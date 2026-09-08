import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/screens/aluno/widgets/belt_icon.dart';

void main() {
  testWidgets('BeltIcon renderiza sem exceção e respeita o tamanho', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: BeltIcon(size: 40, color: Colors.amber)),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(BeltIcon));
    expect(size, const Size(40, 40));
  });

  testWidgets('BeltIcon herda tamanho do IconTheme quando não informado',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: IconTheme(
              data: IconThemeData(size: 28, color: Colors.white),
              child: BeltIcon(),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(BeltIcon)), const Size(28, 28));
  });
}
