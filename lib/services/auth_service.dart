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

    if (response.statusCode != 200) {
      throw Exception('Failed to login: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception("Unexpected response format: ${response.body}");
    }

    final user = decoded['user'] as Map<String, dynamic>;
    final org = user['org'] as Map<String, dynamic>?;

    return {
      "access_token": decoded['access_token'],
      "refresh_token": decoded['refresh_token'],
      "expires_in": decoded['expires_in'],
      "user": user,
      "org": org,
    };
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
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/register"),
      headers: ApiConfig.headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('Registration failed: $error');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception("Unexpected response format: ${response.body}");
    }

    final user = decoded['user'] as Map<String, dynamic>;
    final org = user['org'] as Map<String, dynamic>?;

    return {
      "access_token": decoded['access_token'],
      "refresh_token": decoded['refresh_token'],
      "expires_in": decoded['expires_in'],
      "user": user,
      "org": org,
    };
  }

  static Future<Map<String, dynamic>> refreshToken(String oldToken) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/refresh"),
      headers: {...ApiConfig.headers(), 'Authorization': 'Bearer $oldToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to refresh token: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception("Unexpected response format: ${response.body}");
    }

    return decoded;
  }

  static Future<void> logout(String token) async {
    try {
      await http.post(
        Uri.parse("${ApiConfig.baseUrl}/auth/logout"),
        headers: {...ApiConfig.headers(), 'Authorization': 'Bearer $token'},
      );
    } catch (_) {
      // ignore network errors on logout
    }
  }
}
