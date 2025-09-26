import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TemplateService {
  /// Fetch all templates for the current organization
  static Future<List<Map<String, dynamic>>> getTemplates(String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/templates/"),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      final error = _parseError(response.body);
      throw Exception('Failed to load templates: $error');
    }
  }

  /// Fetch a single template by ID
  static Future<Map<String, dynamic>> getTemplate(String token, int id) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/templates/$id"),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      final error = _parseError(response.body);
      throw Exception('Failed to fetch template: $error');
    }
  }

  /// Create a new template
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
      final error = _parseError(response.body);
      throw Exception('Failed to create template: $error');
    }
  }

  /// Update an existing template
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
      final error = _parseError(response.body);
      throw Exception("Failed to update template: $error");
    }
  }

  /// Delete a template
  static Future<void> deleteTemplate(String token, int templateId) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/templates/$templateId/delete"),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode != 200) {
      final error = _parseError(response.body);
      throw Exception('Failed to delete template: $error');
    }
  }

  /// Private helper to safely parse error messages
  static String _parseError(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic> && decoded.containsKey('error')) {
        return decoded['error'];
      }
      return responseBody;
    } catch (_) {
      return responseBody;
    }
  }
}
