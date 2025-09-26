import 'package:flutter/material.dart';
import '../services/inspection_service.dart';

class InspectionHistoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;
  String _error = '';

  List<Map<String, dynamic>> get history => _history;
  bool get isLoading => _isLoading;
  String get error => _error;

  /// Fetches the inspection history for the current user
  Future<void> fetchHistory(String token) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _history = await InspectionService.getInspectionHistory(token);
    } catch (e) {
      _history = [];
      _error = 'Failed to fetch inspection history: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the cached history
  void clearHistory() {
    _history = [];
    _error = '';
    notifyListeners();
  }
}
