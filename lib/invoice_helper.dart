import 'dart:typed_data';
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
  final String label;
  final String amount;
  final String? status;
  InvoiceRow(this.label, this.amount, [this.status]);
}

Future<Uint8List> buildInvoicePdf({
  required String title,
  required String subtitle,
  required List<InvoiceRow> rows,
  required List<MapEntry<String, String>> totals,
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 14),
          pw.Table(
            border: pw.TableBorder(
                horizontalInside:
                    const pw.BorderSide(color: PdfColors.grey400)),
            children: [
              pw.TableRow(children: [
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('الحالة',
                        style:
                            pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('المبلغ',
                        style:
                            pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('البيان',
                        style:
                            pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ]),
              ...rows.map((r) => pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(r.status ?? '')),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(r.amount)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(r.label)),
                  ])),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(thickness: 1.5),
          ...totals.map((t) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(t.value,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 13)),
                    pw.Text(t.key,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    ),
  );
  return doc.save();
}

Future<File> savePdfToTemp(Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename.pdf');
  await file.writeAsBytes(bytes);
  return file;
}

/// يفتح شاشة معاينة/طباعة النظام (زي الويب) لحفظ الملف يدويًا
Future<void> previewInvoicePdf(Uint8List bytes, String filename) async {
  await Printing.layoutPdf(onLayout: (format) async => bytes, name: filename);
}

/// يفتح قائمة المشاركة في أندرويد (فيها واتساب) ويرفق ملف الـ PDF مباشرة
Future<void> shareInvoiceViaWhatsApp(
    Uint8List bytes, String filename, String text) async {
  final file = await savePdfToTemp(bytes, filename);
  await Share.shareXFiles([XFile(file.path)], text: text);
}
