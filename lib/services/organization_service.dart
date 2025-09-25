import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class OrganizationService {
  static Future<Map<String, dynamic>> joinOrganization(String token, String inviteCode) async {
    final url = Uri.parse('${ApiConfig.baseUrl}organizations/join');

    final response = await http.post(
      url,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({"invite_code": inviteCode}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to join organization: ${response.statusCode} ${response.body}');
    }
  }
}
