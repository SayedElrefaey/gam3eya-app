import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'resilient_http.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  // رابط السيرفر مثبّت هنا مرة واحدة - عدّله لو غيّرت الدومين مستقبلًا
  static const String defaultServerUrl = 'https://invoice.oxserver.net/api.php';

  static String? baseUrl;
  static String? token;
  static String? username;
  static final http.Client _client = buildResilientHttpClient();

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // نفرض الرابط الثابت دايمًا، عشان نمسح أي قيمة قديمة غلط اتخزنت قبل كده
    baseUrl = defaultServerUrl;
    await prefs.setString('baseUrl', defaultServerUrl);
    token = prefs.getString('token');
    username = prefs.getString('username');
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (baseUrl != null) await prefs.setString('baseUrl', baseUrl!);
    if (token != null) await prefs.setString('token', token!);
    if (username != null) await prefs.setString('username', username!);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
    token = null;
    username = null;
  }

  static bool get isLoggedIn => token != null && baseUrl != null;

  static Uri _uri(String endpoint, [Map<String, String>? extra]) {
    final params = {'endpoint': endpoint, ...?extra};
    return Uri.parse(baseUrl!).replace(queryParameters: params);
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<Map<String, dynamic>> _decode(http.Response res) async {
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      final preview = res.body.length > 300 ? res.body.substring(0, 300) : res.body;
      throw ApiException(
          'استجابة غير متوقعة من السيرفر (كود ${res.statusCode}):\n$preview');
    }
    if (res.statusCode >= 400) {
      throw ApiException(data['error']?.toString() ?? 'حدث خطأ');
    }
    return data;
  }

  static Future<void> login(String user, String pass) async {
    baseUrl = defaultServerUrl;
    final res = await _client.post(
      _uri('login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': user, 'password': pass}),
    );
    final data = await _decode(res);
    token = data['token'].toString();
    username = data['username'].toString();
    await _persist();
  }

  static Future<void> logout() async {
    try {
      await _client.post(_uri('logout_token'), headers: _headers);
    } catch (_) {}
    await clearSession();
  }

  // ---------------- Sections ----------------

  static Future<List<Section>> getSections() async {
    final res = await _client.get(_uri('sections'), headers: _headers);
    if (res.statusCode >= 400) await _decode(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Section.fromJson(e)).toList();
  }

  static Future<int> createSection(String name, String type) async {
    final res = await _client.post(
      _uri('sections'),
      headers: _headers,
      body: jsonEncode({'name': name, 'type': type}),
    );
    final data = await _decode(res);
    return int.parse(data['id'].toString());
  }

  static Future<void> renameSection(int id, String name) async {
    final res = await _client.put(
      _uri('sections'),
      headers: _headers,
      body: jsonEncode({'id': id, 'name': name}),
    );
    await _decode(res);
  }

  static Future<void> deleteSection(int id) async {
    final res = await _client.delete(
      _uri('sections', {'id': '$id'}),
      headers: _headers,
    );
    await _decode(res);
  }

  // ---------------- Gam3eyas ----------------

  static Future<List<Gam3eya>> getGam3eyas() async {
    final res = await _client.get(_uri('gam3eyas'), headers: _headers);
    if (res.statusCode >= 400) await _decode(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Gam3eya.fromJson(e)).toList();
  }

  static Future<void> addGam3eya({
    required int sectionId,
    required String name,
    required String startDate,
    required int months,
    required double monthlyAmount,
    required String currency,
  }) async {
    final res = await _client.post(
      _uri('gam3eyas'),
      headers: _headers,
      body: jsonEncode({
        'sectionId': sectionId,
        'name': name,
        'startDate': startDate,
        'months': months,
        'monthlyAmount': monthlyAmount,
        'currency': currency,
      }),
    );
    await _decode(res);
  }

  static Future<void> renameGam3eya(int id, String name) async {
    final res = await _client.put(
      _uri('gam3eyas'),
      headers: _headers,
      body: jsonEncode({'id': id, 'name': name}),
    );
    await _decode(res);
  }

  static Future<void> deleteGam3eya(int id) async {
    final res = await _client.delete(
      _uri('gam3eyas', {'id': '$id'}),
      headers: _headers,
    );
    await _decode(res);
  }

  static Future<void> togglePaid(int scheduleId) async {
    final res = await _client.post(
      _uri('toggle_paid'),
      headers: _headers,
      body: jsonEncode({'id': scheduleId}),
    );
    await _decode(res);
  }

  // ---------------- Individuals ----------------

  static Future<List<Individual>> getIndividuals() async {
    final res = await _client.get(_uri('individuals'), headers: _headers);
    if (res.statusCode >= 400) await _decode(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Individual.fromJson(e)).toList();
  }

  static Future<void> addIndividual({
    required int sectionId,
    required String name,
    required String phone,
    required String currency,
  }) async {
    final res = await _client.post(
      _uri('individuals'),
      headers: _headers,
      body: jsonEncode({
        'sectionId': sectionId,
        'name': name,
        'phone': phone,
        'currency': currency,
      }),
    );
    await _decode(res);
  }

  static Future<void> updateIndividual({
    required int id,
    required String name,
    required String phone,
    required String currency,
  }) async {
    final res = await _client.put(
      _uri('individuals'),
      headers: _headers,
      body: jsonEncode(
          {'id': id, 'name': name, 'phone': phone, 'currency': currency}),
    );
    await _decode(res);
  }

  static Future<void> deleteIndividual(int id) async {
    final res = await _client.delete(
      _uri('individuals', {'id': '$id'}),
      headers: _headers,
    );
    await _decode(res);
  }

  static Future<void> addEntry({
    required int individualId,
    required String note,
    required double amount,
    required String type,
    required String date,
  }) async {
    final res = await _client.post(
      _uri('entries'),
      headers: _headers,
      body: jsonEncode({
        'individualId': individualId,
        'note': note,
        'amount': amount,
        'type': type,
        'date': date,
      }),
    );
    await _decode(res);
  }

  static Future<void> updateEntry({
    required int id,
    required String note,
    required double amount,
    required String type,
    required String date,
  }) async {
    final res = await _client.put(
      _uri('entries'),
      headers: _headers,
      body: jsonEncode({
        'id': id,
        'note': note,
        'amount': amount,
        'type': type,
        'date': date,
      }),
    );
    await _decode(res);
  }

  static Future<void> deleteEntry(int id) async {
    final res = await _client.delete(
      _uri('entries', {'id': '$id'}),
      headers: _headers,
    );
    await _decode(res);
  }
}
