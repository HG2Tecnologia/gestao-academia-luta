import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tatame/core/auth_storage.dart';
import 'package:tatame/core/finance_service.dart';
import 'package:tatame/core/firebase_identity_service.dart';
import 'package:tatame/core/firestore_service.dart';
import 'package:tatame/l10n/app_localizations.dart';
import 'package:tatame/screens/admin/aluno_detalhe_screen.dart';

import 'fakes/fake_finance_service.dart';
import 'fakes/fake_firebase_identity_service.dart';
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
    firebaseIdentityService = FirebaseIdentityService();
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

  // Troca de telefone de acesso (`atualizarTelefoneAcessoAluno`) — a tela
  // nunca tinha sido exercitada por nenhum teste antes desta branch. Os 4
  // testes abaixo cobrem os 3 diagnósticos que o servidor pode devolver no
  // modo `verificar`, exatamente como descritos no fluxo de
  // `_editarAluno` em aluno_detalhe_screen.dart.
  group('troca de telefone de acesso', () {
    testWidgets(
      'telefone livre: salva a ficha e move a conta pro número novo, sem aviso',
      (tester) async {
        final fakeIdentity = FakeFirebaseIdentityService(
          verificarStatus: 'livre',
        );
        firebaseIdentityService = fakeIdentity;

        await pump(tester);
        final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

        await tester.tap(find.byTooltip(l10n.commonEdit));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, l10n.sdPhone),
          '11988887777',
        );
        await tester.ensureVisible(find.text(l10n.sdSaveChanges));
        await tester.tap(find.text(l10n.sdSaveChanges));
        await tester.pumpAndSettle();

        // Ficha salva (telefone_digits é o canônico, sem a máscara visual)...
        expect(
          fakeFirestore.updateAlunoCalls.any(
            (c) => c['telefone_digits'] == '5511988887777',
          ),
          isTrue,
        );
        // ...e a conta de acesso foi movida (modo `aplicar`), sem precisar
        // de nenhum diálogo no caminho (número livre).
        expect(
          fakeIdentity.chamadas.map((c) => c.modo),
          containsAllInOrder(['verificar', 'aplicar']),
        );
        // Sucesso normal, não o aviso amarelo de compartilhada/falha.
        expect(find.text(l10n.sdStudentUpdated), findsOneWidget);
      },
    );

    testWidgets(
      'telefone em conflito + "Vincular": liga o aluno à conta existente',
      (tester) async {
        final fakeIdentity = FakeFirebaseIdentityService(
          verificarStatus: 'conflito',
        );
        firebaseIdentityService = fakeIdentity;

        await pump(tester);
        final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

        await tester.tap(find.byTooltip(l10n.commonEdit));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, l10n.sdPhone),
          '11977776666',
        );
        await tester.ensureVisible(find.text(l10n.sdSaveChanges));
        await tester.tap(find.text(l10n.sdSaveChanges));
        await tester.pumpAndSettle();

        // Diálogo de conflito apareceu, nada foi gravado ainda.
        expect(find.text('Telefone já está em uso'), findsOneWidget);
        expect(fakeFirestore.updateAlunoCalls, isEmpty);

        await tester.tap(find.text('Vincular'));
        await tester.pumpAndSettle();

        // Agora sim: ficha salva e conta vinculada (modo `vincular`, nunca
        // `aplicar` — não pode mexer na senha da conta existente).
        expect(
          fakeFirestore.updateAlunoCalls.any(
            (c) => c['telefone_digits'] == '5511977776666',
          ),
          isTrue,
        );
        expect(
          fakeIdentity.chamadas.map((c) => c.modo),
          containsAllInOrder(['verificar', 'vincular']),
        );
        expect(
          fakeIdentity.chamadas.any((c) => c.modo == 'aplicar'),
          isFalse,
        );
        expect(find.text(l10n.sdStudentUpdated), findsOneWidget);
      },
    );

    testWidgets(
      'telefone em conflito + "Corrigir número": cancela, nada é gravado',
      (tester) async {
        final fakeIdentity = FakeFirebaseIdentityService(
          verificarStatus: 'conflito',
        );
        firebaseIdentityService = fakeIdentity;

        await pump(tester);
        final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

        await tester.tap(find.byTooltip(l10n.commonEdit));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, l10n.sdPhone),
          '11977776666',
        );
        await tester.ensureVisible(find.text(l10n.sdSaveChanges));
        await tester.tap(find.text(l10n.sdSaveChanges));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Corrigir número'));
        await tester.pumpAndSettle();

        // Nada foi gravado — nem a ficha, nem a conta de acesso.
        expect(fakeFirestore.updateAlunoCalls, isEmpty);
        expect(
          fakeIdentity.chamadas.where((c) => c.modo != 'verificar'),
          isEmpty,
        );
        // O diálogo fechou e devolveu pro formulário (ainda editando).
        expect(find.text('Telefone já está em uso'), findsNothing);
        expect(find.text(l10n.sdSaveChanges), findsOneWidget);
      },
    );

    testWidgets(
      'telefone com conta compartilhada: salva a ficha, mas avisa que o login não muda',
      (tester) async {
        final fakeIdentity = FakeFirebaseIdentityService(
          verificarStatus: 'compartilhada',
        );
        firebaseIdentityService = fakeIdentity;

        await pump(tester);
        final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

        await tester.tap(find.byTooltip(l10n.commonEdit));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, l10n.sdPhone),
          '11966665555',
        );
        await tester.ensureVisible(find.text(l10n.sdSaveChanges));
        await tester.tap(find.text(l10n.sdSaveChanges));
        await tester.pumpAndSettle();

        // Ficha salva...
        expect(
          fakeFirestore.updateAlunoCalls.any(
            (c) => c['telefone_digits'] == '5511966665555',
          ),
          isTrue,
        );
        // ...mas a conta de acesso nunca é tocada (compartilhada com outro
        // perfil) — só `verificar` foi chamado, nunca `aplicar`/`vincular`.
        expect(
          fakeIdentity.chamadas.where((c) => c.modo != 'verificar'),
          isEmpty,
        );
        // Aviso amarelo específico, não a mensagem de sucesso normal.
        expect(
          find.textContaining('login deste aluno é compartilhado'),
          findsOneWidget,
        );
        expect(find.text(l10n.sdStudentUpdated), findsNothing);
      },
    );
  });
}
