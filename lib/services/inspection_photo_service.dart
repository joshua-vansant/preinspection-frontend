import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class InspectionPhotoService {
  /// Uploads a photo for a given inspection, or caches it if inspectionId is null.
  static Future<Map<String, dynamic>> uploadPhoto({
    int? inspectionId,
    required String token,
    required File photoFile,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/inspections/upload-photo');

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(ApiConfig.headers(token: token))
      ..files.add(await http.MultipartFile.fromPath('file', photoFile.path));

    // Send inspectionId if provided
    if (inspectionId != null) {
      request.fields['inspection_id'] = inspectionId.toString();
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to upload photo: ${response.statusCode} ${response.body}',
      );
    }
  }
}
