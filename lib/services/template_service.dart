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

  static Future<Map<String, dynamic>> createTemplate({
    required String token,
    required String name,
    required List<Map<String, String>> items,
    bool isDefault = false,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/templates/create");

    final response = await http.post(
      url,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({
        "name": name,
        "items": items,
        "is_default": isDefault,
      }),
      );

      if(response.statusCode == 201){
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw Exception('Failed to create template: $error');
      }
  }

  static Future<void> updateTemplate({
  required String token,
  required int id,
  required String name,
  required List<Map<String, String>> items,
  required bool isDefault,
}) async {
  final response = await http.put(
    Uri.parse("${ApiConfig.baseUrl}/templates/$id/edit"),
    headers: ApiConfig.headers(token: token),
    body: jsonEncode({
      "name": name,
      "items": items,
      "is_default": isDefault,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to update template: ${response.body}");
  }
}

static Future<void> deleteTemplate(String token, int templateId) async {
  final response = await http.delete(
    Uri.parse("${ApiConfig.baseUrl}/templates/$templateId/delete"),
    headers: ApiConfig.headers(token: token)
  );

  if(response.statusCode != 200) {
    throw Exception('Failed to delete template: ${response.body}');
  }
}
}
