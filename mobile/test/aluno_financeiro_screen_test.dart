import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tatame/core/auth_storage.dart';
import 'package:tatame/core/firestore_service.dart';
import 'package:tatame/l10n/app_localizations.dart';
import 'package:tatame/screens/aluno/aluno_financeiro_screen.dart';

import 'fakes/fake_firestore_service.dart';

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Dataset fixo por teste, sempre relativo a "agora" — nunca uma data
/// hardcoded que fica velha com o tempo.
class _Fixture {
  final DateTime now;
  late final String hoje = _iso(now);
  late final String mesPassado = _iso(DateTime(now.year, now.month - 1, 20));
  late final String doisMesesAtras = _iso(DateTime(now.year, now.month - 2, 10));

  _Fixture(this.now);

  Map<String, dynamic> _doc({
    required String id,
    required int status,
    required String venc,
    required String plano,
    num valor = 150,
  }) => {
    'id': id,
    'aluno_id': 'aluno-1',
    'status': status,
    'data_vencimento': venc,
    'plano_nome': plano,
    'valor': valor,
  };

  /// Desconsiderada (há 2 meses, venceria atrasada se não fosse desconsiderada).
  Map<String, dynamic> get desconsiderada =>
      _doc(id: 'p1', status: 4, venc: doisMesesAtras, plano: 'PlanoDesc');

  /// Atrasada de verdade (mês passado, nunca paga).
  Map<String, dynamic> get atrasada =>
      _doc(id: 'p2', status: 0, venc: mesPassado, plano: 'PlanoAtrasada');

  /// Paga, mesmo mês da atrasada.
  Map<String, dynamic> get paga =>
      _doc(id: 'p3', status: 1, venc: mesPassado, plano: 'PlanoPaga');

  /// Pendente do mês atual (vence hoje: ainda não é atraso).
  Map<String, dynamic> get pendenteAtual =>
      _doc(id: 'p4', status: 0, venc: hoje, plano: 'PlanoAtual');

  List<Map<String, dynamic>> get todas =>
      [desconsiderada, atrasada, paga, pendenteAtual];
}

Future<void> _pump(WidgetTester tester, List<Map<String, dynamic>> docs) async {
  // Largura de celular real (não o padrão 800x600 do flutter_test) — pega
  // overflow horizontal que só apareceria num aparelho de verdade. Altura
  // generosa de propósito: os testes fazem asserção em itens de uma lista
  // rolável sem simular scroll, então evitamos que fiquem fora da área
  // construída/cacheada do Sliver.
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  await AuthStorage.saveUser(
    const StoredUser(
      id: 'aluno-1',
      nome: 'Fernanda',
      email: 'fernanda@teste.com',
      perfil: 'Aluno',
      academiaId: 'academia-1',
    ),
  );
  firestoreService = FakeFirestoreService(pagamentos: docs);

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
      home: const AlunoFinanceiroScreen(),
    ),
  );
  // 1º pump: mostra o loading. Espera a Future de _load() resolver.
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    // Nunca deixar o fake vazando para outro arquivo de teste.
    firestoreService = FirestoreService();
  });

  testWidgets(
    'Desconsiderada não conta como pendência nem aparece como Atrasada',
    (tester) async {
      final f = _Fixture(DateTime.now());
      await _pump(tester, f.todas);

      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

      // Só 1 atrasada (a de verdade) — a desconsiderada não entra na contagem.
      expect(find.text(l10n.apOverdueCount(1)), findsOneWidget);
      expect(find.text(l10n.apOverdueCount(2)), findsNothing);
      // 1 pendente (a do mês atual).
      expect(find.text(l10n.apPendingCount(1)), findsOneWidget);

      // Abrir "ver todas as atrasadas": só a atrasada de verdade aparece.
      await tester.tap(find.text(l10n.apViewAllOverdue));
      await tester.pumpAndSettle();
      expect(find.text('PlanoAtrasada'), findsOneWidget);
      expect(find.text('PlanoDesc'), findsNothing);
      expect(find.text(l10n.apOverdueCount(1)), findsWidgets);
    },
  );

  testWidgets('mês atual mostra só as cobranças daquele mês', (tester) async {
    final f = _Fixture(DateTime.now());
    await _pump(tester, f.todas);

    // A pendente do mês atual aparece; as de meses passados, não.
    expect(find.text('PlanoAtual'), findsOneWidget);
    expect(find.text('PlanoAtrasada'), findsNothing);
    expect(find.text('PlanoPaga'), findsNothing);
    expect(find.text('PlanoDesc'), findsNothing);
  });

  testWidgets(
    '"Voltar ao mês atual" só aparece fora do mês atual, e funciona',
    (tester) async {
      final f = _Fixture(DateTime.now());
      await _pump(tester, f.todas);

      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

      // No mês atual, o botão não existe.
      expect(find.text(l10n.fiBackToCurrentMonth), findsNothing);

      // Voltar 1 mês: aparece o botão e a cobrança do mês passado.
      await tester.tap(find.byTooltip(l10n.apPrevMonth));
      await tester.pumpAndSettle();
      expect(find.text(l10n.fiBackToCurrentMonth), findsOneWidget);
      expect(find.text('PlanoAtrasada'), findsOneWidget);
      expect(find.text('PlanoAtual'), findsNothing);

      // Tocar o botão: volta pro mês atual, botão some de novo.
      await tester.tap(find.text(l10n.fiBackToCurrentMonth));
      await tester.pumpAndSettle();
      expect(find.text(l10n.fiBackToCurrentMonth), findsNothing);
      expect(find.text('PlanoAtual'), findsOneWidget);
    },
  );

  testWidgets('filtro "Pago" mostra só as pagas do mês selecionado', (
    tester,
  ) async {
    final f = _Fixture(DateTime.now());
    await _pump(tester, f.todas);

    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

    // Ir pro mês passado (onde há uma atrasada e uma paga).
    await tester.tap(find.byTooltip(l10n.apPrevMonth));
    await tester.pumpAndSettle();
    expect(find.text('PlanoAtrasada'), findsOneWidget);
    expect(find.text('PlanoPaga'), findsOneWidget);

    // A fileira de chips rola horizontalmente — garante que "Pagos" está
    // visível antes de tocar (senão o tap acerta fora da tela).
    await tester.ensureVisible(find.text(l10n.fiTabPaid));
    await tester.tap(find.text(l10n.fiTabPaid));
    await tester.pumpAndSettle();
    expect(find.text('PlanoPaga'), findsOneWidget);
    expect(find.text('PlanoAtrasada'), findsNothing);

    await tester.ensureVisible(find.text(l10n.fiTabOverdue));
    await tester.tap(find.text(l10n.fiTabOverdue));
    await tester.pumpAndSettle();
    expect(find.text('PlanoAtrasada'), findsOneWidget);
    expect(find.text('PlanoPaga'), findsNothing);
  });

  testWidgets('mês sem nenhuma cobrança mostra o estado vazio', (
    tester,
  ) async {
    final f = _Fixture(DateTime.now());
    await _pump(tester, f.todas);

    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

    // Avança 6 meses — nenhum doc de teste cai lá.
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byTooltip(l10n.apNextMonth));
    }
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhuma cobrança em'), findsOneWidget);
  });

  testWidgets('sem nenhuma pendência, o card fica "em dia" e some o botão', (
    tester,
  ) async {
    final f = _Fixture(DateTime.now());
    await _pump(tester, [f.paga]);

    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

    expect(find.text(l10n.apAllPaid), findsOneWidget);
    expect(find.text(l10n.apViewAllOverdue), findsNothing);
  });
}
