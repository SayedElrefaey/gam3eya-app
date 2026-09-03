import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/models.dart';
import '../invoice_helper.dart';
import 'gam3eyas_tab.dart' show cover, gold;

const _ledgerHeader = Color(0xFF08A8D8);
const _ledgerDebit = Color(0xFFE87B73);
const _ledgerCredit = Color(0xFF91D98B);
const _ledgerSummary = Color(0xFFC9D9E1);
const _ledgerBlue = Color(0xFF1414A0);

class IndividualDetailScreen extends StatefulWidget {
  final int id;
  const IndividualDetailScreen({super.key, required this.id});
  @override
  State<IndividualDetailScreen> createState() => _IndividualDetailScreenState();
}

class _IndividualDetailScreenState extends State<IndividualDetailScreen> {
  Individual? _p;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.getIndividuals();
      final p = list.firstWhere((x) => x.id == widget.id);
      if (mounted) setState(() { _p = p; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _openEntryForm({Entry? existing}) async {
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    final amountCtrl = TextEditingController(text: existing != null ? existing.amount.toString() : '');
    String type = existing?.type ?? 'debit';
    DateTime date = existing != null ? DateTime.parse(existing.entryDate) : DateTime.now();
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(existing != null ? 'تعديل الحركة' : 'إضافة حركة على الحساب',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(controller: noteCtrl, textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: amountCtrl, textAlign: TextAlign.right, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'نوع الحركة', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'debit', child: Text('مستحق (إضافة)')),
                    DropdownMenuItem(value: 'credit', child: Text('تم تحصيله (خصم)')),
                  ],
                  onChanged: (v) => setSt(() => type = v ?? 'debit'),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${date.day}/${date.month}/${date.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (d != null) setSt(() => date = d);
                  },
                ),
                if (error != null)
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: cover, foregroundColor: gold),
                    onPressed: () async {
                      final amount = double.tryParse(amountCtrl.text) ?? 0;
                      if (amount <= 0) { setSt(() => error = 'من فضلك أدخل مبلغ صحيح'); return; }
                      final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      try {
                        if (existing != null) {
                          await ApiService.updateEntry(id: existing.id, note: noteCtrl.text.trim(), amount: amount, type: type, date: dateStr);
                        } else {
                          await ApiService.addEntry(individualId: widget.id, note: noteCtrl.text.trim(), amount: amount, type: type, date: dateStr);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      } catch (e) {
                        setSt(() => error = e.toString());
                      }
                    },
                    child: Text(existing != null ? 'حفظ التعديل' : 'حفظ الحركة'),
                  )),
                ]),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _deleteEntry(int id) async {
    try {
      await ApiService.deleteEntry(id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفرد'),
        content: const Text('هل تريد حذف هذا الفرد وكل حساباته؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.deleteIndividual(widget.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _sendInvoice() async {
    final p = _p!;
    final sym = currencySymbols[p.currency] ?? p.currency;

    final entries = [...p.entries]
      ..sort((a, b) {
        final da = DateTime.parse(a.entryDate);
        final db = DateTime.parse(b.entryDate);
        final cmp = da.compareTo(db);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });

    double runningBalance = 0;
    double totalDebit = 0;
    double totalCredit = 0;
    final rows = <InvoiceRow>[];

    for (final e in entries) {
      final dt = DateTime.parse(e.entryDate);
      final isDebit = e.type == 'debit';
      final debit = isDebit ? e.amount : 0.0;
      final credit = isDebit ? 0.0 : e.amount;

      runningBalance += debit - credit;
      totalDebit += debit;
      totalCredit += credit;

      rows.add(InvoiceRow(
        date: _formatDateTime(dt),
        details: e.note.isEmpty ? 'حركة' : e.note,
        debit: debit,
        credit: credit,
        balance: runningBalance,
        currency: sym,
      ));
    }

    final totals = [
      MapEntry('${fmtNum(runningBalance.abs())} $sym', 'الرصيد الإجمالي'),
      MapEntry('${fmtNum(totalDebit)} $sym', 'إجمالي عليه'),
      MapEntry('${fmtNum(totalCredit)} $sym', 'إجمالي له'),
    ];

    final bytes = await buildInvoicePdf(
      title: 'فاتورة حساب',
      subtitle: p.name,
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
                await previewInvoicePdf(bytes, 'فاتورة ${p.name}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('إرسال عبر واتساب / مشاركة'),
              onTap: () async {
                Navigator.pop(ctx);
                await shareInvoiceViaWhatsApp(
                  bytes,
                  'فاتورة ${p.name}',
                  'فاتورة ${p.name} - الرصيد: ${fmtNum(runningBalance.abs())} $sym',
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));
    if (_p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = _p!;
    final sym = currencySymbols[p.currency] ?? p.currency;

    final sorted = [...p.entries]
      ..sort((a, b) {
        final da = DateTime.parse(a.entryDate);
        final db = DateTime.parse(b.entryDate);
        final cmp = db.compareTo(da);
        return cmp != 0 ? cmp : b.id.compareTo(a.id);
      });

    final chronological = [...p.entries]
      ..sort((a, b) {
        final da = DateTime.parse(a.entryDate);
        final db = DateTime.parse(b.entryDate);
        final cmp = da.compareTo(db);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });

    final balances = <int, double>{};
    double running = 0;
    double totalDebit = 0;
    double totalCredit = 0;
    for (final e in chronological) {
      if (e.type == 'debit') {
        running += e.amount;
        totalDebit += e.amount;
      } else {
        running -= e.amount;
        totalCredit += e.amount;
      }
      balances[e.id] = running;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: _ledgerHeader,
          foregroundColor: Colors.white,
          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
          elevation: 2,
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'invoice') _sendInvoice();
                if (value == 'delete') _delete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'invoice', child: Text('فاتورة PDF')),
                PopupMenuItem(value: 'delete', child: Text('حذف الفرد')),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          color: _ledgerHeader,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 18),
            children: [
              Row(
                children: [
                  _quickAction(Icons.arrow_forward, 'حركة', () => _openEntryForm()),
                  _quickAction(Icons.add_circle_outline, 'إضافة', () => _openEntryForm()),
                  _quickAction(Icons.table_rows, 'تفاصيل', () {}),
                  _quickAction(Icons.attach_money, sym, () {}),
                ],
              ),
              const SizedBox(height: 12),
              _ledgerHeaderRow(),
              const SizedBox(height: 4),
              if (sorted.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Text('لا توجد حركات مسجلة', textAlign: TextAlign.center),
                )
              else
                ...sorted.map((e) {
                  final isDebit = e.type == 'debit';
                  final amountColor = isDebit ? _ledgerDebit : _ledgerCredit;
                  final balance = balances[e.id] ?? 0;
                  final balanceColor = balance >= 0 ? _ledgerDebit : _ledgerCredit;
                  final dt = DateTime.parse(e.entryDate);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ledgerCell(
                          _formatDateTime(dt),
                          flex: 16,
                          background: Colors.white,
                          textColor: Colors.black,
                          fontSize: 13,
                        ),
                        _ledgerCell(
                          e.note.isEmpty ? 'حركة' : e.note,
                          flex: 13,
                          background: Colors.white,
                          textColor: Colors.black,
                          fontSize: 15,
                        ),
                        _ledgerCell(
                          fmtNum(e.amount),
                          flex: 10,
                          background: amountColor,
                          textColor: Colors.black,
                          fontSize: 18,
                          bold: true,
                        ),
                        _ledgerCell(
                          fmtNum(balance),
                          flex: 10,
                          background: balanceColor,
                          textColor: Colors.black,
                          fontSize: 18,
                          bold: true,
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 8),
              _summaryBox(totalDebit, totalCredit, running, sym),
              const SizedBox(height: 62),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openEntryForm(),
          backgroundColor: _ledgerHeader,
          foregroundColor: Colors.white,
          child: const Icon(Icons.note_add),
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7F9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2EDF0)),
                ),
                child: Icon(icon, color: _ledgerHeader, size: 36),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _ledgerHeaderRow() {
    return Row(
      children: [
        _ledgerHeaderCell('التاريخ', 16),
        _ledgerHeaderCell('التفاصيل', 13),
        _ledgerHeaderCell('المبلغ', 10),
        _ledgerHeaderCell('الرصيد', 10),
      ],
    );
  }

  Widget _ledgerHeaderCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _ledgerHeader,
          borderRadius: BorderRadius.circular(4),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _ledgerCell(
    String text, {
    required int flex,
    required Color background,
    required Color textColor,
    double fontSize = 16,
    bool bold = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _summaryBox(double totalDebit, double totalCredit, double balance, String sym) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: _ledgerSummary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('عليه: ${fmtNum(totalDebit)}', style: const TextStyle(fontSize: 18)),
              Text('له: ${fmtNum(totalCredit)}', style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'الرصيد عليه: ${fmtNum(balance.abs())} $sym'.trim(),
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hasTime = dt.hour != 0 || dt.minute != 0;
    if (!hasTime) return '$y-$m-$d';
    return '$y-$m-$d ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
