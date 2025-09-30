import 'package:flutter/material.dart';
import '../services/inspection_service.dart';
import '../utils/ui_helpers.dart';

class InspectionProvider extends ChangeNotifier {
  Map<String, dynamic> _currentInspection = {};
  bool _isSubmitting = false;
  String _error = '';

  Map<String, dynamic> get currentInspection => _currentInspection;
  bool get isSubmitting => _isSubmitting;
  String get error => _error;

  /// Initialize a new inspection (PRE or POST)
  void startInspection({
    required int vehicleId,
    required String type, // 'pre-trip' or 'post-trip'
    Map<String, dynamic>? initialData,
    Map<String, dynamic>? template,
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
      if (initialData != null) ...initialData,
    };
    _error = '';
    notifyListeners();
  }

  /// Update a single field in the current inspection
  void updateField(String key, dynamic value) {
    _currentInspection[key] = value;
    notifyListeners();
  }

  /// Submit a new inspection
  Future<bool> submitInspection(String token) async {
    _isSubmitting = true;
    _error = '';
    notifyListeners();

    try {
      await InspectionService.submitInspection(token, _currentInspection);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      final parsed = UIHelpers.parseError(e.toString());
      _error = parsed.isNotEmpty ? 'Failed to submit inspection: $parsed' : 'Failed to submit inspection';
      notifyListeners();
      return false;
    }
  }

  /// Update an existing inspection (if editing)
  Future<bool> updateInspection(String token, int inspectionId) async {
    _isSubmitting = true;
    _error = '';
    notifyListeners();

    try {
      await InspectionService.updateInspection(inspectionId, token, _currentInspection);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      final parsed = UIHelpers.parseError(e.toString());
      _error = parsed.isNotEmpty ? 'Failed to submit inspection: $parsed' : 'Failed to submit inspection';
      notifyListeners();
      return false;
    }
  }

  /// Reset the current inspection
  void resetInspection() {
    _currentInspection = {};
    _error = '';
    _isSubmitting = false;
    notifyListeners();
  }
}
