import 'package:http/http.dart' as http;

/// HTTP client used by the app. Kept in a separate file so networking
/// configuration can be improved later without changing ApiService.
http.Client buildResilientHttpClient() => http.Client();
