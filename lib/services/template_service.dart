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
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load templates: ${response.body}');
    }
  }
}
