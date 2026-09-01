import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

const currencySymbols = {'EGP': 'ج.م', 'USD': '\$'};

String fmtNum(num n) {
  final parts = n.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  final dec = parts[1] == '00' ? '' : '.${parts[1]}';
  return '$intPart$dec';
}

class InvoiceRow {
  final String date;
  final String details;
  final double debit;
  final double credit;
  final double balance;
  final String currency;

  InvoiceRow({
    required this.date,
    required this.details,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.currency,
  });
}

Future<Uint8List> buildInvoicePdf({
  required String title,
  required String subtitle,
  required List<InvoiceRow> rows,
  required List<MapEntry<String, String>> totals,
}) async {
  final regularData = await rootBundle.load(
      'assets/fonts/NotoNaskhArabic-Regular.ttf');
  final boldData = await rootBundle.load(
      'assets/fonts/NotoNaskhArabic-Bold.ttf');
  final regular = pw.Font.ttf(regularData);
  final bold = pw.Font.ttf(boldData);

  final doc = pw.Document();
  final theme = pw.ThemeData.withFont(base: regular, bold: bold);

  final totalDebit = rows.fold<double>(0, (sum, r) => sum + r.debit);
  final totalCredit = rows.fold<double>(0, (sum, r) => sum + r.credit);
  final finalBalance = rows.isEmpty ? 0.0 : rows.last.balance;
  final currency = rows.isEmpty ? '' : rows.first.currency;
  final balanceLabel = finalBalance >= 0
      ? 'الرصيد الإجمالي - عليه'
      : 'الرصيد الإجمالي - له';
  final balanceText = '${fmtNum(finalBalance.abs())} $currency'.trim();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(24, 26, 24, 28),
      theme: theme,
      textDirection: pw.TextDirection.rtl,
      build: (context) {
        final tableRows = <pw.TableRow>[
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              _cell('الرصيد', bold, align: pw.TextAlign.center),
              _cell('له', bold, align: pw.TextAlign.center),
              _cell('عليه', bold, align: pw.TextAlign.center),
              _cell('التفاصيل', bold, align: pw.TextAlign.center),
              _cell('التاريخ', bold, align: pw.TextAlign.center),
            ],
          ),
          ...rows.map((r) => pw.TableRow(children: [
                _cell('${fmtNum(r.balance)} ${r.currency}'.trim(), bold,
                    align: pw.TextAlign.center),
                _cell(r.credit == 0 ? '' : fmtNum(r.credit), bold,
                    align: pw.TextAlign.center, color: PdfColors.red),
                _cell(r.debit == 0 ? '' : fmtNum(r.debit), bold,
                    align: pw.TextAlign.center, color: PdfColors.red),
                _cell(r.details, bold, align: pw.TextAlign.center),
                _cell(r.date, bold, align: pw.TextAlign.center),
              ])),
          pw.TableRow(children: [
            _cell('', regular, align: pw.TextAlign.center),
            _cell(totalCredit == 0 ? '' : fmtNum(totalCredit), bold,
                align: pw.TextAlign.center, color: PdfColors.red),
            _cell(totalDebit == 0 ? '' : fmtNum(totalDebit), bold,
                align: pw.TextAlign.center, color: PdfColors.red),
            _cell('إجمالي العمليات', bold, align: pw.TextAlign.center),
            _cell('', regular, align: pw.TextAlign.center),
          ]),
          pw.TableRow(
            decoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFB3B0)),
            children: [
              _cell(balanceText, bold,
                  align: pw.TextAlign.center, color: PdfColors.blue900),
              _cell('', regular, align: pw.TextAlign.center),
              _cell('', regular, align: pw.TextAlign.center),
              _cell(balanceLabel, bold,
                  align: pw.TextAlign.center, color: PdfColors.blue900),
              _cell('', regular, align: pw.TextAlign.center),
            ],
          ),
        ];

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: bold, fontSize: 18),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              subtitle,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: regular, fontSize: 11),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey600,
                width: 0.7,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.0),
                1: const pw.FlexColumnWidth(0.75),
                2: const pw.FlexColumnWidth(0.85),
                3: const pw.FlexColumnWidth(2.25),
                4: const pw.FlexColumnWidth(1.25),
              },
              children: tableRows,
            ),
          ],
        );
      },
    ),
  );
  return doc.save();
}

pw.Widget _cell(
  String text,
  pw.Font font, {
  pw.TextAlign align = pw.TextAlign.right,
  PdfColor? color,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(7),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(font: font, fontSize: 11, color: color),
    ),
  );
}

Future<File> savePdfToTemp(Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename.pdf');
  await file.writeAsBytes(bytes);
  return file;
}

Future<void> previewInvoicePdf(Uint8List bytes, String filename) async {
  await Printing.layoutPdf(onLayout: (format) async => bytes, name: filename);
}

Future<void> shareInvoiceViaWhatsApp(
    Uint8List bytes, String filename, String text) async {
  final file = await savePdfToTemp(bytes, filename);
  await Share.shareXFiles([XFile(file.path)], text: text);
}
