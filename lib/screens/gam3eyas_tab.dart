import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/models.dart';
import '../invoice_helper.dart';
import 'gam3eya_detail_screen.dart';

const cover = Color(0xFF12332A);
const gold = Color(0xFFC9962C);

class Gam3eyasTab extends StatefulWidget {
  final Section section;
  const Gam3eyasTab({super.key, required this.section});
  @override
  State<Gam3eyasTab> createState() => _Gam3eyasTabState();
}

class _Gam3eyasTabState extends State<Gam3eyasTab> {
  List<Gam3eya> _all = [];
  String? _error;
  bool _loading = true;

  List<Gam3eya> get _items =>
      _all.where((g) => g.sectionId == widget.section.id).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant Gam3eyasTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.id != widget.section.id) _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.getGam3eyas();
      if (mounted) setState(() { _all = list; _error = null; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openAddForm() async {
    final nameCtrl = TextEditingController();
    final monthsCtrl = TextEditingController(text: '12');
    final amountCtrl = TextEditingController();
    DateTime? startDate;
    String currency = 'EGP';
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('إضافة ${widget.section.name} جديد',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(controller: nameCtrl, textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'اسم الجمعية', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(startDate == null
                      ? 'اختر تاريخ البداية'
                      : '${startDate!.day}/${startDate!.month}/${startDate!.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100));
                    if (d != null) setSt(() => startDate = d);
                  },
                ),
                TextField(controller: monthsCtrl, textAlign: TextAlign.right, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'عدد الشهور', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: amountCtrl, textAlign: TextAlign.right, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'مبلغ القسط الشهري', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: currency,
                  decoration: const InputDecoration(labelText: 'العملة', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'EGP', child: Text('جنيه مصري (ج.م)')),
                    DropdownMenuItem(value: 'USD', child: Text('دولار (\$)')),
                  ],
                  onChanged: (v) => setSt(() => currency = v ?? 'EGP'),
                ),
                if (error != null)
                  Padding(padding: const EdgeInsets.only(top: 8),
                      child: Text(error!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: cover, foregroundColor: gold),
                    onPressed: () async {
                      final months = int.tryParse(monthsCtrl.text) ?? 0;
                      final amount = double.tryParse(amountCtrl.text) ?? 0;
                      if (nameCtrl.text.trim().isEmpty || startDate == null || months < 1 || amount <= 0) {
                        setSt(() => error = 'من فضلك أكمل جميع الحقول بشكل صحيح');
                        return;
                      }
                      try {
                        await ApiService.addGam3eya(
                          sectionId: widget.section.id,
                          name: nameCtrl.text.trim(),
                          startDate:
                              '${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}',
                          months: months,
                          monthlyAmount: amount,
                          currency: currency,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      } catch (e) {
                        setSt(() => error = e.toString());
                      }
                    },
                    child: const Text('حفظ الجمعية'),
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

  Future<void> _rename(Gam3eya g) async {
    final ctrl = TextEditingController(text: g.name);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل اسم الجمعية'),
        content: TextField(controller: ctrl, textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('حفظ')),
        ],
      ),
    );
    if (res != null && res.isNotEmpty) {
      try {
        await ApiService.renameGam3eya(g.id, res);
        _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _delete(Gam3eya g) async {
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
        await ApiService.deleteGam3eya(g.id);
        _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddForm,
        backgroundColor: cover,
        foregroundColor: gold,
        icon: const Icon(Icons.add),
        label: Text('إضافة ${widget.section.name}'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? ListView(children: [Padding(padding: const EdgeInsets.all(30), child: Text(_error!, textAlign: TextAlign.center))])
            : _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? ListView(children: [
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text('لا يوجد ${widget.section.name} بعد\nابدأ بإضافة أول ${widget.section.name}', textAlign: TextAlign.center),
                        )
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final g = _items[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              onTap: () async {
                                await Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => Gam3eyaDetailScreen(id: g.id)));
                                _load();
                              },
                              title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${g.months} شهر · مدفوع ${g.paidCount}/${g.months}'),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                Chip(label: Text(currencySymbols[g.currency] ?? g.currency)),
                                IconButton(icon: const Icon(Icons.edit, color: cover), onPressed: () => _rename(g)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(g)),
                              ]),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
