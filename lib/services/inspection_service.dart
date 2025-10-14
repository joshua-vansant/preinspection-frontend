import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:flutter/material.dart';

class InspectionService {
  static Future<Map<String, dynamic>> submitInspection(
    String token,
    Map<String, dynamic> inspection,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/inspections/submit'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(inspection),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to submit inspection: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>?> getLastInspection(
    String token,
    int vehicleId,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/inspections/last/$vehicleId');

    final response = await http.get(
      url,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      return null; // no prior inspection
    } else {
      throw Exception(
        'Failed to fetch last inspection: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getInspectionHistory(
    String token,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/inspections/history');

    final response = await http.get(
      url,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      throw Exception(
        'Failed to fetch inspection history: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> getInspectionById(
    int id,
    String token,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/inspections/$id');

    final response = await http.get(
      url,
      headers: ApiConfig.headers(token: token),
    );
    debugPrint(
      'DEBUG: Response from inspectionService.getInspectionById ${response}',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to fetch inspection by ID: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<void> updateInspection(
    int inspectionId,
    String token,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/inspections/$inspectionId');

    final response = await http.put(
      url,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({
        'template_id': data['template_id'],
        'vehicle_id': data['vehicle_id'],
        'type': data['type'],
        'results': data['results'],
        'notes': data['notes'],
        'start_mileage': data['start_mileage'],
        'fuel_level': data['fuel_level'],
        'fuel_notes': data['fuel_notes'],
        'odometer_verified': data['odometer_verified'],
      }),
    );

    debugPrint('DEBUG: PUT URL: $url');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update inspection: ${response.statusCode} ${response.body}',
      );
    }

    debugPrint("DEBUG: Inspection updated successfully: ${response.body}");
  }

  // Delete an inspection by ID (admin only)
  static Future<void> deleteInspection(int inspectionId, String token) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/inspections/$inspectionId');
    final response = await http.delete(
      url,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete inspection: ${response.statusCode} ${response.body}',
      );
    }

    debugPrint("DEBUG: Inspection deleted successfully");
  }

  static Future<Map<String, dynamic>> startInspection({
    required String token,
    required int vehicleId,
    required String type,
    int? orgId,
    int? templateId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/inspections/start');
    final response = await http.post(
      url,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({
        'vehicle_id': vehicleId,
        'type': type,
        'org_id': orgId,
        if (templateId != null) "template_id": templateId,
      }),
    );

    print("DEBUG: templateID in service ${templateId}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start inspection: ${response.body}');
    }
  }
}
