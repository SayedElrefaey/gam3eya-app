import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/models.dart';
import 'login_screen.dart';
import 'gam3eyas_tab.dart';
import 'individuals_tab.dart';
import 'section_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Section> _sections = [];
  int? _activeId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.getSections();
      if (!mounted) return;
      setState(() {
        _sections = list;
        if (_activeId == null || !list.any((s) => s.id == _activeId)) {
          _activeId = list.isNotEmpty ? list.first.id : null;
        }
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _openSection(Section section) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SectionScreen(section: section)),
    );
    await _load();
  }

  Future<void> _openTabsManager() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFBF7EC),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 16, left: 16, right: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('إدارة التبويبات', textAlign: TextAlign.right, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: cover)),
                const SizedBox(height: 12),
                if (_sections.isEmpty)
                  const Padding(padding: EdgeInsets.all(12), child: Text('لا توجد تبويبات بعد', textAlign: TextAlign.center))
                else
                  ..._sections.map((s) => Card(
                        child: ListTile(
                          title: Text(s.name, textAlign: TextAlign.right),
                          subtitle: Text(
                            s.type == 'gam3eya'
                                ? 'نوع: جمعيات${s.hasTurns ? ' • الأدوار مفعلة' : ''}'
                                : 'نوع: حسابات أفراد',
                            textAlign: TextAlign.right,
                          ),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: cover),
                              onPressed: () async {
                                final nameCtrl = TextEditingController(text: s.name);
                                bool? hasTurns = s.type == 'gam3eya' ? s.hasTurns : null;
                                final res = await showDialog<Map<String, dynamic>>(
                                  context: ctx,
                                  builder: (dctx) => StatefulBuilder(builder: (dctx, setSt2) {
                                    return AlertDialog(
                                      title: const Text('تعديل التبويب'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(controller: nameCtrl, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'اسم التبويب')),
                                          if (s.type == 'gam3eya') ...[
                                            const SizedBox(height: 12),
                                            SwitchListTile.adaptive(
                                              contentPadding: EdgeInsets.zero,
                                              title: const Text('تفعيل الأدوار', textAlign: TextAlign.right),
                                              subtitle: const Text('إظهار وتحديد دورك في كل جمعية', textAlign: TextAlign.right),
                                              value: hasTurns ?? false,
                                              activeColor: gold,
                                              onChanged: (v) => setSt2(() => hasTurns = v),
                                            ),
                                          ],
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('إلغاء')),
                                        ElevatedButton(onPressed: () => Navigator.pop(dctx, {'name': nameCtrl.text.trim(), 'hasTurns': hasTurns}), child: const Text('حفظ')),
                                      ],
                                    );
                                  }),
                                );
                                nameCtrl.dispose();
                                if (res != null && (res['name'] as String).isNotEmpty) {
                                  await ApiService.renameSection(s.id, res['name'] as String, hasTurns: res['hasTurns'] as bool?);
                                  await _load();
                                  setSt(() {});
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: ctx,
                                  builder: (dctx) => AlertDialog(
                                    title: const Text('حذف التبويب'),
                                    content: Text('هل تريد حذف هذا التبويب؟ هيتحذف معاه ${s.type == 'gam3eya' ? 'كل الجمعيات اللي جواه' : 'كل الأفراد اللي جواه'}.', textAlign: TextAlign.right),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('إلغاء')),
                                      TextButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await ApiService.deleteSection(s.id);
                                  await _load();
                                  setSt(() {});
                                }
                              },
                            ),
                          ]),
                        ),
                      )),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: cover, foregroundColor: gold, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () async {
                    final nameCtrl = TextEditingController();
                    String type = 'gam3eya';
                    bool hasTurns = true;
                    String? error;
                    final created = await showDialog<bool>(
                      context: ctx,
                      builder: (dctx) => StatefulBuilder(builder: (dctx, setSt2) {
                        return AlertDialog(
                          title: const Text('إضافة تبويب جديد'),
                          content: Column(mainAxisSize: MainAxisSize.min, children: [
                            TextField(controller: nameCtrl, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'اسم التبويب')),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: type,
                              decoration: const InputDecoration(labelText: 'نوع التبويب'),
                              items: const [
                                DropdownMenuItem(value: 'gam3eya', child: Text('جمعيات (بتواريخ وأقساط)')),
                                DropdownMenuItem(value: 'individual', child: Text('حسابات أفراد')),
                              ],
                              onChanged: (v) => setSt2(() => type = v ?? 'gam3eya'),
                            ),
                            if (type == 'gam3eya') ...[
                              const SizedBox(height: 10),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('تفعيل الأدوار', textAlign: TextAlign.right),
                                subtitle: const Text('إظهار خانة تحديد دورك داخل الجمعية', textAlign: TextAlign.right),
                                value: hasTurns,
                                activeColor: gold,
                                onChanged: (v) => setSt2(() => hasTurns = v),
                              ),
                            ],
                            if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.right)),
                          ]),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('إلغاء')),
                            ElevatedButton(
                              onPressed: () async {
                                if (nameCtrl.text.trim().isEmpty) { setSt2(() => error = 'الاسم مطلوب'); return; }
                                try {
                                  final id = await ApiService.createSection(nameCtrl.text.trim(), type, hasTurns: type == 'gam3eya' && hasTurns);
                                  _activeId = id;
                                  if (dctx.mounted) Navigator.pop(dctx, true);
                                } catch (e) {
                                  setSt2(() => error = e.toString());
                                }
                              },
                              child: const Text('حفظ'),
                            ),
                          ],
                        );
                      }),
                    );
                    nameCtrl.dispose();
                    if (created == true) {
                      await _load();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة تبويب جديد'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر الجمعيات والحسابات'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), tooltip: 'إدارة التبويبات', onPressed: _openTabsManager),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'خروج (${ApiService.username ?? ''})', onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: cover,
                  child: _sections.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 80),
                          const Icon(Icons.menu_book_outlined, size: 60, color: gold),
                          const SizedBox(height: 14),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('مفيش أقسام لسه', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cover))),
                          const SizedBox(height: 10),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 80), child: ElevatedButton.icon(onPressed: _openTabsManager, icon: const Icon(Icons.add), label: const Text('إضافة قسم'))),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
                          itemCount: _sections.length,
                          itemBuilder: (ctx, index) {
                            final section = _sections[index];
                            final isGam3eya = section.type == 'gam3eya';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Color(0xFFD8CFB0)),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _openSection(section),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.chevron_left, color: gold, size: 30),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Text(section.name, textAlign: TextAlign.right, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: cover)),
                                            const SizedBox(height: 4),
                                            Text(
                                              isGam3eya ? 'جمعيات وتحصيل الأقساط' : 'حسابات أفراد وحركات مالية',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B6248)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: isGam3eya ? const Color(0xFFF2ECDA) : const Color(0xFFE3F0EA),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(isGam3eya ? Icons.groups_outlined : Icons.person_outline, color: cover, size: 27),
                                      ),
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
}
