import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/financeiro_resumo.dart';

/// Doc `pagamentos` mínimo. [status]: 0 Pendente · 1 Pago · 3 Previsto ·
/// 4 Desconsiderado.
Map<String, dynamic> cobranca({
  required int status,
  required String venc,
  num valor = 150,
  num? valorPago,
  String? alunoId,
  String? mesRef,
}) => {
  'status': status,
  'data_vencimento': venc,
  'mes_referencia': mesRef ?? venc.substring(0, 7),
  'valor': valor,
  if (valorPago != null) 'valor_pago': valorPago,
  'aluno_id': alunoId ?? 'aluno-1',
};

void main() {
  final hoje = DateTime(2026, 9, 10); // "hoje" fixo pros testes

  group('Bloco 2 — gerar cobranças', () {
    test('cobrança recém-gerada aparece como Pendente no mês', () {
      final r = resumoFinanceiroAcademia(
        [cobranca(status: 0, venc: '2026-09-15')],
        ano: 2026,
        mes: 9,
        hoje: hoje,
      );
      expect(r.qtdPendente, 1);
      expect(r.totalPendenteMes, 150);
      expect(r.qtdRecebido, 0);
      expect(r.qtdAtrasado, 0);
    });

    test('gerar cobrança já paga não altera o recebido (idempotente)', () {
      final docs = [
        cobranca(status: 1, venc: '2026-09-15', valorPago: 150),
      ];
      final r1 = resumoFinanceiroAcademia(docs, ano: 2026, mes: 9, hoje: hoje);
      final r2 = resumoFinanceiroAcademia(docs, ano: 2026, mes: 9, hoje: hoje);
      expect(r1.totalRecebidoMes, 150);
      expect(r2.totalRecebidoMes, 150); // repetir não duplica
    });
  });

  group('Bloco 3 — cobrança avulsa', () {
    test('vencimento no passado entra como atrasada', () {
      final r = resumoFinanceiroAcademia(
        [cobranca(status: 0, venc: '2026-09-01')],
        ano: 2026,
        mes: 9,
        hoje: hoje,
      );
      expect(r.qtdAtrasado, 1);
      expect(r.totalAtrasado, 150);
    });

    test('vencimento HOJE ainda não é atraso', () {
      final r = resumoFinanceiroAcademia(
        [cobranca(status: 0, venc: '2026-09-10')],
        ano: 2026,
        mes: 9,
        hoje: hoje,
      );
      expect(r.qtdAtrasado, 0);
      expect(r.qtdPendente, 1);
    });

    test('vencimento futuro não conta como pendente do mês corrente', () {
      final r = resumoFinanceiroAcademia(
        [cobranca(status: 0, venc: '2026-10-05')],
        ano: 2026,
        mes: 9,
        hoje: hoje,
      );
      expect(r.qtdPendente, 0);
      expect(r.qtdAtrasado, 0);
    });
  });

  group('Bloco 4 — marcar pago / desfazer', () {
    test('marcar pago: sai de pendente, entra em recebido', () {
      final pendente = resumoFinanceiroAcademia(
        [cobranca(status: 0, venc: '2026-09-15')],
        ano: 2026,
        mes: 9,
        hoje: hoje,
      );
      expect(pendente.qtdPendente, 1);
      expect(pendente.qtdRecebido, 0);

      final pago = resumoFinanceiroAcademia(
        [cobranca(status: 1, venc: '2026-09-15', valorPago: 150)],
        ano: 2026,
        mes: 9,
        hoje: hoje,
      );
      expect(pago.qtdPendente, 0);
      expect(pago.qtdRecebido, 1);
      expect(pago.totalRecebidoMes, 150);
    });

    test('marcar pago numa atrasada também tira do atraso e da inadimplência', () {
      final atrasada = resumoFinanceiroAcademia(
        [cobranca(status: 0, venc: '2026-08-01', alunoId: 'a1')],
        ano: 2026,
        mes: 8,
        hoje: hoje,
      );
      expect(atrasada.qtdAtrasado, 1);
      expect(atrasada.alunosInadimplentes, 1);

      final paga = resumoFinanceiroAcademia(
        [cobranca(status: 1, venc: '2026-08-01', alunoId: 'a1')],
        ano: 2026,
        mes: 8,
        hoje: hoje,
      );
      expect(paga.qtdAtrasado, 0);
      expect(paga.alunosInadimplentes, 0);
    });

    test('desfazer pagamento: volta a contar como pendente/atrasado', () {
      final desfeita = resumoFinanceiroAcademia(
        [cobranca(status: 0, venc: '2026-08-01')], // status volta a 0
        ano: 2026,
        mes: 8,
        hoje: hoje,
      );
      expect(desfeita.qtdAtrasado, 1);
      expect(desfeita.qtdRecebido, 0);
    });

    test('pagamento antecipado (mês futuro) conta no recebido do mês futuro', () {
      final r = resumoFinanceiroAcademia(
        [cobranca(status: 1, venc: '2026-10-10', valorPago: 150)],
        ano: 2026,
        mes: 10,
        hoje: hoje,
      );
      expect(r.totalRecebidoMes, 150);
      expect(r.qtdRecebido, 1);
    });
  });

  group('Bloco 5 — desconsiderar / reativar (o bug relatado)', () {
    test('desconsiderar tira de tudo e NUNCA vira receita', () {
      final r = resumoFinanceiroAcademia(
        [cobranca(status: 4, venc: '2026-08-01', alunoId: 'a1')],
        ano: 2026,
        mes: 8,
        hoje: hoje,
      );
      expect(r.totalRecebidoMes, 0);
      expect(r.totalPendenteMes, 0);
      expect(r.totalAtrasado, 0);
      expect(r.alunosInadimplentes, 0);
      expect(r.qtdRecebido + r.qtdPendente + r.qtdAtrasado, 0);
    });

    test('desconsiderar uma atrasada some da inadimplência', () {
      final antes = resumoFinanceiroAcademia(
        [cobranca(status: 0, venc: '2026-08-01', alunoId: 'a1')],
        ano: 2026,
        mes: 8,
        hoje: hoje,
      );
      expect(antes.alunosInadimplentes, 1);

      final depois = resumoFinanceiroAcademia(
        [cobranca(status: 4, venc: '2026-08-01', alunoId: 'a1')],
        ano: 2026,
        mes: 8,
        hoje: hoje,
      );
      expect(depois.alunosInadimplentes, 0);
    });

    test('reativar (volta pra pendente) volta a contar', () {
      final reativada = resumoFinanceiroAcademia(
        [cobranca(status: 0, venc: '2026-09-15')],
        ano: 2026,
        mes: 9,
        hoje: hoje,
      );
      expect(reativada.qtdPendente, 1);
    });

    test('app do aluno: desconsiderada não é pendência nem soma no total', () {
      final linhas = montarCobrancasAluno([
        cobranca(status: 4, venc: '2026-08-01'),
        cobranca(status: 0, venc: '2026-09-15'),
      ], hoje: hoje);

      expect(linhas[0].status, 'Desconsiderado');
      expect(totalEmAbertoAluno(linhas), 150); // só a pendente conta
      expect(contarStatusAluno(linhas, 'Desconsiderado'), 1);
      expect(atrasadasAluno(linhas), isEmpty); // vencida mas desconsiderada
    });
  });

  group('Bloco 6 — excluir cobrança', () {
    test('excluída não existe mais na lista => some de todos os totais', () {
      // "excluir" = documento não está mais na lista de entrada.
      final r = resumoFinanceiroAcademia(
        <Map<String, dynamic>>[],
        ano: 2026,
        mes: 9,
        hoje: hoje,
      );
      expect(r.toMap().values.every((v) => v == 0), isTrue);
    });

    test('excluir uma paga reduz o recebido do mês', () {
      final comDuas = resumoFinanceiroAcademia(
        [
          cobranca(status: 1, venc: '2026-09-05', valorPago: 150),
          cobranca(status: 1, venc: '2026-09-06', valorPago: 200),
        ],
        ano: 2026,
        mes: 9,
        hoje: hoje,
      );
      expect(comDuas.totalRecebidoMes, 350);

      final apenasUma = resumoFinanceiroAcademia(
        [cobranca(status: 1, venc: '2026-09-05', valorPago: 150)],
        ano: 2026,
        mes: 9,
        hoje: hoje,
      );
      expect(apenasUma.totalRecebidoMes, 150);
    });
  });

  group('Bloco 9 — resumo do aluno (todos os meses)', () {
    test('atrasadas em 2 meses diferentes aparecem juntas e ordenadas', () {
      final linhas = montarCobrancasAluno([
        cobranca(status: 0, venc: '2026-07-10'),
        cobranca(status: 0, venc: '2026-08-10'),
        cobranca(status: 0, venc: '2026-10-10'), // futuro: não atrasada
      ], hoje: hoje);

      final atrasadas = atrasadasAluno(linhas);
      expect(atrasadas.length, 2);
      expect(atrasadas.first.raw['data_vencimento'], '2026-07-10');
      expect(atrasadas.last.raw['data_vencimento'], '2026-08-10');
    });

    test('total em aberto soma pendente + atrasado de todos os meses', () {
      final linhas = montarCobrancasAluno([
        cobranca(status: 0, venc: '2026-07-10', valor: 100), // atrasada
        cobranca(status: 0, venc: '2026-09-20', valor: 200), // pendente
        cobranca(status: 3, venc: '2026-11-10', valor: 300), // previsto
        cobranca(status: 4, venc: '2026-06-10', valor: 999), // desconsiderada
      ], hoje: hoje);

      expect(totalEmAbertoAluno(linhas), 300); // 100 + 200, sem previsto/desc.
    });

    test('sem nenhuma pendência: tudo em dia', () {
      final linhas = montarCobrancasAluno([
        cobranca(status: 1, venc: '2026-09-05', valorPago: 150),
      ], hoje: hoje);

      expect(totalEmAbertoAluno(linhas), 0);
      expect(atrasadasAluno(linhas), isEmpty);
    });

    test('cobrancasDoMesAluno filtra só o mês pedido', () {
      final linhas = montarCobrancasAluno([
        cobranca(status: 0, venc: '2026-08-10'),
        cobranca(status: 0, venc: '2026-09-10'),
        cobranca(status: 0, venc: '2026-09-20'),
      ], hoje: hoje);

      expect(cobrancasDoMesAluno(linhas, '2026-09').length, 2);
      expect(cobrancasDoMesAluno(linhas, '2026-08').length, 1);
      expect(cobrancasDoMesAluno(linhas, '2026-12'), isEmpty);
    });
  });

  group('Bloco 10 — consistência de data (vira o dia)', () {
    test('vencida ontem = atrasado nos dois lados', () {
      final academia = resumoFinanceiroAcademia(
        [cobranca(status: 0, venc: '2026-09-09')],
        ano: 2026,
        mes: 9,
        hoje: hoje,
      );
      final aluno = montarCobrancasAluno([
        cobranca(status: 0, venc: '2026-09-09'),
      ], hoje: hoje);

      expect(academia.qtdAtrasado, 1);
      expect(aluno.single.status, 'Atrasado');
    });

    test('paga vencida no passado NUNCA aparece como atrasada', () {
      final academia = resumoFinanceiroAcademia(
        [cobranca(status: 1, venc: '2026-01-01', valorPago: 150)],
        ano: 2026,
        mes: 1,
        hoje: hoje,
      );
      final aluno = montarCobrancasAluno([
        cobranca(status: 1, venc: '2026-01-01'),
      ], hoje: hoje);

      expect(academia.qtdAtrasado, 0);
      expect(aluno.single.status, 'Pago');
    });

    test('desconsiderada vencida NUNCA aparece como atrasada', () {
      final academia = resumoFinanceiroAcademia(
        [cobranca(status: 4, venc: '2026-01-01')],
        ano: 2026,
        mes: 1,
        hoje: hoje,
      );
      final aluno = montarCobrancasAluno([
        cobranca(status: 4, venc: '2026-01-01'),
      ], hoje: hoje);

      expect(academia.qtdAtrasado, 0);
      expect(aluno.single.status, 'Desconsiderado');
    });
  });
}
