import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/models.dart';
import '../invoice_helper.dart';
import 'gam3eyas_tab.dart' show cover, gold;

String _fmtDate(String isoDate) {
  final d = DateTime.parse(isoDate);
  return '${d.day}/${d.month}/${d.year}';
}

class Gam3eyaDetailScreen extends StatefulWidget {
  final int id;
  const Gam3eyaDetailScreen({super.key, required this.id});
  @override
  State<Gam3eyaDetailScreen> createState() => _Gam3eyaDetailScreenState();
}

class _Gam3eyaDetailScreenState extends State<Gam3eyaDetailScreen> {
  Gam3eya? _g;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.getGam3eyas();
      final g = list.firstWhere((x) => x.id == widget.id);
      if (mounted) setState(() { _g = g; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _togglePaid(int scheduleId) async {
    try {
      await ApiService.togglePaid(scheduleId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _sendInvoice() async {
    final g = _g!;
    final sym = currencySymbols[g.currency] ?? g.currency;

    double runningBalance = 0;
    double totalDebit = 0;
    double totalCredit = 0;
    final rows = <InvoiceRow>[];

    for (final s in g.schedule) {
      final debit = s.amount;
      final credit = s.paid ? s.amount : 0.0;
      runningBalance += debit - credit;
      totalDebit += debit;
      totalCredit += credit;

      rows.add(InvoiceRow(
        date: _fmtDate(s.dueDate),
        details: 'شهر ${s.monthIdx}',
        debit: debit,
        credit: credit,
        balance: runningBalance,
        currency: sym,
      ));
    }

    final totals = [
      MapEntry('${fmtNum(totalDebit)} $sym', 'إجمالي عليه'),
      MapEntry('${fmtNum(totalCredit)} $sym', 'إجمالي له'),
      MapEntry('${fmtNum(runningBalance.abs())} $sym', 'الرصيد الإجمالي'),
    ];

    final bytes = await buildInvoicePdf(
      title: 'فاتورة جمعية',
      subtitle: g.name,
      rows: rows,
      totals: totals,
    );

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('طباعة / حفظ PDF'),
              onTap: () async {
                Navigator.pop(ctx);
                await previewInvoicePdf(bytes, 'فاتورة ${g.name}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('إرسال عبر واتساب / مشاركة'),
              onTap: () async {
                Navigator.pop(ctx);
                await shareInvoiceViaWhatsApp(
                  bytes,
                  'فاتورة ${g.name}',
                  'فاتورة ${g.name} - الرصيد: ${fmtNum(runningBalance.abs())} $sym',
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الجمعية'),
        content: const Text('هل تريد حذف هذه الجمعية؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.deleteGam3eya(widget.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));
    if (_g == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final g = _g!;
    final sym = currencySymbols[g.currency] ?? g.currency;

    return Scaffold(
      appBar: AppBar(title: Text(g.name)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(children: [
              _statCard('القسط الشهري', '${fmtNum(g.monthlyAmount)} $sym'),
              _statCard('الإجمالي', '${fmtNum(g.total)} $sym'),
              _statCard('المدفوع', '${g.paidCount}/${g.months}'),
            ]),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: g.schedule.map((s) {
                  return ListTile(
                    tileColor: s.paid ? const Color(0xFFDCF0E3) : null,
                    leading: CircleAvatar(child: Text('${s.monthIdx}')),
                    title: Text(_fmtDate(s.dueDate)),
                    subtitle: Text('${fmtNum(s.amount)} $sym'),
                    trailing: s.paid
                        ? TextButton(
                            onPressed: () => _togglePaid(s.id),
                            child: const Text('✓ تم السداد — تراجع'))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: cover),
                            onPressed: () => _togglePaid(s.id),
                            child: const Text('دفع'),
                          ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sendInvoice,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('فاتورة PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete),
                  label: const Text('حذف'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF2ECDA), borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.brown)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
      );
}
