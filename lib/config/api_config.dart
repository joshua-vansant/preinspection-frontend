class ApiConfig {
  static const String baseUrl = 'https://preinspection-api.onrender.com/';

  // Returns standard headers, optionally with auth token
  static Map<String, String> headers({String? token}) {
    final baseHeaders = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      baseHeaders['Authorization'] = 'Bearer $token';
    }
    return baseHeaders;
  }
}
