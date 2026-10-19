import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tatame/core/auth_storage.dart';
import 'package:tatame/core/firestore_service.dart';
import 'package:tatame/l10n/app_localizations.dart';
import 'package:tatame/screens/notificacoes_screen.dart';

import 'fakes/fake_firestore_service.dart';

/// Cobre o pedido do usuário: sino de notificação com contador, mostrando
/// eventos pessoais do aluno (cobrança gerada, graduação) separados do feed
/// da academia (conta vencida etc.) — e navegação ao tocar numa notificação.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required StoredUser user,
    required Widget home,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.saveUser(user);

    final router = GoRouter(
      initialLocation: '/inicio',
      routes: [
        GoRoute(path: '/inicio', builder: (_, __) => home),
        GoRoute(
          path: '/admin/alunos/:id',
          builder: (_, state) =>
              Scaffold(body: Text('ficha-${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/aluno/financeiro',
          builder: (_, __) => const Scaffold(body: Text('tela-financeiro')),
        ),
        GoRoute(
          path: '/aluno/graduacoes',
          builder: (_, __) => const Scaffold(body: Text('tela-graduacoes')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    firestoreService = FirestoreService();
  });

  const admin = StoredUser(
    id: 'admin-1',
    nome: 'Sensei',
    email: 'sensei@teste.com',
    perfil: 'Admin',
    academiaId: 'academia-1',
  );
  const aluno = StoredUser(
    id: 'aluno-1',
    nome: 'Carlos',
    email: 'carlos@teste.com',
    perfil: 'Aluno',
    academiaId: 'academia-1',
  );

  group('SinoNotificacoes', () {
    testWidgets('conta só o feed da academia quando logado como staff', (
      tester,
    ) async {
      firestoreService = FakeFirestoreService(
        notificacoes: [
          {'id': 'n1', 'tipo': 'alerta', 'lida': false},
          {'id': 'n2', 'tipo': 'solicitacao_senha', 'lida': false},
          // Pessoal de outro aluno — NÃO deveria contar pro staff nem pro aluno.
          {
            'id': 'n3',
            'tipo': 'cobranca_gerada',
            'aluno_id': 'outro-aluno',
            'lida': false,
          },
        ],
      );
      await pump(
        tester,
        user: admin,
        home: const Scaffold(body: SinoNotificacoes()),
      );

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('conta só os eventos pessoais quando logado como aluno', (
      tester,
    ) async {
      firestoreService = FakeFirestoreService(
        notificacoes: [
          {'id': 'n1', 'tipo': 'alerta', 'lida': false}, // feed da academia
          {
            'id': 'n2',
            'tipo': 'cobranca_gerada',
            'aluno_id': 'aluno-1',
            'lida': false,
          },
          {
            'id': 'n3',
            'tipo': 'graduacao',
            'aluno_id': 'aluno-1',
            'lida': true,
          },
          {
            'id': 'n4',
            'tipo': 'cobranca_gerada',
            'aluno_id': 'outro-aluno',
            'lida': false,
          },
        ],
      );
      await pump(
        tester,
        user: aluno,
        home: const Scaffold(body: SinoNotificacoes()),
      );

      // Só 'n2' é pessoal do aluno-1 E não lida.
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('sem notificação não lida, não mostra o badge', (tester) async {
      firestoreService = FakeFirestoreService(
        notificacoes: [
          {
            'id': 'n1',
            'tipo': 'graduacao',
            'aluno_id': 'aluno-1',
            'lida': true,
          },
        ],
      );
      await pump(
        tester,
        user: aluno,
        home: const Scaffold(body: SinoNotificacoes()),
      );

      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsNothing);
    });
  });

  group('NotificacoesScreen', () {
    testWidgets(
      'tocar numa "solicitacao_senha" marca como lida e abre a ficha do aluno',
      (tester) async {
        firestoreService = FakeFirestoreService(
          notificacoes: [
            {
              'id': 'n1',
              'tipo': 'solicitacao_senha',
              'titulo': 'Solicitação de nova senha',
              'mensagem': 'Carlos pediu para redefinir a senha.',
              'usuario_id': 'aluno-99',
              'lida': false,
            },
          ],
        );
        await pump(tester, user: admin, home: const NotificacoesScreen());

        await tester.tap(find.text('Solicitação de nova senha'));
        await tester.pumpAndSettle();

        expect(
          (firestoreService as FakeFirestoreService).marcarNotificacaoLidaCalls,
          ['n1'],
        );
        expect(find.text('ficha-aluno-99'), findsOneWidget);
      },
    );

    testWidgets('tocar numa "cobranca_gerada" abre o financeiro do aluno', (
      tester,
    ) async {
      firestoreService = FakeFirestoreService(
        notificacoes: [
          {
            'id': 'n1',
            'tipo': 'cobranca_gerada',
            'titulo': 'Nova mensalidade gerada',
            'mensagem': 'Sua mensalidade de outubro/2026 já está disponível.',
            'aluno_id': 'aluno-1',
            'lida': false,
          },
        ],
      );
      await pump(tester, user: aluno, home: const NotificacoesScreen());

      await tester.tap(find.text('Nova mensalidade gerada'));
      await tester.pumpAndSettle();

      expect(find.text('tela-financeiro'), findsOneWidget);
    });

    testWidgets(
      'notificação de tipo antigo (alerta) só marca como lida, sem navegar',
      (tester) async {
        firestoreService = FakeFirestoreService(
          notificacoes: [
            {
              'id': 'n1',
              'tipo': 'alerta',
              'titulo': 'Conta da academia vencida',
              'mensagem': 'Água - vencimento 2026-09-01',
              'lida': false,
            },
          ],
        );
        await pump(tester, user: admin, home: const NotificacoesScreen());

        await tester.tap(find.text('Conta da academia vencida'));
        await tester.pumpAndSettle();

        expect(
          (firestoreService as FakeFirestoreService).marcarNotificacaoLidaCalls,
          ['n1'],
        );
        // Continua na própria tela de notificações — nenhuma navegação nova.
        expect(find.text('Conta da academia vencida'), findsOneWidget);
      },
    );
  });
}
