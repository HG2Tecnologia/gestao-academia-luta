import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tatame/screens/auth/login_screen.dart';

void main() {
  GoRouter buildRouter(String initialLocation) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, state) {
            final extra = state.extra;
            final contexto = extra is Map ? extra['contexto'] as String? : null;
            return LoginScreen(contexto: contexto);
          },
        ),
        GoRoute(
          path: '/boas-vindas',
          builder: (_, __) => const Scaffold(body: Text('boas-vindas')),
        ),
      ],
    );
  }

  testWidgets(
    'contexto aluno esconde a ação empresarial "Criar uma academia"',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/login',
            routes: [
              GoRoute(
                path: '/login',
                builder: (_, __) => const LoginScreen(contexto: 'aluno'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Criar uma academia'), findsNothing);
      expect(find.text('Acessando o app pela primeira vez'), findsOneWidget);
      expect(find.text('Esqueci minha senha'), findsOneWidget);
    },
  );

  testWidgets(
    'contexto academia mostra a ação renomeada "Criar uma academia"',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/login',
            routes: [
              GoRoute(
                path: '/login',
                builder: (_, __) => const LoginScreen(contexto: 'academia'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Criar uma academia'), findsOneWidget);
      expect(find.text('Criar conta'), findsNothing);
    },
  );

  testWidgets('sem contexto (acesso direto/legado) redireciona para /boas-vindas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: buildRouter('/login')),
    );
    await tester.pumpAndSettle();

    expect(find.text('boas-vindas'), findsOneWidget);
  });
}
