import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tatame/core/auth_storage.dart';
import 'package:tatame/core/finance_service.dart';
import 'package:tatame/core/firestore_service.dart';
import 'package:tatame/l10n/app_localizations.dart';
import 'package:tatame/screens/admin/financeiro_screen.dart';

import 'fakes/fake_finance_service.dart';
import 'fakes/fake_firestore_service.dart';

/// Regressão do bug real relatado em produção: a tela de Financeiro da
/// academia chamava a Cloud Function `ensureChargesForPeriod` (que gera
/// mensalidade Pendente para TODO aluno ativo com plano) usando o mês que
/// estava sendo NAVEGADO na tela, em vez do mês real de hoje. Bastava o
/// admin rolar o histórico pra trás para gerar cobrança retroativa para
/// todos os alunos, mesmo os que nem estavam matriculados naquela época.
///
/// Estes testes montam a tela com um [FakeFinanceService] que só grava as
/// chamadas (nunca bate na Cloud Function de verdade) e provam que, não
/// importa para onde o admin navegue, a geração automática nunca é chamada
/// para outra competência que não seja a de hoje.
void main() {
  late FakeFinanceService fakeFinance;

  String periodoDeHoje() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

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
    firestoreService = FakeFirestoreService(pagamentos: const [], academia: const {});
    fakeFinance = FakeFinanceService();
    financeService = fakeFinance;

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
        home: const AdminFinanceiroScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    // Nunca deixar os fakes vazando para outro arquivo de teste.
    firestoreService = FirestoreService();
    financeService = FinanceService();
  });

  testWidgets(
    'ao abrir a tela, garante mensalidade só da competência de hoje',
    (tester) async {
      await pump(tester);

      expect(fakeFinance.ensureChargesForPeriodCalls, [periodoDeHoje()]);
    },
  );

  testWidgets(
    'navegar para meses passados NUNCA dispara geração para o mês navegado',
    (tester) async {
      await pump(tester);
      final hoje = periodoDeHoje();

      // Volta 3 meses no histórico — cenário exato do bug relatado (admin
      // rolando o histórico pra trás e gerando cobrança retroativa).
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();
      }

      // Toda chamada feita (uma por _load) tem que ser sempre a de hoje —
      // nunca um mês passado, mesmo com a tela mostrando outro mês.
      expect(fakeFinance.ensureChargesForPeriodCalls, isNotEmpty);
      expect(
        fakeFinance.ensureChargesForPeriodCalls.toSet(),
        {hoje},
        reason:
            'nenhuma chamada deveria pedir competência diferente da de hoje',
      );
    },
  );

  testWidgets(
    'navegar para meses futuros também nunca dispara geração fora do mês de hoje',
    (tester) async {
      await pump(tester);
      final hoje = periodoDeHoje();

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();
      }

      expect(fakeFinance.ensureChargesForPeriodCalls.toSet(), {hoje});
    },
  );

  testWidgets(
    'menu "Mais" → "Corrigir duplicadas" chama a função certa após dupla confirmação',
    (tester) async {
      await pump(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

      await tester.tap(find.byTooltip(l10n.fiMoreActions));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.fiMergeDuplicates));
      await tester.pumpAndSettle();

      // Duas confirmações antes de executar — nenhuma chamada ainda.
      expect(fakeFinance.mergeDuplicateChargesCalls, isEmpty);
      await tester.tap(find.text(l10n.fiMergeDuplicatesButton));
      await tester.pumpAndSettle();
      expect(fakeFinance.mergeDuplicateChargesCalls, isEmpty);
      await tester.tap(find.text(l10n.fiMergeDuplicatesButton));
      await tester.pumpAndSettle();

      expect(fakeFinance.mergeDuplicateChargesCalls, ['academia-1']);
    },
  );
}
