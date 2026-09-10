import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/perfil_switch.dart';
import 'package:tatame/l10n/app_localizations.dart';

void main() {
  testWidgets('troca de perfil usa uma ação textual e acessível', (tester) async {
    var acionado = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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
