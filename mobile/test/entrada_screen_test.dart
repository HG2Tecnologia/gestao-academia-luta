import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tatame/screens/auth/entrada_screen.dart';

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const EntradaScreen()),
        GoRoute(
          path: '/login',
          builder: (_, state) {
            final extra = state.extra;
            final contexto = extra is Map ? extra['contexto'] as String? : null;
            return Scaffold(body: Text('login:$contexto'));
          },
        ),
      ],
    );
  }

  testWidgets('mostra os dois cards de entrada (aluno e academia)', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    expect(find.text('Sou Aluno ou Responsável'), findsOneWidget);
    expect(find.text('Sou uma Academia'), findsOneWidget);
  });

  testWidgets('card de aluno navega para /login com contexto aluno', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sou Aluno ou Responsável'));
    await tester.pumpAndSettle();

    expect(find.text('login:aluno'), findsOneWidget);
  });

  testWidgets('card de academia navega para /login com contexto academia', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sou uma Academia'));
    await tester.pumpAndSettle();

    expect(find.text('login:academia'), findsOneWidget);
  });
}
