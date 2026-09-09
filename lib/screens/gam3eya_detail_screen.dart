import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/models.dart';
import '../invoice_helper.dart';
import 'gam3eyas_tab.dart' show cover, gold;

const _paper = Color(0xFFFBF7EC);
const _paper2 = Color(0xFFF2ECDA);
const _line = Color(0xFFD8CFB0);
const _success = Color(0xFF2F6B4F);
const _successLight = Color(0xFFDCF0E3);
const _turnBlue = Color(0xFF3B54C9);
const _turnLight = Color(0xFFE3E9FA);
const _danger = Color(0xFFA3402F);

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

  Future<void> _showTurnForm() async {
    final g = _g!;
    final selected = g.myTurns.toSet();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 18, right: 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تحديد أدوارك', textAlign: TextAlign.right, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cover)),
                const SizedBox(height: 6),
                const Text('اختار كل الشهور اللي هي دورك في الجمعية', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Color(0xFF6B6248))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: List.generate(g.months, (i) {
                    final m = i + 1;
                    final isSelected = selected.contains(m);
                    return FilterChip(
                      selected: isSelected,
                      label: Text('شهر $m'),
                      selectedColor: _turnBlue,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E2E6B), fontWeight: FontWeight.bold),
                      onSelected: (v) => setSt(() => v ? selected.add(m) : selected.remove(m)),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: cover, foregroundColor: gold),
                    onPressed: () async {
                      try {
                        await ApiService.setMyTurns(widget.id, selected.toList()..sort());
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _load();
                      } catch (e) {
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                    child: const Text('حفظ الأدوار'),
                  )),
                ]),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
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
      rows.add(InvoiceRow(date: _fmtDate(s.dueDate), details: 'شهر ${s.monthIdx}', debit: debit, credit: credit, balance: runningBalance, currency: sym));
    }
    final bytes = await buildInvoicePdf(
      title: 'فاتورة جمعية',
      subtitle: g.name,
      rows: rows,
      totals: [
        MapEntry('${fmtNum(totalDebit)} $sym', 'إجمالي عليه'),
        MapEntry('${fmtNum(totalCredit)} $sym', 'إجمالي له'),
        MapEntry('${fmtNum(runningBalance.abs())} $sym', 'الرصيد الإجمالي'),
      ],
    );
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.print), title: const Text('طباعة / حفظ PDF'), onTap: () async { Navigator.pop(ctx); await previewInvoicePdf(bytes, 'فاتورة ${g.name}'); }),
            ListTile(leading: const Icon(Icons.share), title: const Text('إرسال عبر واتساب / مشاركة'), onTap: () async { Navigator.pop(ctx); await shareInvoiceViaWhatsApp(bytes, 'فاتورة ${g.name}', 'فاتورة ${g.name} - الرصيد: ${fmtNum(runningBalance.abs())} $sym'); }),
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
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: _danger))),
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
    if (_error != null) return Scaffold(appBar: AppBar(backgroundColor: cover), body: Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_error!, textAlign: TextAlign.center))));
    if (_g == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final g = _g!;
    final sym = currencySymbols[g.currency] ?? g.currency;
    final total = g.total;
    final paid = g.paidTotal;
    final remaining = total - paid;
    final turnsText = g.myTurns.isEmpty ? 'الدور غير محدد' : 'دورك: ${g.myTurns.join(', ')}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _paper,
        appBar: AppBar(backgroundColor: cover, foregroundColor: Colors.white, title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)), actions: [
          PopupMenuButton<String>(
            onSelected: (v) { if (v == 'invoice') _sendInvoice(); if (v == 'delete') _delete(); },
            itemBuilder: (_) => const [PopupMenuItem(value: 'invoice', child: Text('فاتورة PDF')), PopupMenuItem(value: 'delete', child: Text('حذف الجمعية'))],
          ),
        ]),
        body: RefreshIndicator(
          onRefresh: _load,
          color: cover,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 22),
            children: [
              Row(children: [
                _statCard('القسط الشهري', '${fmtNum(g.monthlyAmount)} $sym'),
                _statCard('الإجمالي', '${fmtNum(total)} $sym'),
                _statCard('المدفوع', '${g.paidCount}/${g.months}'),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _statCard('المتبقي', '${fmtNum(remaining)} $sym')),
                if (g.myTurns.isNotEmpty || true) Expanded(child: _turnCard(turnsText)),
              ]),
              const SizedBox(height: 12),
              if (g.myTurns.isNotEmpty || true) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _showTurnForm,
                    icon: const Icon(Icons.star, color: _turnBlue),
                    label: Text(g.myTurns.isEmpty ? 'تحديد أدوارك' : 'تعديل أدوارك'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: _line)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                    decoration: const BoxDecoration(color: cover, borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
                    child: const Row(children: [
                      Expanded(flex: 8, child: Text('#', textAlign: TextAlign.center, style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 16))),
                      Expanded(flex: 20, child: Text('التاريخ', textAlign: TextAlign.center, style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 16))),
                      Expanded(flex: 22, child: Text('المبلغ', textAlign: TextAlign.center, style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 16))),
                      Expanded(flex: 25, child: Text('الحالة', textAlign: TextAlign.center, style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 16))),
                    ]),
                  ),
                  ...g.schedule.map((s) {
                    final isTurn = g.myTurns.contains(s.monthIdx);
                    return Container(
                      color: isTurn ? _turnLight : (s.paid ? _successLight : Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5),
                      child: Row(children: [
                        Expanded(flex: 8, child: Text('${s.monthIdx}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, color: cover, fontSize: 15))),
                        Expanded(flex: 20, child: Text(_fmtDate(s.dueDate), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: cover, fontSize: 15))),
                        Expanded(flex: 22, child: Text('${fmtNum(s.amount)} $sym', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: isTurn ? const Color(0xFF1E2E6B) : cover, fontSize: 15))),
                        Expanded(flex: 25, child: FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          if (s.paid)
                            TextButton(onPressed: () => _togglePaid(s.id), child: const Text('✓ تم السداد — تراجع', style: TextStyle(color: _success, fontWeight: FontWeight.bold)))
                          else
                            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: cover), onPressed: () => _togglePaid(s.id), child: const Text('دفع')),
                          if (isTurn) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.star, color: _turnBlue, size: 18)),
                        ]))),
                      ]),
                    );
                  }),
                ]),
              ),
              const SizedBox(height: 12),
              _summaryBox(g, sym),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _sendInvoice, icon: const Icon(Icons.picture_as_pdf), label: const Text('فاتورة PDF'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: _showTurnForm, icon: const Icon(Icons.star, color: _turnBlue), label: const Text('الأدوار'))),
              ]),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _paper2, borderRadius: BorderRadius.circular(9), border: Border.all(color: _line)),
          child: Column(children: [
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF6B6248))),
            const SizedBox(height: 4),
            Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: cover)),
          ]),
        ),
      );

  Widget _turnCard(String text) => Expanded(
        child: InkWell(
          onTap: _showTurnForm,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _turnLight, borderRadius: BorderRadius.circular(9), border: Border.all(color: _turnBlue)),
            child: Column(children: [
              const Text('أدوارك', style: TextStyle(fontSize: 11, color: Color(0xFF1E2E6B))),
              const SizedBox(height: 4),
              Text(text, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E2E6B))),
            ]),
          ),
        ),
      );

  Widget _summaryBox(Gam3eya g, String sym) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: BoxDecoration(color: _paper2, border: Border.all(color: _line), borderRadius: BorderRadius.circular(9)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('إجمالي الأقساط: ${fmtNum(g.total)} $sym', style: const TextStyle(fontSize: 16, color: cover, fontWeight: FontWeight.w700)),
            Text('المدفوع: ${fmtNum(g.paidTotal)} $sym', style: const TextStyle(fontSize: 16, color: _success, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 5),
          Text('المتبقي: ${fmtNum(g.total - g.paidTotal)} $sym', style: const TextStyle(fontSize: 18, color: cover, fontWeight: FontWeight.w900)),
        ]),
      );
}
