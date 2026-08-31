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
                        Padding(padding: const EdgeInsets.all(40), child: Text('لا يوجد ${widget.section.name} بعد\nأضف عنصر وسجل حسابه', textAlign: TextAlign.center))
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final p = _items[i];
                          final sym = currencySymbols[p.currency] ?? p.currency;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              onTap: () async {
                                await Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => IndividualDetailScreen(id: p.id)));
                                _load();
                              },
                              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${p.phone.isEmpty ? 'بدون رقم هاتف' : p.phone} · الإجمالي ${fmtNum(p.total)} $sym'),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                Chip(label: Text(sym)),
                                IconButton(icon: const Icon(Icons.edit, color: cover), onPressed: () => _edit(p)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(p)),
                              ]),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
