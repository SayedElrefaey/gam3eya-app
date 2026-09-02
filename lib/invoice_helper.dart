import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

const currencySymbols = {'EGP': 'ج.م', 'USD': '\$'};

String fmtNum(num n) {
  final parts = n.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
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

  const InvoiceRow({
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
  final regularData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
  final boldData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf');
  final regular = pw.Font.ttf(regularData);
  final bold = pw.Font.ttf(boldData);
  final latinFallback = pw.Font.helvetica();
  final theme = pw.ThemeData.withFont(base: regular, bold: bold);
  final doc = pw.Document();

  if (title == 'فاتورة حساب') {
    _addIndividualInvoicePage(doc: doc, theme: theme, regular: regular, bold: bold,
        latinFallback: latinFallback, title: title, subtitle: subtitle, rows: rows);
  } else {
    _addGam3eyaInvoicePage(doc: doc, theme: theme, regular: regular, bold: bold,
        latinFallback: latinFallback, title: title, subtitle: subtitle, rows: rows);
  }
  return doc.save();
}

void _addIndividualInvoicePage({
  required pw.Document doc,
  required pw.ThemeData theme,
  required pw.Font regular,
  required pw.Font bold,
  required pw.Font latinFallback,
  required String title,
  required String subtitle,
  required List<InvoiceRow> rows,
}) {
  final totalDebit = rows.fold<double>(0, (sum, r) => sum + r.debit);
  final totalCredit = rows.fold<double>(0, (sum, r) => sum + r.credit);
  final finalBalance = rows.isEmpty ? 0.0 : rows.last.balance;
  final currency = rows.isEmpty ? '' : rows.first.currency;

  // pw.Table is laid out left-to-right. To match the web RTL table exactly,
  // the children are supplied in reverse visual order:
  // left -> right = الرصيد | له | عليه | التفاصيل | التاريخ
  // so the visual rightmost column is التاريخ.
  final tableRows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFD9D9D9)),
      children: [
        _cell('الرصيد', bold, latinFallback, center: true, fontSize: 14,
            textColor: const PdfColor.fromInt(0xFF1414A0), padding: 8),
        _cell('له', bold, latinFallback, center: true, fontSize: 14,
            textColor: const PdfColor.fromInt(0xFF1414A0), padding: 8),
        _cell('عليه', bold, latinFallback, center: true, fontSize: 14,
            textColor: const PdfColor.fromInt(0xFF1414A0), padding: 8),
        _cell('التفاصيل', bold, latinFallback, center: true, fontSize: 14,
            textColor: const PdfColor.fromInt(0xFF1414A0), padding: 8),
        _cell('التاريخ', bold, latinFallback, center: true, fontSize: 14,
            textColor: const PdfColor.fromInt(0xFF1414A0), padding: 8),
      ],
    ),
    ...rows.map((r) => pw.TableRow(children: [
      _cell(fmtNum(r.balance), regular, latinFallback, center: true, fontSize: 14,
          textColor: const PdfColor.fromInt(0xFFA3002B), padding: 8),
      _cell(r.credit == 0 ? '0' : fmtNum(r.credit), regular, latinFallback, center: true, fontSize: 14,
          textColor: const PdfColor.fromInt(0xFF1E8A3C), padding: 8),
      _cell(r.debit == 0 ? '0' : fmtNum(r.debit), regular, latinFallback, center: true, fontSize: 14,
          textColor: const PdfColor.fromInt(0xFFA3002B), padding: 8),
      _cell(r.details, regular, latinFallback, center: true, fontSize: 14,
          textColor: const PdfColor.fromInt(0xFF1414A0), padding: 8),
      _cell(r.date, regular, latinFallback, center: true, fontSize: 14,
          textColor: const PdfColor.fromInt(0xFF1414A0), padding: 8),
    ])),
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEDEDED)),
      children: [
        _cell('', regular, latinFallback, center: true, fontSize: 14, padding: 8),
        _cell(fmtNum(totalCredit), bold, latinFallback, center: true, fontSize: 14,
            textColor: const PdfColor.fromInt(0xFF1E8A3C), padding: 8),
        _cell(fmtNum(totalDebit), bold, latinFallback, center: true, fontSize: 14,
            textColor: const PdfColor.fromInt(0xFFA3002B), padding: 8),
        _cell('إجمالي العمليات', bold, latinFallback, center: true, fontSize: 14, padding: 8),
        _cell('', regular, latinFallback, center: true, fontSize: 14, padding: 8),
      ],
    ),
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5B7B1)),
      children: [
        _cell('${fmtNum(finalBalance.abs())} $currency'.trim(), bold, latinFallback,
            center: true, fontSize: 16, textColor: const PdfColor.fromInt(0xFF1414A0), padding: 9),
        _cell('', regular, latinFallback, center: true, fontSize: 15, padding: 9),
        _cell('', regular, latinFallback, center: true, fontSize: 15, padding: 9),
        _cell(finalBalance >= 0 ? 'الرصيد الإجمالي - عليه' : 'الرصيد الإجمالي - له', bold, latinFallback,
            center: true, fontSize: 15, textColor: const PdfColor.fromInt(0xFF1414A0), padding: 9),
        _cell('', regular, latinFallback, center: true, fontSize: 15, padding: 9),
      ],
    ),
  ];

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(14, 14, 14, 16),
    theme: theme,
    textDirection: pw.TextDirection.rtl,
    build: (context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(title, textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: bold, fontSize: 17, fontFallback: [latinFallback])),
        pw.SizedBox(height: 2),
        pw.Text(subtitle, textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: regular, fontSize: 11, fontFallback: [latinFallback],
                color: const PdfColor.fromInt(0xFF6B6248))),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFF999999), width: 0.65),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.05),
            1: pw.FlexColumnWidth(1.0),
            2: pw.FlexColumnWidth(1.05),
            3: pw.FlexColumnWidth(1.8),
            4: pw.FlexColumnWidth(1.05),
          },
          children: tableRows,
        ),
      ],
    ),
  ));
}

