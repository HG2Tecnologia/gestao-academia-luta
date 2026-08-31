import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/perfil_switch.dart';

void main() {
  testWidgets('troca de perfil usa uma ação textual e acessível', (tester) async {
    var acionado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PerfilSwitchButton(
            onPressed: () => acionado = true,
          ),
        ),
      ),
    );

    expect(find.text('Trocar perfil'), findsOneWidget);
    expect(find.byIcon(Icons.switch_account_rounded), findsOneWidget);

    await tester.tap(find.text('Trocar perfil'));
    expect(acionado, isTrue);
  });
}
