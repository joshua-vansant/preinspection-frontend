import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class VehicleService {
  static Future<Map<String, dynamic>?> getLastInspectionForVehicle(
    String token,
    int vehicleId,
  ) async {
    final Uri url = Uri.parse(
      '${ApiConfig.baseUrl}/inspections/last/$vehicleId',
    );

    final response = await http.get(
      url,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 404) {
      // No inspections for this vehicle
      return null;
    } else {
      throw Exception(
        'Failed to fetch last inspection for vehicle $vehicleId: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getVehicles(String token) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vehicles/');

    final response = await http.get(
      url,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();
    } else if (response.statusCode == 400) {
      throw Exception('Failed to fetch vehicles: ${response.body}');
    } else {
      throw Exception(
        'Failed to fetch vehicles: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> getVehicleById(
    String token,
    int vehicleId,
  ) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vehicles/$vehicleId');

    final response = await http.get(
      url,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to fetch vehicle $vehicleId: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> addVehicle({
    required String token,
    required String licensePlate,
    String? number,
    String? make,
    String? model,
    int? year,
    String? vin,
    int? mileage,
    String? status,
    int? orgId, // only for admin
  }) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vehicles/add');

    final body = {
      'license_plate': licensePlate,
      if (number != null) 'number': number,
      if (make != null) 'make': make,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      if (vin != null) 'vin': vin,
      if (mileage != null) 'mileage': mileage,
      if (status != null) 'status': status,
      if (orgId != null) 'org_id': orgId,
    };

    final response = await http.post(
      url,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final vehicleData = jsonDecode(response.body)['vehicle'];
      return Map<String, dynamic>.from(vehicleData);
    } else {
      throw Exception(
        'Failed to add vehicle: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> updateVehicle({
    required String token,
    required int vehicleId,
    String? number,
    String? make,
    String? model,
    int? year,
    String? vin,
    String? licensePlate,
    int? mileage,
    String? status,
    int? orgId,
  }) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vehicles/$vehicleId');

    final body = {
      if (number != null) 'number': number,
      if (make != null) 'make': make,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      if (vin != null) 'vin': vin,
      if (licensePlate != null) 'license_plate': licensePlate,
      if (mileage != null) 'mileage': mileage,
      if (status != null) 'status': status,
      if (orgId != null) 'org_id': orgId,
    };

    final response = await http.put(
      url,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final vehicleData = jsonDecode(response.body)['vehicle'];
      return Map<String, dynamic>.from(vehicleData);
    } else {
      throw Exception(
        'Failed to update vehicle: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<void> deleteVehicle(String token, int vehicleId) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vehicles/$vehicleId');

    final response = await http.delete(
      url,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete vehicle: ${response.statusCode} ${response.body}',
      );
    }
  }
}
