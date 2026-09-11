import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tatame/core/auth_storage.dart';
import 'package:tatame/core/firestore_service.dart';
import 'package:tatame/l10n/app_localizations.dart';
import 'package:tatame/screens/admin/alunos_screen.dart';

import 'fakes/fake_firestore_service.dart';

/// Cobre o pedido do usuário: adicionar ordenação A-Z / Z-A na listagem de
/// alunos da academia (antes não existia nenhuma ordenação — vinha na ordem
/// que o Firestore devolvia, já alfabética, mas sem opção de inverter).
void main() {
  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.saveUser(
      const StoredUser(
        id: 'admin-1',
        nome: 'Sensei',
        email: 'sensei@teste.com',
        perfil: 'Admin',
        academiaId: 'academia-1',
      ),
    );
    firestoreService = FakeFirestoreService(
      alunos: [
        {'id': 'a1', 'nome': 'Carlos', 'ativo': true},
        {'id': 'a2', 'nome': 'Ana', 'ativo': true},
        {'id': 'a3', 'nome': 'Bruna', 'ativo': true},
      ],
    );

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
        home: const AdminAlunosScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    firestoreService = FirestoreService();
  });

  List<String> nomesNaTela(WidgetTester tester) {
    final finder = find.textContaining(RegExp(r'^(Ana|Bruna|Carlos)$'));
    return tester
        .widgetList<Text>(finder)
        .map((t) => t.data!)
        .toList(growable: false);
  }

  testWidgets('lista vem em ordem A-Z por padrão', (tester) async {
    await pump(tester);
    expect(nomesNaTela(tester), ['Ana', 'Bruna', 'Carlos']);
  });

  testWidgets('botão de ordenação inverte para Z-A e volta pra A-Z', (
    tester,
  ) async {
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

    await tester.tap(find.byTooltip(l10n.sortNameDesc));
    await tester.pumpAndSettle();
    expect(nomesNaTela(tester), ['Carlos', 'Bruna', 'Ana']);

    await tester.tap(find.byTooltip(l10n.sortNameAsc));
    await tester.pumpAndSettle();
    expect(nomesNaTela(tester), ['Ana', 'Bruna', 'Carlos']);
  });

  testWidgets('ordenação também se aplica ao resultado da busca', (
    tester,
  ) async {
    await pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

    await tester.tap(find.byTooltip(l10n.sortNameDesc));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, l10n.studentsSearchHint),
      'a',
    );
    // Busca tem debounce de 300ms.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(nomesNaTela(tester), ['Carlos', 'Bruna', 'Ana']);
  });
}
