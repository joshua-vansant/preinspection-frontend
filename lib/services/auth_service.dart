import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
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

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    final body = {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
    };
    if (phoneNumber != null) body['phone_number'] = phoneNumber;

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/register"),
      headers: ApiConfig.headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception("Unexpected response format: ${response.body}");
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception(error);
    }
  }
}
