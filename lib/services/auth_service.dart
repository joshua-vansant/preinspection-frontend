import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/login"),
      headers: ApiConfig.headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception("Unexpected response format: ${response.body}");
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/register"),
      headers: ApiConfig.headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception("Unexpected response format: ${response.body}");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }
}
