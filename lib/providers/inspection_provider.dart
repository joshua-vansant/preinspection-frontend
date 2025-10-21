import 'dart:io';
import 'package:flutter/material.dart';
import '../services/inspection_service.dart';
import '../services/inspection_photo_service.dart';
import '../utils/ui_helpers.dart';
import 'auth_provider.dart';

class InspectionProvider extends ChangeNotifier {
  final AuthProvider authProvider;

  InspectionProvider({required this.authProvider});

  Map<String, dynamic> _currentInspection = {};
  List<Map<String, dynamic>> _inspectionPhotos = [];
  bool _isSubmitting = false;
  String _error = '';
  int? _inspectionId;
  int? get inspectionId => _inspectionId;

  Map<String, dynamic> get currentInspection => _currentInspection;
  List<Map<String, dynamic>> get inspectionPhotos => _inspectionPhotos;
  bool get isSubmitting => _isSubmitting;
  String get error => _error;

  // -------------------------
  // Start a new inspection draft
  // -------------------------
  Future<void> startInspection({
    required int vehicleId,
    required String type,
    Map<String, dynamic>? initialData,
    int? templateId,
    Map<String, dynamic>? template,
    Map<String, dynamic>? selectedVehicle,
  }) async {
    // If an inspection is lingering, clear it out before proceeding
    if (_inspectionId != null || _currentInspection.isNotEmpty) {
      debugPrint(
        "DEBUG: ⚠️ Found leftover inspection ($_inspectionId) — resetting before new start",
      );
      resetInspection();
    }

    // Build new inspection data AFTER any reset
    _currentInspection = {
      'vehicle_id': vehicleId,
      'type': type,
      'template_id': templateId ?? template?['id'],
      'start_mileage': null,
      'end_mileage': null,
      'fuel_level': 0.0,
      'fuel_notes': null,
      'odometer_verified': false,
      'results': {
        for (var item in template?['items'] ?? []) item['id'].toString(): "no",
      },
      'notes': null,
      'template_name': template?['name'] ?? 'Unknown',
      'template_items': template?['items'] ?? [],
      'org_id': authProvider.org?['id'] ?? selectedVehicle?['org_id'],
      if (initialData != null) ...initialData,
    };

    _inspectionPhotos = [];
    _error = '';
    notifyListeners();

    // Normal backend draft creation
    if (initialData == null) {
      final token = authProvider.token;
      if (token == null) {
        _error = 'Authentication token not available';
        notifyListeners();
        return;
      }

      final response = await InspectionService.startInspection(
        token: token,
        vehicleId: vehicleId,
        type: type,
        orgId: _currentInspection['org_id'],
        templateId: _currentInspection['template_id'],
      );

      debugPrint('DEBUG: startInspection response = $response');

      if (response.containsKey('inspection_id')) {
        _inspectionId = response['inspection_id'];

        // Merge data from server if needed
        if (response.containsKey('results')) {
          _currentInspection['results'] = response['results'];
        }
        if (response.containsKey('template_id')) {
          _currentInspection['template_id'] = response['template_id'];
        }

        notifyListeners();
      } else {
        _error = 'Backend did not return an inspection ID';
        notifyListeners();
      }
    }
  }

  // -------------------------
  // Update a field in the inspection
  // -------------------------
  void updateField(String key, dynamic value) {
    _currentInspection[key] = value;
    notifyListeners();
  }

  // -------------------------
  // Internal submit wrapper
  // -------------------------
  Future<bool> _submit(Future<void> Function() action) async {
    _isSubmitting = true;
    _error = '';
    notifyListeners();

    try {
      await action();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      final parsed = UIHelpers.parseError(e.toString());
      _error = parsed.isNotEmpty
          ? 'Failed to submit inspection: $parsed'
          : 'Failed to submit inspection';
      notifyListeners();
      return false;
    }
  }

  // -------------------------
  // Submit new inspection
  // -------------------------
  Future<bool> submitInspection() async {
    final token = authProvider.token;
    if (token == null) return false;

    return _submit(() async {
      // Ensure we have a valid draft first
      if (_inspectionId == null) {
        debugPrint(
          "DEBUG: ℹ️ No existing draft found — creating one before submit",
        );

        final startResponse = await InspectionService.startInspection(
          token: token,
          vehicleId: _currentInspection['vehicle_id'],
          type: _currentInspection['type'],
          orgId: _currentInspection['org_id'],
          templateId: _currentInspection['template_id'],
        );

        if (startResponse.containsKey('inspection_id')) {
          _inspectionId = startResponse['inspection_id'];
          debugPrint("DEBUG: ✅ Created new draft (ID: $_inspectionId)");
        } else {
          throw Exception('Failed to create draft before submission');
        }
      } else {
        debugPrint("DEBUG: ✅ Using existing draft (ID: $_inspectionId)");
      }


      // Submit finalized inspection
      final payload = {..._currentInspection, 'inspection_id': _inspectionId};

      debugPrint("DEBUG: 🚀 Submitting inspection payload: $payload");

      final response = await InspectionService.submitInspection(token, payload);

      if (response != null && response['inspection_id'] != null) {
        final submittedId = response['inspection_id'] as int;
        debugPrint(
          "DEBUG: ✅ Inspection submitted successfully (ID: $submittedId)",
        );

        // Reset state to prevent reusing old inspection ID
        resetInspection();
      } else {
        debugPrint("DEBUG: ⚠️ Backend did not return inspection_id");
      }
    });
  }

  // -------------------------
  // Update existing inspection
  // -------------------------
  Future<bool> updateInspection(int inspectionId) async {
    final token = authProvider.token;
    if (token == null) return false;

    return _submit(() async {
      await InspectionService.updateInspection(
        inspectionId,
        token,
        _currentInspection,
      );
      _inspectionId = inspectionId;
    });
  }

  // -------------------------
  // Upload a photo for a specific item or the inspection
  // -------------------------
  Future<void> uploadPhoto(File photoFile, {int? inspectionItemId}) async {
    final token = authProvider.token;
    if (token == null || _inspectionId == null) {
      _error = 'Not authenticated or no inspection started';
      notifyListeners();
      return;
    }

    try {
      final response = await InspectionPhotoService.uploadPhoto(
        inspectionId: _inspectionId,
        token: token,
        photoFile: photoFile,
        inspectionItemId: inspectionItemId,
      );

      final photoUrl = response['photo_url'];
      if (photoUrl != null) {
        _inspectionPhotos.add({
          'photo_url': photoUrl,
          'inspection_item_id': inspectionItemId?.toString(),
        });
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to upload photo: ${e.toString()}';
      notifyListeners();
    }
  }

  // -------------------------
  // Add photo manually
  // -------------------------
  void addPhoto(Map<String, dynamic> photo, {int? inspectionItemId}) {
    _inspectionPhotos.add({...photo, 'inspectionItemId': inspectionItemId});
    notifyListeners();
  }

  // -------------------------
  // Reset inspection
  // -------------------------
  void resetInspection() {
    _currentInspection = {};
    _inspectionPhotos = [];
    _error = '';
    _isSubmitting = false;
    _inspectionId = null;
    notifyListeners();
  }
}
