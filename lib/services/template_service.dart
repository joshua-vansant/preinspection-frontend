import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TemplateService {
  static Future<List<Map<String, dynamic>>> getTemplates(String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/templates/"),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      throw Exception("Unexpected response format: ${response.body}");
    } else {
      throw Exception('Failed to fetch templates: ${response.body}');
    }
  }
}
