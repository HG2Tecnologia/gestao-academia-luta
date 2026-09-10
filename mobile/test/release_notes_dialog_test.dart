import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tatame/core/release_notes.dart';
import 'package:tatame/core/theme/app_theme.dart';
import 'package:tatame/core/whats_new_service.dart';
import 'package:tatame/l10n/app_localizations.dart';

Future<void> _openDialog(
  WidgetTester tester, {
  required Locale locale,
  required Brightness brightness,
  required ReleaseViewer viewer,
}) async {
  tester.view.physicalSize = const Size(1400, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () =>
                  WhatsNewService.showManually(context, viewer: viewer),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Sensei Manager',
      packageName: 'com.example.tatame',
      version: '1.3.0',
      buildNumber: '20',
      buildSignature: '',
    );
  });

  group('dados', () {
    test('1.3.0 existe e filtra por audiência', () {
      final notes = releaseNotesFor('1.3.0');
      expect(notes, isNotNull);

      final aluno = notes!.entriesFor(ReleaseViewer.student);
      final academia = notes.entriesFor(ReleaseViewer.academy);

      expect(aluno.length, 3, reason: 'aluno vê só tema, idioma e visual');
      expect(
        aluno.every((e) => e.audience == ReleaseAudience.all),
        isTrue,
        reason: 'nada de regra de negócio para o aluno',
      );
      expect(academia.length, greaterThan(aluno.length));
    });

    test('versão desconhecida não tem notas', () {
      expect(releaseNotesFor('0.0.1'), isNull);
    });
  });

  testWidgets('PT + dark: título, CTA e cards do aluno', (tester) async {
    await _openDialog(
      tester,
      locale: const Locale('pt'),
      brightness: Brightness.dark,
      viewer: ReleaseViewer.student,
    );

    expect(find.text('Novidades do Sensei Manager!'), findsOneWidget);
    expect(find.text('Entendi'), findsOneWidget);
    expect(find.text('VERSÃO 1.3.0'), findsOneWidget);
    expect(find.text('Agora também em tema claro'), findsOneWidget);
    // Card exclusivo de academia não aparece para o aluno.
    expect(find.text('Redefinição de senha pelo app'), findsNothing);
  });

  testWidgets('PT + light: mesmo conteúdo, tema claro', (tester) async {
    await _openDialog(
      tester,
      locale: const Locale('pt'),
      brightness: Brightness.light,
      viewer: ReleaseViewer.academy,
    );

    expect(find.text('Novidades do Sensei Manager!'), findsOneWidget);
    expect(find.text('Redefinição de senha pelo app'), findsOneWidget);
  });

  testWidgets('EN + dark: strings em inglês', (tester) async {
    await _openDialog(
      tester,
      locale: const Locale('en'),
      brightness: Brightness.dark,
      viewer: ReleaseViewer.academy,
    );

    expect(find.text("What's new in Sensei Manager!"), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
    expect(find.text('VERSION 1.3.0'), findsOneWidget);
    expect(find.text('NEW'), findsWidgets);
  });

  testWidgets('EN + light: fecha no CTA', (tester) async {
    await _openDialog(
      tester,
      locale: const Locale('en'),
      brightness: Brightness.light,
      viewer: ReleaseViewer.student,
    );

    expect(find.text("What's new in Sensei Manager!"), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text("What's new in Sensei Manager!"), findsNothing);
  });
}
