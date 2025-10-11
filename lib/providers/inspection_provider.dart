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

  // Initialize a new inspection (PRE or POST)
  void startInspection({
    required int vehicleId,
    required String type,
    Map<String, dynamic>? initialData,
    Map<String, dynamic>? template,
    Map<String, dynamic>? selectedVehicle,
  }) {
    _currentInspection = {
      'vehicle_id': vehicleId,
      'type': type,
      'template_id': template?['id'],
      'start_mileage': null,
      'end_mileage': null,
      'fuel_level': 0.0,
      'fuel_notes': null,
      'odometer_verified': false,
      'results': {
        for (var item in template?['items'] ?? []) item['id'].toString(): "no"
      },
      'notes': null,
      'template_name': template?['name'] ?? 'Unknown',
      'template_items': template?['items'] ?? [],
      'org_id': authProvider.org?['id'] ?? selectedVehicle?['org_id'],
      if (initialData != null) ...initialData,
    };
    _error = '';
    notifyListeners();
  }

  // Update a single field in the current inspection
  void updateField(String key, dynamic value) {
    _currentInspection[key] = value;
    notifyListeners();
  }

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

  // Submit a new inspection
  Future<bool> submitInspection() async {
    final token = authProvider.token;
    if (token == null) {
      _error = 'Not authenticated';
      return false;
    }
    return _submit(() => InspectionService.submitInspection(token, _currentInspection));
  }

  // Update an existing inspection
  Future<bool> updateInspection(int inspectionId) async {
    final token = authProvider.token;
    if (token == null) {
      _error = 'Not authenticated';
      return false;
    }
    return _submit(() =>
        InspectionService.updateInspection(inspectionId, token, _currentInspection));
  }

  // Upload a photo (works with or without inspection ID)
  Future<void> uploadPhoto(File photoFile) async {
    final token = authProvider.token;
    if (token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    try {
      final response = await InspectionPhotoService.uploadPhoto(
        inspectionId: _inspectionId, // may be null for drafts
        token: token,
        photoFile: photoFile,
      );

      final photoUrl = response['photo_url'];
      if (photoUrl != null) {
        _inspectionPhotos.add({'url': photoUrl});
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to upload photo: ${UIHelpers.parseError(e.toString())}';
      notifyListeners();
    }
  }

  // Add a photo to the current inspection manually
  void addPhoto(Map<String, dynamic> photo) {
    _inspectionPhotos.add(photo);
    notifyListeners();
  }

  // Reset the current inspection
  void resetInspection() {
    _currentInspection = {};
    _inspectionPhotos = [];
    _error = '';
    _isSubmitting = false;
    _inspectionId = null;
    notifyListeners();
  }
}
