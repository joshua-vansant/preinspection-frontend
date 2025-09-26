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

  static Future<String> getInviteCode(String token) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/organizations/code"),
      headers: ApiConfig.headers(token: token),
    );

    if(response.statusCode != 200){
      throw Exception("Failed to fetch invite code: ${response.body}");
    }

    final data = jsonDecode(response.body);
    return data["invite_code"] as String;
  }

  static Future<String> getNewCode(String token) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/organizations/code/regenerate"),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to regenerate invite code: ${response.body}");
    }

    final data = jsonDecode(response.body);
    return data["invite_code"];
  }

static Future<List<Map<String, dynamic>>> getAllUsers(String token) async {
  final url = Uri.parse('${ApiConfig.baseUrl}organizations/users');
  final response = await http.get(url, headers: ApiConfig.headers(token: token));

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List users = data['users'] as List? ?? [];
    return users.map<Map<String, dynamic>>((u) => Map<String, dynamic>.from(u)).toList();
  } else {
    throw Exception('Failed to fetch users: ${response.statusCode} ${response.body}');
  }
}


  static Future<Map<String, dynamic>> createOrg(
      String token, String name) async {
    final url = Uri.parse('${ApiConfig.baseUrl}organizations/create');

    final response = await http.post(
      url,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({"name": name}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'Failed to create organization: ${response.statusCode} ${response.body}');
    }
  }
}

