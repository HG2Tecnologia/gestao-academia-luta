import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:tatame/core/iap_service.dart';
import 'package:tatame/core/paywall_modal.dart';
import 'package:tatame/core/plan_catalog.dart';
import 'package:tatame/core/plan_service.dart';
import 'package:tatame/core/theme/app_theme.dart';
import 'package:tatame/l10n/app_localizations.dart';

/// Loja indisponível: a tela usa os preços de reserva.
class _SemLoja extends InAppPurchasePlatform {
  @override
  Future<bool> isAvailable() async => false;
}

Future<void> _abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => mostrarPaywall(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

/// O preço cobrado é um texto composto (valor + "/mês" no mensal).
Finder _preco(String valor) => find.byWidgetPredicate(
  (w) => w is RichText && w.text.toPlainText().startsWith(valor),
);

String _paga(int dias) =>
    DateTime.now().add(Duration(days: dias)).toIso8601String();

void main() {
  setUpAll(() {
    // Fora de Android/iOS o plugin não registra a implementação nativa.
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    InAppPurchase.instance;
    InAppPurchasePlatform.instance = _SemLoja();
    IapService.instance;
    debugDefaultTargetPlatformOverride = null;
  });
  setUp(PlanService.instance.reset);

  testWidgets('no grátis abre no PRO e alterna para o Black Belt', (
    tester,
  ) async {
    await _abrir(tester);

    expect(find.text('Assinar Sensei PRO'), findsOneWidget);
    expect(_preco('R\$149,90'), findsOneWidget);
    expect(find.text('29% OFF'), findsOneWidget);
    expect(find.text('Sistema web'), findsNothing);

    await tester.tap(find.text('Black Belt\napp + web'));
    await tester.pumpAndSettle();

    expect(find.text('Assinar Sensei Black Belt'), findsOneWidget);
    expect(_preco('R\$99,99'), findsOneWidget);
    expect(_preco('R\$229,90'), findsOneWidget);
    expect(_preco('R\$749,90'), findsOneWidget);
    expect(find.text('23% OFF'), findsOneWidget);
    expect(find.text('38% OFF'), findsOneWidget);
    expect(find.text('Sistema web'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assinante PRO abre no Black Belt; o plano atual fica travado', (
    tester,
  ) async {
    PlanService.instance.aplicarDados({
      'plano_tipo': 1,
      'plano_origem': 'loja',
      'plano_expiracao': _paga(30),
      'plano_produto_id': kIapTrimestral,
      'plano_plataforma': 'android',
    });
    await _abrir(tester);

    expect(find.text('Mudar para o Sensei Black Belt'), findsOneWidget);

    await tester.tap(find.text('PRO\nsó app'));
    await tester.pumpAndSettle();

    expect(find.text('SEU PLANO ATUAL'), findsOneWidget);
    final botao = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Este é o seu plano'),
    );
    expect(botao.onPressed, isNull);

    await tester.tap(find.text('Mensal'));
    await tester.pumpAndSettle();
    expect(find.text('Trocar de período'), findsOneWidget);
  });
}
