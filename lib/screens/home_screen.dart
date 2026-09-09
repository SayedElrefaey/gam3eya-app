import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/models.dart';
import 'login_screen.dart';
import 'gam3eyas_tab.dart';
import 'individuals_tab.dart';

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
    Section? active;
    if (_activeId != null) {
      try { active = _sections.firstWhere((s) => s.id == _activeId); } catch (_) { active = null; }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر الجمعيات والحسابات'),
        actions: [IconButton(icon: const Icon(Icons.logout), tooltip: 'خروج (${ApiService.username ?? ''})', onPressed: _logout)],
      ),
      body: Column(
        children: [
          Container(
            color: cover,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _sections.map((s) {
                    final isActive = s.id == _activeId;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Material(
                        color: isActive ? gold : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => _activeId = s.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            child: Text(s.name, style: TextStyle(color: isActive ? cover : Colors.white.withOpacity(0.75), fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ),
                    );
                  }).toList()),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: Colors.white.withOpacity(0.08),
                shape: const CircleBorder(),
                child: IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _openTabsManager),
              ),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
                    : _sections.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const Text('مفيش تبويبات لسه', textAlign: TextAlign.center),
                                const SizedBox(height: 10),
                                ElevatedButton(onPressed: _openTabsManager, child: const Text('إضافة أول تبويب')),
                              ]),
                            ),
                          )
                        : active == null
                            ? const SizedBox.shrink()
                            : active.type == 'gam3eya'
                                ? Gam3eyasTab(section: active)
                                : IndividualsTab(section: active),
          ),
        ],
      ),
    );
  }
}
