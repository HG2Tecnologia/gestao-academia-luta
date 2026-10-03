/// Exportação do relatório financeiro (lista de cobranças do mês/filtro
/// atual da tela de Financeiro) em PDF e Excel. Mesmo padrão de
/// `relatorio_presencas_export.dart`, mas com colunas próprias — mantido
/// separado de propósito, já que os dois domínios (presença x cobrança) têm
/// formas de linha diferentes e não ganham nada em compartilhar o mesmo tipo.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

enum ColunaFinanceiro { nome, tipo, valor, vencimento, status, dataPagamento }

class LinhaRelatorioFinanceiro {
  final String nomeAluno;
  final String tipo;
  final String valorFormatado;
  final String vencimentoFormatado;
  final String status;
  final String dataPagamentoFormatada;

  const LinhaRelatorioFinanceiro({
    required this.nomeAluno,
    required this.tipo,
    required this.valorFormatado,
    required this.vencimentoFormatado,
    required this.status,
    required this.dataPagamentoFormatada,
  });
}

String _valorColuna(ColunaFinanceiro c, LinhaRelatorioFinanceiro l) {
  switch (c) {
    case ColunaFinanceiro.nome:
      return l.nomeAluno;
    case ColunaFinanceiro.tipo:
      return l.tipo;
    case ColunaFinanceiro.valor:
      return l.valorFormatado;
    case ColunaFinanceiro.vencimento:
      return l.vencimentoFormatado;
    case ColunaFinanceiro.status:
      return l.status;
    case ColunaFinanceiro.dataPagamento:
      return l.dataPagamentoFormatada;
  }
}

Future<void> exportarRelatorioFinanceiroPdf({
  required List<LinhaRelatorioFinanceiro> linhas,
  required List<ColunaFinanceiro> colunas,
  required Map<ColunaFinanceiro, String> rotulos,
  required String tituloAcademia,
  required String periodoLabel,
  Rect? sharePositionOrigin,
}) async {
  final doc = pw.Document();
  final cabecalho = colunas.map((c) => rotulos[c] ?? '').toList();
  final linhasTabela = linhas.map((l) => colunas.map((c) => _valorColuna(c, l)).toList()).toList();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (_) => [
        pw.Text(tituloAcademia, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(periodoLabel, style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: cabecalho,
          data: linhasTabela,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9.5),
          cellAlignment: pw.Alignment.centerLeft,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        ),
      ],
    ),
  );

  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'relatorio_financeiro.pdf',
    bounds: sharePositionOrigin,
  );
}

Future<void> exportarRelatorioFinanceiroExcel({
  required List<LinhaRelatorioFinanceiro> linhas,
  required List<ColunaFinanceiro> colunas,
  required Map<ColunaFinanceiro, String> rotulos,
  required String tituloAcademia,
  required String periodoLabel,
  Rect? sharePositionOrigin,
}) async {
  final excel = xls.Excel.createExcel();
  final sheetName = excel.getDefaultSheet() ?? 'Relatório';
  final sheet = excel[sheetName];

  sheet.appendRow([xls.TextCellValue(tituloAcademia)]);
  sheet.appendRow([xls.TextCellValue(periodoLabel)]);
  sheet.appendRow(const []);
  sheet.appendRow(colunas.map((c) => xls.TextCellValue(rotulos[c] ?? '')).toList());
  for (final l in linhas) {
    sheet.appendRow(colunas.map((c) => xls.TextCellValue(_valorColuna(c, l))).toList());
  }

  final bytes = excel.encode();
  if (bytes == null) return;

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/relatorio_financeiro.xlsx');
  await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);

  await Share.shareXFiles(
    [XFile(file.path)],
    text: tituloAcademia,
    sharePositionOrigin: sharePositionOrigin,
  );
}
