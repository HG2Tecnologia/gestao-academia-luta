import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tatame/core/auth_storage.dart';
import 'package:tatame/core/finance_service.dart';
import 'package:tatame/core/firestore_service.dart';
import 'package:tatame/l10n/app_localizations.dart';
import 'package:tatame/screens/admin/aluno_detalhe_screen.dart';

import 'fakes/fake_finance_service.dart';
import 'fakes/fake_firestore_service.dart';

/// Regressão do bug real relatado em produção: definir o plano de um aluno
/// pela primeira vez gerava a mensalidade do mês por DOIS caminhos diferentes
/// — um no cadastro do aluno (ID aleatório) e outro no Financeiro/automático
/// diário (ID determinístico) — e como não se reconheciam, geravam DOIS
/// documentos de cobrança pro mesmo aluno/mês.
///
/// A correção unificou os dois caminhos na mesma função idempotente
/// (`financeService.ensureChargesForPeriod`). Este teste prova que salvar o
/// plano pela primeira vez chama esse caminho exatamente UMA vez, para a
/// competência de hoje — nunca duplicado, nunca por um caminho paralelo.
void main() {
  late FakeFirestoreService fakeFirestore;
  late FakeFinanceService fakeFinance;

  String periodoDeHoje() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> pump(
    WidgetTester tester, {
    Map<String, dynamic> alunoOverrides = const {},
  }) async {
    // Tela + modal de edição são compridos (vários campos + seção de plano)
    // — o viewport padrão do flutter_test (800x600) deixa botão/opções fora
    // da área visível e os taps caem fora do hit test. Viewport realista de
    // celular, bem alto, evita isso sem mudar o comportamento testado.
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    fakeFirestore = FakeFirestoreService(
      alunos: [
        {
          'id': 'aluno-1',
          'nome': 'Fernanda',
          'ativo': true,
          // Já tem acesso ao app — evita o fluxo de provisionar senha
          // temporária (fora do escopo deste teste) depois de salvar.
          'firebaseUid': 'uid-existente',
          'telefone': '11999999999',
          'email': 'fernanda@teste.com',
          // SEM plano_id por padrão: é exatamente o cenário do bug — plano
          // definido pela primeira vez. Testes que precisam de um aluno já
          // com plano passam `alunoOverrides`.
          ...alunoOverrides,
        },
      ],
      planos: [
        {'id': 'plano-1', 'nome': 'Mensal', 'valor_mensal': 150},
      ],
    );
    firestoreService = fakeFirestore;
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
        home: const AdminAlunoDetalheScreen(alunoId: 'aluno-1'),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    firestoreService = FirestoreService();
    financeService = FinanceService();
  });

  testWidgets(
    'definir o plano pela 1ª vez gera a mensalidade só UMA vez (sem duplicar)',
    (tester) async {
      await pump(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

      // Abre o modal de edição.
      await tester.tap(find.byTooltip(l10n.commonEdit));
      await tester.pumpAndSettle();

      // Seleciona o plano (ainda sem plano: mostra o placeholder).
      await tester.ensureVisible(find.text(l10n.sdSelectPlanPlaceholder));
      await tester.tap(find.text(l10n.sdSelectPlanPlaceholder));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mensal'));
      await tester.pumpAndSettle();

      // Define o dia de vencimento.
      await tester.ensureVisible(
        find.widgetWithText(TextField, l10n.sdDueDayField),
      );
      await tester.enterText(
        find.widgetWithText(TextField, l10n.sdDueDayField),
        '10',
      );

      // Salva.
      await tester.ensureVisible(find.text(l10n.sdSaveChanges));
      await tester.tap(find.text(l10n.sdSaveChanges));
      await tester.pumpAndSettle();

      // O plano foi persistido...
      expect(
        fakeFirestore.updateAlunoCalls.any(
          (c) => c['plano_id'] == 'plano-1' && c['dia_vencimento'] == 10,
        ),
        isTrue,
        reason: 'updateAluno deveria ter recebido o novo plano e dia de vencimento',
      );

      // ...e a mensalidade foi garantida exatamente UMA vez, pelo caminho
      // idempotente único, para a competência de hoje. Se algum dia
      // reaparecer um segundo caminho de geração (o bug original), esta
      // lista teria mais de uma entrada ou uma competência diferente.
      expect(fakeFinance.ensureChargesForPeriodCalls, [periodoDeHoje()]);
    },
  );

  testWidgets(
    'editar aluno que já tinha plano NÃO gera mensalidade de novo',
    (tester) async {
      await pump(
        tester,
        alunoOverrides: {
          'plano_id': 'plano-1',
          'plano_nome': 'Mensal',
          'dia_vencimento': 10,
        },
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

      await tester.tap(find.byTooltip(l10n.commonEdit));
      await tester.pumpAndSettle();

      // Só troca o telefone — o plano já estava definido antes.
      await tester.enterText(
        find.widgetWithText(TextField, l10n.sdPhone),
        '11988887777',
      );
      await tester.ensureVisible(find.text(l10n.sdSaveChanges));
      await tester.tap(find.text(l10n.sdSaveChanges));
      await tester.pumpAndSettle();

      expect(fakeFinance.ensureChargesForPeriodCalls, isEmpty);
    },
  );
}
