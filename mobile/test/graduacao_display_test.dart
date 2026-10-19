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

  testWidgets(
    'faixa sem grauCoresFaixa (todo o histórico hoje) mantém o visual de sempre',
    (tester) async {
      final g = GraduacaoView.fromMap(const {
        'nomeModalidade': 'Jiu-Jitsu Infantil',
        'nomeFaixa': 'Branca',
        'corFaixa': '#FFFFFF',
        'corBarraFaixa': '#000000',
        'faixaTemGraus': true,
        'grau': 2,
        'faixaMaxGraus': 4,
      });
      expect(g.grauCoresHex, isEmpty);
      await _pump(tester, g);
      expect(tester.takeException(), isNull);
      expect(find.text('Branca'), findsOneWidget);
    },
  );

  testWidgets(
    'graus coloridos (12 graus, sistema IBJJF/CBJJ) renderiza sem exceção',
    (tester) async {
      final g = GraduacaoView.fromMap(const {
        'nomeModalidade': 'Jiu-Jitsu Infantil',
        'nomeFaixa': 'Branca',
        'corFaixa': '#FFFFFF',
        'corBarraFaixa': '#000000',
        'faixaTemGraus': true,
        'grau': 9,
        'faixaMaxGraus': 12,
        'grauCoresFaixa': [
          '#FFFFFF', '#FFFFFF', '#FFFFFF', '#FFFFFF',
          '#FF0000', '#FF0000', '#FF0000', '#FF0000',
          '#FFFF00', '#FFFF00', '#FFFF00', '#FFFF00',
        ],
      });
      expect(g.grauCoresHex.length, 12);
      await _pump(tester, g);
      expect(tester.takeException(), isNull);
      // Acima de 6 graus SEM cor por grau, só o texto aparece (comportamento
      // de hoje, coberto no teste "suporta maxGraus variável (10)" acima) —
      // mas aqui, COM grauCoresFaixa preenchido, o rótulo textual também
      // deve aparecer (o limite de marcadores sobe, mas o label continua).
      expect(find.textContaining('9º grau de 12'), findsOneWidget);
    },
  );

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
