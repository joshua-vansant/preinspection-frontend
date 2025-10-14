import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart'; // <-- add this for MIME type detection
import '../config/api_config.dart';

class InspectionPhotoService {
  /// Uploads a photo for a given inspection, or caches it if inspectionId is null.
  static Future<Map<String, dynamic>> uploadPhoto({
    int? inspectionId,
    required String token,
    required File photoFile,
    int? inspectionItemId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/inspections/upload-photo');

    // Detect MIME type based on file extension
    final mimeType = lookupMimeType(photoFile.path) ?? 'image/jpeg';
    final mimeParts = mimeType.split('/'); // ['image', 'jpeg']

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(ApiConfig.headers(token: token))
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          photoFile.path,
          contentType: mimeParts.length == 2
              ? MediaType(mimeParts[0], mimeParts[1])
              : null,
        ),
      );

    // Send inspectionId if provided
    if (inspectionId != null) {
      request.fields['inspection_id'] = inspectionId.toString();
    }

    // Send inspectionItemId if provided
    if (inspectionItemId != null) {
      request.fields['inspection_item_id'] = inspectionItemId.toString();
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
