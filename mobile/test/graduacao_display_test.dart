import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/screens/aluno/widgets/graduacao_display.dart';

Future<void> _pump(WidgetTester tester, GraduacaoView g,
    {GraduacaoDisplaySize size = GraduacaoDisplaySize.compact}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: GraduacaoDisplay(graduacao: g, size: size, overline: 'Graduação atual'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('mostra o grau quando existe', (tester) async {
    await _pump(
      tester,
      const GraduacaoView(
        modalidadeNome: 'Jiu-Jitsu',
        graduacaoNome: 'Roxa',
        corHex: '#8E44AD',
        temGraus: true,
        grau: 3,
        maxGraus: 4,
      ),
    );
    expect(find.text('Roxa'), findsOneWidget);
    expect(find.textContaining('3º grau'), findsOneWidget);
  });

  testWidgets('não mostra rótulo de grau quando não há graus', (tester) async {
    await _pump(
      tester,
      const GraduacaoView(
        modalidadeNome: 'Muay Thai',
        graduacaoNome: 'Faixa Preta',
        corHex: '#111111',
        temGraus: false,
        grau: 0,
      ),
    );
    expect(find.textContaining('grau'), findsNothing);
    expect(find.text('Faixa Preta'), findsOneWidget);
  });

  testWidgets('cor inválida não quebra a UI (cai no modo textual)', (tester) async {
    await _pump(
      tester,
      const GraduacaoView(
        modalidadeNome: 'Karatê',
        graduacaoNome: 'Marrom',
        corHex: 'cor-invalida',
        temGraus: true,
        grau: 1,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Marrom'), findsOneWidget);
  });

  testWidgets('modalidade sem sistema de cor usa apresentação textual', (tester) async {
    await _pump(
      tester,
      const GraduacaoView(
        modalidadeNome: 'Boxe',
        graduacaoNome: 'Nível Avançado',
        corHex: null,
        temGraus: false,
      ),
    );
    expect(find.text('Nível Avançado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('suporta maxGraus variável (10) sem estourar', (tester) async {
    await _pump(
      tester,
      const GraduacaoView(
        modalidadeNome: 'Judô',
        graduacaoNome: 'Faixa',
        corHex: '#2E86C1',
        temGraus: true,
        grau: 7,
        maxGraus: 10,
      ),
    );
    expect(tester.takeException(), isNull);
    // Acima de 6 graus o rótulo textual carrega o número.
    expect(find.textContaining('7º grau de 10'), findsOneWidget);
  });

  testWidgets('nome de modalidade e graduação longos não estouram layout',
      (tester) async {
    await _pump(
      tester,
      const GraduacaoView(
        modalidadeNome:
            'Jiu-Jitsu Brasileiro Adulto Competição Avançado Turma da Manhã',
        graduacaoNome: 'Faixa Roxa com Ponteira Preta Grau Intermediário',
        corHex: '#8E44AD',
        temGraus: true,
        grau: 2,
        maxGraus: 4,
      ),
      size: GraduacaoDisplaySize.full,
    );
    expect(tester.takeException(), isNull);
  });
}
