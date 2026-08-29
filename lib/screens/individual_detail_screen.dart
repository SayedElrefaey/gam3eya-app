import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/models.dart';
import '../invoice_helper.dart';
import 'gam3eyas_tab.dart' show cover, gold;

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
    final d = DateTime.now();
    final rows = p.entries.map((e) {
      final dt = DateTime.parse(e.entryDate);
      final sign = e.type == 'debit' ? '' : '-';
      return InvoiceRow('${e.note.isEmpty ? 'حركة' : e.note} - ${dt.day}/${dt.month}/${dt.year}', '$sign${fmtNum(e.amount)} $sym');
    }).toList();
    final totals = [MapEntry('${fmtNum(p.total)} $sym', 'الإجمالي المستحق')];
    final bytes = await buildInvoicePdf(title: 'فاتورة حساب', subtitle: p.name, rows: rows, totals: totals);

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
                await shareInvoiceViaWhatsApp(bytes, 'فاتورة ${p.name}',
                    'فاتورة ${p.name} - الإجمالي: ${fmtNum(p.total)} $sym');
              },
            ),
          ]),
        ),
      ),
    );
    // ignore unused var warning
    // ignore: unnecessary_statements
    d;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));
    if (_p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = _p!;
    final sym = currencySymbols[p.currency] ?? p.currency;

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntryForm(),
        backgroundColor: cover,
        foregroundColor: gold,
        icon: const Icon(Icons.add),
        label: const Text('حركة'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(children: [
              _statCard('الإجمالي المستحق', '${fmtNum(p.total)} $sym'),
              _statCard('عدد الحركات', '${p.entries.length}'),
            ]),
            const SizedBox(height: 16),
            if (p.entries.isEmpty)
              const Padding(padding: EdgeInsets.all(20), child: Text('لا توجد حركات مسجلة', textAlign: TextAlign.center))
            else
              Card(
                child: Column(
                  children: p.entries.map((e) {
                    final dt = DateTime.parse(e.entryDate);
                    final isDebit = e.type == 'debit';
                    return ListTile(
                      title: Text(e.note.isEmpty ? 'حركة' : e.note),
                      subtitle: Text('${dt.day}/${dt.month}/${dt.year}'),
                      leading: Text(
                        '${isDebit ? '' : '-'}${fmtNum(e.amount)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDebit ? const Color(0xFF1E4A34) : Colors.red),
                      ),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit, size: 20, color: cover), onPressed: () => _openEntryForm(existing: e)),
                        IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _deleteEntry(e.id)),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _sendInvoice, icon: const Icon(Icons.picture_as_pdf), label: const Text('فاتورة PDF'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: _delete,
                icon: const Icon(Icons.delete),
                label: const Text('حذف الفرد'),
              )),
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
