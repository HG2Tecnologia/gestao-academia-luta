/// Exportação do relatório oficial de presenças em PDF e Excel. Mantido
/// separado da tela (`relatorio_presencas_screen.dart`) e da agregação
/// (`relatorio_presencas_oficial.dart`) — só sabe transformar
/// [LinhaRelatorioPresenca] + rótulos de coluna já resolvidos (vêm de
/// `context.l10n`, este arquivo não depende de l10n) em arquivo.
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

import 'relatorio_presencas_oficial.dart';

/// Colunas disponíveis para exportação — a tela decide quais ficam marcadas
/// por padrão e deixa o usuário desmarcar as que não quer no documento.
enum ColunaRelatorio { nome, telefone, turma, faixa, presencas, faltas, totalAulas, percentual }

String _valorColuna(ColunaRelatorio c, LinhaRelatorioPresenca l) {
  switch (c) {
    case ColunaRelatorio.nome:
      return l.nomeAluno;
    case ColunaRelatorio.telefone:
      return l.telefone;
    case ColunaRelatorio.turma:
      return l.nomeTurma;
    case ColunaRelatorio.faixa:
      return l.faixaNome;
    case ColunaRelatorio.presencas:
      return '${l.presencas}';
    case ColunaRelatorio.faltas:
      return '${l.faltas}';
    case ColunaRelatorio.totalAulas:
      return '${l.totalAulas}';
    case ColunaRelatorio.percentual:
      return '${l.percentual.toStringAsFixed(0)}%';
  }
}

Future<void> exportarRelatorioPdf({
  required List<LinhaRelatorioPresenca> linhas,
  required List<ColunaRelatorio> colunas,
  required Map<ColunaRelatorio, String> rotulos,
  required String tituloAcademia,
  required String periodoLabel,
  required String turmaLabel,
  Rect? sharePositionOrigin,
}) async {
  // `printing` chama esse parâmetro de `bounds`, não `sharePositionOrigin`
  // (esse nome é específico do `share_plus`, usado no Excel abaixo).
  final doc = pw.Document();
  final cabecalho = colunas.map((c) => rotulos[c] ?? '').toList();
  final linhasTabela = linhas.map((l) => colunas.map((c) => _valorColuna(c, l)).toList()).toList();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (_) => [
        pw.Text(tituloAcademia, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('$periodoLabel · $turmaLabel', style: const pw.TextStyle(fontSize: 11)),
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
    filename: 'relatorio_presencas.pdf',
    bounds: sharePositionOrigin,
  );
}

Future<void> exportarRelatorioExcel({
  required List<LinhaRelatorioPresenca> linhas,
  required List<ColunaRelatorio> colunas,
  required Map<ColunaRelatorio, String> rotulos,
  required String tituloAcademia,
  required String periodoLabel,
  required String turmaLabel,
  Rect? sharePositionOrigin,
}) async {
  final excel = xls.Excel.createExcel();
  final sheetName = excel.getDefaultSheet() ?? 'Relatório';
  final sheet = excel[sheetName];

  sheet.appendRow([xls.TextCellValue(tituloAcademia)]);
  sheet.appendRow([xls.TextCellValue('$periodoLabel · $turmaLabel')]);
  sheet.appendRow(const []);
  sheet.appendRow(colunas.map((c) => xls.TextCellValue(rotulos[c] ?? '')).toList());
  for (final l in linhas) {
    sheet.appendRow(colunas.map((c) => xls.TextCellValue(_valorColuna(c, l))).toList());
  }

  final bytes = excel.encode();
  if (bytes == null) return;

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/relatorio_presencas.xlsx');
  await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);

  await Share.shareXFiles(
    [XFile(file.path)],
    text: tituloAcademia,
    sharePositionOrigin: sharePositionOrigin,
  );
}
