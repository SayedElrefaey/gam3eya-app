import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/models.dart';
import '../invoice_helper.dart';
import 'gam3eyas_tab.dart' show cover, gold;
import 'individual_detail_screen.dart';

class IndividualsTab extends StatefulWidget {
  final Section section;
  const IndividualsTab({super.key, required this.section});
  @override
  State<IndividualsTab> createState() => _IndividualsTabState();
}

class _IndividualsTabState extends State<IndividualsTab> {
  List<Individual> _all = [];
  String? _error;
  bool _loading = true;

  List<Individual> get _items =>
      _all.where((p) => p.sectionId == widget.section.id).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant IndividualsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.id != widget.section.id) _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.getIndividuals();
      if (mounted) setState(() { _all = list; _error = null; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openAddForm() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String currency = 'EGP';
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إضافة ${widget.section.name} جديد', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف (واتساب)', border: OutlineInputBorder())),
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
                    if (nameCtrl.text.trim().isEmpty) {
                      setSt(() => error = 'من فضلك أدخل اسم الفرد');
                      return;
                    }
                    try {
                      await ApiService.addIndividual(
                          sectionId: widget.section.id, name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim(), currency: currency);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    } catch (e) {
                      setSt(() => error = e.toString());
                    }
                  },
                  child: const Text('حفظ'),
                )),
              ]),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _edit(Individual p) async {
    final nameCtrl = TextEditingController(text: p.name);
    final phoneCtrl = TextEditingController(text: p.phone);
    String currency = p.currency;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('تعديل بيانات الفرد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder())),
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: cover, foregroundColor: gold),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    setSt(() => error = 'الاسم مطلوب');
                    return;
                  }
                  try {
                    await ApiService.updateIndividual(
                        id: p.id, name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim(), currency: currency);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (e) {
                    setSt(() => error = e.toString());
                  }
                },
                child: const Text('حفظ'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _delete(Individual p) async {
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
        await ApiService.deleteIndividual(p.id);
        _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _quickAddEntry(Individual p) async {
    final noteCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'debit';
    DateTime date = DateTime.now();
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إضافة حركة - ${p.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                  DropdownMenuItem(value: 'debit', child: Text('مستحق (عليه)')),
                  DropdownMenuItem(value: 'credit', child: Text('تم تحصيله (له)')),
                ],
                onChanged: (v) => setSt(() => type = v ?? 'debit'),
              ),
              if (error != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: cover, foregroundColor: gold),
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text) ?? 0;
                  if (amount <= 0) { setSt(() => error = 'من فضلك أدخل مبلغ صحيح'); return; }
                  final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  try {
                    await ApiService.addEntry(individualId: p.id, note: noteCtrl.text.trim(), amount: amount, type: type, date: dateStr);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (e) {
                    setSt(() => error = e.toString());
                  }
                },
                child: const Text('حفظ الحركة'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    double sumDebit = 0, sumCredit = 0;
    for (final p in items) {
      if (p.total > 0) {
        sumDebit += p.total;
      } else {
        sumCredit += -p.total;
      }
    }
    final net = sumDebit - sumCredit;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddForm,
        backgroundColor: cover,
        foregroundColor: gold,
        icon: const Icon(Icons.add),
        label: Text('إضافة ${widget.section.name}'),
      ),
      bottomNavigationBar: (items.isEmpty || _error != null || _loading)
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFEDEDED),
                border: Border(top: BorderSide(color: Color(0xFFD8CFB0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('له: ${fmtNum(sumCredit)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('عليه: ${fmtNum(sumDebit)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('الرصيد ${net >= 0 ? 'عليه' : 'له'}: ${fmtNum(net.abs())}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ],
              ),
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? ListView(children: [Padding(padding: const EdgeInsets.all(30), child: Text(_error!, textAlign: TextAlign.center))])
            : _loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? ListView(children: [
                        Padding(padding: const EdgeInsets.all(40), child: Text('لا يوجد ${widget.section.name} بعد\nأضف عنصر وسجل حسابه', textAlign: TextAlign.center))
                      ])
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8, right: 4),
                              child: Text('${items.length} 👥',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1279C6), fontSize: 14)),
                            ),
                          ),
                          ...items.map((p) {
                            final isDebit = p.total > 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFD8CFB0)),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  await Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => IndividualDetailScreen(id: p.id)));
                                  _load();
                                },
                                child: Row(children: [
                                  Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDebit ? const Color(0xFFE05252) : const Color(0xFF3CB878),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(isDebit ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text('${fmtNum(p.total.abs())} ${currencySymbols[p.currency] ?? p.currency}',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                  Stack(clipBehavior: Clip.none, children: [
                                    IconButton(
                                      icon: const Icon(Icons.note_add, color: Color(0xFF1279C6)),
                                      onPressed: () => _quickAddEntry(p),
                                    ),
                                    Positioned(
                                      top: 2, left: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(color: const Color(0xFF29ABE2), borderRadius: BorderRadius.circular(8)),
                                        child: Text('${p.entries.length}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ]),
                                  IconButton(icon: const Icon(Icons.edit, size: 19, color: cover), onPressed: () => _edit(p)),
                                  IconButton(icon: const Icon(Icons.delete, size: 19, color: Colors.red), onPressed: () => _delete(p)),
                                ]),
                              ),
                            );
                          }),
                        ],
                      ),
      ),
    );
  }
}
