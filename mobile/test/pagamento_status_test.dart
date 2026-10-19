import 'package:flutter_test/flutter_test.dart';
import 'package:tatame/core/pagamento_status.dart';

void main() {
  group('pagamentoStatusFromInt', () {
    test('mapeia os inteiros conhecidos', () {
      expect(pagamentoStatusFromInt(0), PagamentoStatus.pendente);
      expect(pagamentoStatusFromInt(1), PagamentoStatus.pago);
      expect(pagamentoStatusFromInt(2), PagamentoStatus.atrasado);
      expect(pagamentoStatusFromInt(3), PagamentoStatus.previsto);
      expect(pagamentoStatusFromInt(4), PagamentoStatus.desconsiderado);
    });

    test('aceita string numérica', () {
      expect(pagamentoStatusFromInt('1'), PagamentoStatus.pago);
      expect(pagamentoStatusFromInt('4'), PagamentoStatus.desconsiderado);
    });

    test('nulo ou lixo cai em pendente', () {
      expect(pagamentoStatusFromInt(null), PagamentoStatus.pendente);
      expect(pagamentoStatusFromInt('abc'), PagamentoStatus.pendente);
      expect(pagamentoStatusFromInt(99), PagamentoStatus.pendente);
    });
  });

  group('pagamentoStatusEfetivo', () {
    final hoje = DateTime(2026, 9, 10);

    test('pendente vencido ONTEM vira atrasado', () {
      expect(
        pagamentoStatusEfetivo(
          rawStatus: 0,
          dataVencimento: '2026-09-09',
          hoje: hoje,
        ),
        PagamentoStatus.atrasado,
      );
    });

    test('pendente vencendo HOJE ainda é pendente', () {
      expect(
        pagamentoStatusEfetivo(
          rawStatus: 0,
          dataVencimento: '2026-09-10',
          hoje: hoje,
        ),
        PagamentoStatus.pendente,
      );
    });

    test('pendente com vencimento futuro continua pendente', () {
      expect(
        pagamentoStatusEfetivo(
          rawStatus: 0,
          dataVencimento: '2026-10-05',
          hoje: hoje,
        ),
        PagamentoStatus.pendente,
      );
    });

    test('previsto vencido também vira atrasado', () {
      expect(
        pagamentoStatusEfetivo(
          rawStatus: 3,
          dataVencimento: '2026-08-01',
          hoje: hoje,
        ),
        PagamentoStatus.atrasado,
      );
    });

    test('pago vencido NUNCA vira atrasado', () {
      expect(
        pagamentoStatusEfetivo(
          rawStatus: 1,
          dataVencimento: '2026-01-01',
          hoje: hoje,
        ),
        PagamentoStatus.pago,
      );
    });

    test('desconsiderado vencido NUNCA vira atrasado', () {
      expect(
        pagamentoStatusEfetivo(
          rawStatus: 4,
          dataVencimento: '2026-01-01',
          hoje: hoje,
        ),
        PagamentoStatus.desconsiderado,
      );
    });

    test('sem data de vencimento mantém o status base', () {
      expect(
        pagamentoStatusEfetivo(rawStatus: 0, dataVencimento: null, hoje: hoje),
        PagamentoStatus.pendente,
      );
    });
  });

  group('predicados de negócio', () {
    test('só Pago conta como receita', () {
      expect(pagamentoContaComoReceita(PagamentoStatus.pago), isTrue);
      for (final s in [
        PagamentoStatus.pendente,
        PagamentoStatus.atrasado,
        PagamentoStatus.previsto,
        PagamentoStatus.desconsiderado,
      ]) {
        expect(pagamentoContaComoReceita(s), isFalse, reason: '$s');
      }
    });

    test('pendência aberta = pendente ou atrasado', () {
      expect(pagamentoEhPendenciaAberta(PagamentoStatus.pendente), isTrue);
      expect(pagamentoEhPendenciaAberta(PagamentoStatus.atrasado), isTrue);
      expect(pagamentoEhPendenciaAberta(PagamentoStatus.previsto), isFalse);
      expect(pagamentoEhPendenciaAberta(PagamentoStatus.pago), isFalse);
      expect(
        pagamentoEhPendenciaAberta(PagamentoStatus.desconsiderado),
        isFalse,
      );
    });

    test('desconsiderado: nem receita da academia, nem pendência do aluno', () {
      expect(
        pagamentoContaComoReceita(PagamentoStatus.desconsiderado),
        isFalse,
      );
      expect(
        pagamentoEhPendenciaAberta(PagamentoStatus.desconsiderado),
        isFalse,
      );
    });
  });

  group('pagamentoMesReferencia', () {
    test('usa mes_referencia quando presente', () {
      expect(
        pagamentoMesReferencia({
          'mes_referencia': '2026-07',
          'data_vencimento': '2026-08-01',
        }),
        '2026-07',
      );
    });

    test('deriva do data_vencimento quando falta mes_referencia', () {
      expect(
        pagamentoMesReferencia({'data_vencimento': '2026-08-15'}),
        '2026-08',
      );
    });

    test('sem nenhum dos dois retorna vazio', () {
      expect(pagamentoMesReferencia({}), '');
    });
  });

  group('consistência aluno x academia (mesmo doc, mesma leitura)', () {
    final hoje = DateTime(2026, 9, 10);

    Map<String, dynamic> doc(int status, String venc) => {
      'status': status,
      'data_vencimento': venc,
      'mes_referencia': venc.substring(0, 7),
      'valor': 150,
    };

    test('academia marca como pago -> aluno lê pago e não é pendência', () {
      final d = doc(1, '2026-09-05');
      final st = pagamentoStatusEfetivo(
        rawStatus: d['status'],
        dataVencimento: d['data_vencimento'],
        hoje: hoje,
      );
      expect(st, PagamentoStatus.pago);
      expect(pagamentoEhPendenciaAberta(st), isFalse);
      expect(pagamentoContaComoReceita(st), isTrue);
    });

    test('academia desconsidera -> aluno lê desconsiderado, some da pendência '
        'e não vira receita', () {
      final d = doc(4, '2026-09-05');
      final st = pagamentoStatusEfetivo(
        rawStatus: d['status'],
        dataVencimento: d['data_vencimento'],
        hoje: hoje,
      );
      expect(st, PagamentoStatus.desconsiderado);
      expect(pagamentoEhPendenciaAberta(st), isFalse);
      expect(pagamentoContaComoReceita(st), isFalse);
    });

    test('cobrança gerada e vencida -> os dois lados enxergam atrasado', () {
      final d = doc(0, '2026-07-05');
      final st = pagamentoStatusEfetivo(
        rawStatus: d['status'],
        dataVencimento: d['data_vencimento'],
        hoje: hoje,
      );
      expect(st, PagamentoStatus.atrasado);
      expect(pagamentoEhPendenciaAberta(st), isTrue);
    });
  });
}
