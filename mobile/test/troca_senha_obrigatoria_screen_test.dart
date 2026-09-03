import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/screens/auth/troca_senha_obrigatoria_screen.dart';

void main() {
  testWidgets('bloqueia o pop de navegação (PopScope canPop: false)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TrocaSenhaObrigatoriaScreen()),
    );

    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isFalse);
  });

  testWidgets('não tem AppBar nem botão de voltar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TrocaSenhaObrigatoriaScreen()),
    );

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('valida que a confirmação precisa coincidir com a nova senha', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TrocaSenhaObrigatoriaScreen()),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Nova senha'), 'senha123');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirme a nova senha'),
      'outraSenha1',
    );
    await tester.tap(find.text('Salvar e continuar'));
    await tester.pump();

    expect(find.text('As senhas não coincidem'), findsOneWidget);
  });

  testWidgets('valida tamanho mínimo da nova senha', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TrocaSenhaObrigatoriaScreen()),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Nova senha'), '123');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirme a nova senha'),
      '123',
    );
    await tester.tap(find.text('Salvar e continuar'));
    await tester.pump();

    expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
  });
}
