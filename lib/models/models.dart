class Section {
  final int id;
  final String name;
  final String type; // gam3eya / individual

  Section({required this.id, required this.name, required this.type});

  factory Section.fromJson(Map<String, dynamic> j) => Section(
        id: int.parse(j['id'].toString()),
        name: j['name'].toString(),
        type: j['type'].toString(),
      );
}

class ScheduleItem {
  final int id;
  final int monthIdx;
  final String dueDate;
  final double amount;
  final bool paid;

  ScheduleItem({
    required this.id,
    required this.monthIdx,
    required this.dueDate,
    required this.amount,
    required this.paid,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> j) => ScheduleItem(
        id: int.parse(j['id'].toString()),
        monthIdx: int.parse(j['month_idx'].toString()),
        dueDate: j['due_date'].toString(),
        amount: double.parse(j['amount'].toString()),
        paid: j['paid'].toString() == '1',
      );
}

class Gam3eya {
  final int id;
  final int? sectionId;
  final String name;
  final String startDate;
  final int months;
  final double monthlyAmount;
  final String currency;
  final List<ScheduleItem> schedule;

  Gam3eya({
    required this.id,
    required this.sectionId,
    required this.name,
    required this.startDate,
    required this.months,
    required this.monthlyAmount,
    required this.currency,
    required this.schedule,
  });

  double get total => schedule.fold(0.0, (a, s) => a + s.amount);
  int get paidCount => schedule.where((s) => s.paid).length;
  double get paidTotal =>
      schedule.where((s) => s.paid).fold(0.0, (a, s) => a + s.amount);

  factory Gam3eya.fromJson(Map<String, dynamic> j) => Gam3eya(
        id: int.parse(j['id'].toString()),
        sectionId:
            j['section_id'] == null ? null : int.parse(j['section_id'].toString()),
        name: j['name'].toString(),
        startDate: j['start_date'].toString(),
        months: int.parse(j['months'].toString()),
        monthlyAmount: double.parse(j['monthly_amount'].toString()),
        currency: j['currency'].toString(),
        schedule: (j['schedule'] as List)
            .map((s) => ScheduleItem.fromJson(s))
            .toList(),
      );
}

class Entry {
  final int id;
  final String note;
  final double amount;
  final String type; // debit / credit
  final String entryDate;

  Entry({
    required this.id,
    required this.note,
    required this.amount,
    required this.type,
    required this.entryDate,
  });

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: int.parse(j['id'].toString()),
        note: (j['note'] ?? '').toString(),
        amount: double.parse(j['amount'].toString()),
        type: j['type'].toString(),
        entryDate: j['entry_date'].toString(),
      );
}

class Individual {
  final int id;
  final int? sectionId;
  final String name;
  final String phone;
  final String currency;
  final List<Entry> entries;

  Individual({
    required this.id,
    required this.sectionId,
    required this.name,
    required this.phone,
    required this.currency,
    required this.entries,
  });

  double get total => entries.fold(
      0.0, (a, e) => a + (e.type == 'debit' ? e.amount : -e.amount));

  factory Individual.fromJson(Map<String, dynamic> j) => Individual(
        id: int.parse(j['id'].toString()),
        sectionId:
            j['section_id'] == null ? null : int.parse(j['section_id'].toString()),
        name: j['name'].toString(),
        phone: (j['phone'] ?? '').toString(),
        currency: j['currency'].toString(),
        entries:
            (j['entries'] as List).map((e) => Entry.fromJson(e)).toList(),
      );
}
