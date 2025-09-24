import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class VehicleService {
  /// Fetches the list of vehicles for the authenticated driver
  static Future<List<Map<String, dynamic>>> getVehicles(String token) async {
    final url = Uri.parse('${ApiConfig.baseUrl}vehicles'); // uses ApiConfig baseUrl

    final response = await http.get(
      url,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception('Failed to fetch vehicles: ${response.statusCode} ${response.body}');
    }
  }
}
