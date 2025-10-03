import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:frontend/utils/ui_helpers.dart';

class TemplateService {
  static Future<List<Map<String, dynamic>>> getTemplates(String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/templates/"),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      final error = UIHelpers.parseError(response.body);
      throw Exception('Failed to load templates: $error');
    }
  }

  static Future<Map<String, dynamic>> getTemplate(String token, int id) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/templates/$id"),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      final error = UIHelpers.parseError(response.body);
      throw Exception('Failed to fetch template: $error');
    }
  }

  static Future<Map<String, dynamic>> createTemplate({
    required String token,
    required String name,
    required List<Map<String, dynamic>> items,
    bool isDefault = false,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/templates/create"),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({"name": name, "items": items, "is_default": isDefault}),
    );

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      final error = UIHelpers.parseError(response.body);
      throw Exception('Failed to create template: $error');
    }
  }

  static Future<Map<String, dynamic>> updateTemplate({
    required String token,
    required int id,
    required String name,
    required List<Map<String, dynamic>> items,
    required bool isDefault,
  }) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/templates/$id/edit"),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({"name": name, "items": items, "is_default": isDefault}),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      final error = UIHelpers.parseError(response.body);
      throw Exception("Failed to update template: $error");
    }
  }

  static Future<void> deleteTemplate(String token, int templateId) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/templates/$templateId/delete"),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode != 200) {
      final error = UIHelpers.parseError(response.body);
      throw Exception('Failed to delete template: $error');
    }
  }
}
