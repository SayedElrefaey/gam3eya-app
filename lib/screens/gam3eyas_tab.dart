import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/models.dart';
import 'gam3eya_detail_screen.dart';

const cover = Color(0xFF12332A);
const gold = Color(0xFFC9962C);
const _paper = Color(0xFFFBF7EC);
const _paper2 = Color(0xFFF2ECDA);
const _line = Color(0xFFD8CFB0);
const _turnBlue = Color(0xFF3B54C9);
const _turnLight = Color(0xFFE3E9FA);

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

  List<Gam3eya> get _items => _all.where((g) => g.sectionId == widget.section.id).toList();

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
      if (mounted) {
        setState(() {
          _all = list;
          _error = null;
          _loading = false;
        });
      }
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
    final selectedTurns = <int>{};
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final months = int.tryParse(monthsCtrl.text) ?? 0;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('إضافة ${widget.section.name} جديد', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cover), textAlign: TextAlign.right),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'اسم الجمعية', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: monthsCtrl,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'عدد الشهور', border: OutlineInputBorder()),
                    onChanged: (_) => setSt(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'مبلغ القسط الشهري', border: OutlineInputBorder()),
                  ),
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
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      startDate == null ? 'اختر تاريخ البداية' : '${startDate!.day}/${startDate!.month}/${startDate!.year}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: cover, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: gold),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setSt(() => startDate = d);
                    },
                  ),
                  if (widget.section.hasTurns && months > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _turnLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _turnBlue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('تحديد أدوارك (اختياري)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2E6B))),
                          const SizedBox(height: 6),
                          const Text('اختار الشهور التي يكون دورك فيها', style: TextStyle(fontSize: 12, color: Color(0xFF1E2E6B))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: List.generate(months, (i) {
                              final m = i + 1;
                              final selected = selectedTurns.contains(m);
                              return FilterChip(
                                selected: selected,
                                label: Text('شهر $m'),
                                selectedColor: _turnBlue,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF1E2E6B), fontWeight: FontWeight.bold),
                                onSelected: (v) => setSt(() => v ? selectedTurns.add(m) : selectedTurns.remove(m)),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (error != null)
                    Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.right)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء'))),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: cover, foregroundColor: gold),
                      onPressed: () async {
                        final m = int.tryParse(monthsCtrl.text) ?? 0;
                        final amount = double.tryParse(amountCtrl.text) ?? 0;
                        if (nameCtrl.text.trim().isEmpty || startDate == null || m < 1 || amount <= 0) {
                          setSt(() => error = 'من فضلك أكمل جميع الحقول بشكل صحيح');
                          return;
                        }
                        try {
                          await ApiService.addGam3eya(
                            sectionId: widget.section.id,
                            name: nameCtrl.text.trim(),
                            startDate: '${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}',
                            months: m,
                            monthlyAmount: amount,
                            currency: currency,
                            myTurnMonths: selectedTurns.where((x) => x <= m).toList()..sort(),
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
        },
      ),
    );

    nameCtrl.dispose();
    monthsCtrl.dispose();
    amountCtrl.dispose();
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
    ctrl.dispose();
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
      backgroundColor: _paper,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddForm,
        backgroundColor: cover,
        foregroundColor: gold,
        icon: const Icon(Icons.add),
        label: Text('إضافة ${widget.section.name}'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: cover,
        child: _error != null
            ? ListView(children: [Padding(padding: const EdgeInsets.all(30), child: Text(_error!, textAlign: TextAlign.center))])
            : _loading
                ? const Center(child: CircularProgressIndicator(color: cover))
                : _items.isEmpty
                    ? ListView(children: [const SizedBox(height: 60), Padding(padding: EdgeInsets.all(30), child: Text('لا توجد جمعيات بعد\nابدأ بإضافة أول جمعية', textAlign: TextAlign.center, style: TextStyle(color: cover, fontSize: 16, fontWeight: FontWeight.w600)))] )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 90),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final g = _items[i];
                          final total = g.total;
                          final paid = g.paidTotal;
                          final remaining = total - paid;
                          final turnsText = g.myTurns.isEmpty ? 'الدور غير محدد' : 'دورك: ${g.myTurns.join(', ')}';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _line)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => Gam3eyaDetailScreen(id: g.id)));
                                _load();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text(g.name, textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cover))),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _paper2, borderRadius: BorderRadius.circular(20), border: Border.all(color: _line)), child: Text(currencySymbols[g.currency] ?? g.currency, style: const TextStyle(fontWeight: FontWeight.bold, color: cover))),
                                    ]),
                                    const SizedBox(height: 7),
                                    Text('${g.months} شهر  •  مدفوع ${g.paidCount}/${g.months}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Color(0xFF6B6248))),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Expanded(child: _infoBox('القسط الشهري', '${fmtNum(g.monthlyAmount)} ${currencySymbols[g.currency] ?? g.currency}')),
                                      const SizedBox(width: 8),
                                      Expanded(child: _infoBox('المتبقي', '${fmtNum(remaining)} ${currencySymbols[g.currency] ?? g.currency}')),
                                    ]),
                                    if (widget.section.hasTurns) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(color: _turnLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: _turnBlue)),
                                        child: Row(children: [
                                          const Icon(Icons.star, size: 18, color: _turnBlue),
                                          const SizedBox(width: 6),
                                          Expanded(child: Text(turnsText, textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF1E2E6B), fontWeight: FontWeight.bold, fontSize: 12))),
                                        ]),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Expanded(child: OutlinedButton.icon(onPressed: () => _rename(g), icon: const Icon(Icons.edit, size: 18), label: const Text('تعديل'))),
                                      const SizedBox(width: 8),
                                      Expanded(child: OutlinedButton.icon(onPressed: () => _delete(g), icon: const Icon(Icons.delete, size: 18, color: Colors.red), label: const Text('حذف', style: TextStyle(color: Colors.red)))),
                                    ]),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: _paper2, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B6248))),
        const SizedBox(height: 3),
        Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cover)),
      ]),
    );
  }
}
