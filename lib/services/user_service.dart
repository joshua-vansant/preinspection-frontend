import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class UserService {
  static Future<Map<String, dynamic>> updateUser(
    String token,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/users/update');

    final response = await http.put(
      url,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonBody['user'] as Map<String, dynamic>;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to update user');
    }
  }
}
