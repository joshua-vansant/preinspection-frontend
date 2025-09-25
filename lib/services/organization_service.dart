import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class OrganizationService {
  static Future<Map<String, dynamic>> joinOrg(String token, String inviteCode) async {
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

  static Future<Map<String, dynamic>?> getMyOrg(String token) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/organizations/me');
    final response = await http.get(
      url,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null; // no org joined
    } else {
      throw Exception("Failed to fetch organization: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> leaveOrg(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/organizations/leave'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to leave organization: ${response.statusCode} ${response.body}');
    }
  }
}