void _addGam3eyaInvoicePage({
  required pw.Document doc,
  required pw.ThemeData theme,
  required pw.Font regular,
  required pw.Font bold,
  required pw.Font latinFallback,
  required String title,
  required String subtitle,
  required List<InvoiceRow> rows,
}) {
  final total = rows.fold<double>(0, (sum, r) => sum + r.debit);
  final paid = rows.fold<double>(0, (sum, r) => sum + r.credit);
  final currency = rows.isEmpty ? '' : rows.first.currency;

  final tableRows = <pw.TableRow>[
    pw.TableRow(children: [
      _cell('الحالة', bold, latinFallback, center: true, fontSize: 11, padding: 6),
      _cell('المبلغ', bold, latinFallback, center: true, fontSize: 11, padding: 6),
      _cell('البيان', bold, latinFallback, center: true, fontSize: 11, padding: 6),
    ]),
    ...rows.map((r) => pw.TableRow(children: [
      _cell(r.credit > 0 ? 'مدفوع' : 'غير مدفوع', regular, latinFallback, center: true, fontSize: 11, padding: 6),
      _cell('${fmtNum(r.debit)} ${r.currency}'.trim(), regular, latinFallback, center: true, fontSize: 11, padding: 6),
      _cell('${r.details} - ${r.date}', regular, latinFallback, center: true, fontSize: 11, padding: 6),
    ])),
    pw.TableRow(children: [
      _cell('', regular, latinFallback, center: true, fontSize: 12, padding: 6),
      _cell('${fmtNum(total)} $currency'.trim(), bold, latinFallback, center: true, fontSize: 12, padding: 6),
      _cell('الإجمالي', bold, latinFallback, center: true, fontSize: 12, padding: 6),
    ]),
    pw.TableRow(children: [
      _cell('', regular, latinFallback, center: true, fontSize: 12, padding: 6),
      _cell('${fmtNum(paid)} $currency'.trim(), bold, latinFallback, center: true, fontSize: 12, padding: 6),
      _cell('المدفوع', bold, latinFallback, center: true, fontSize: 12, padding: 6),
    ]),
  ];

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(14, 14, 14, 16),
    theme: theme,
    textDirection: pw.TextDirection.rtl,
    build: (context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(title, textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: bold, fontSize: 17, fontFallback: [latinFallback])),
        pw.SizedBox(height: 2),
        pw.Text(subtitle, textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: regular, fontSize: 11, fontFallback: [latinFallback])),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFD8CFB0), width: 0.65),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.95),
            1: pw.FlexColumnWidth(1.0),
            2: pw.FlexColumnWidth(2.3),
          },
          children: tableRows,
        ),
      ],
    ),
  ));
}

pw.Widget _cell(String text, pw.Font font, pw.Font latinFallback, {
  bool center = false,
  PdfColor? textColor,
  double fontSize = 11,
  double padding = 7,
}) {
  return pw.Padding(
    padding: pw.EdgeInsets.all(padding),
    child: pw.Text(
      text,
      textAlign: center ? pw.TextAlign.center : pw.TextAlign.right,
      textDirection: pw.TextDirection.rtl,
      style: pw.TextStyle(font: font, fontSize: fontSize, color: textColor, fontFallback: [latinFallback]),
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

Future<void> shareInvoiceViaWhatsApp(Uint8List bytes, String filename, String text) async {
  final file = await savePdfToTemp(bytes, filename);
  await Share.shareXFiles([XFile(file.path)], text: text);
}
