import 'package:flutter/material.dart';
import '../services/inspection_service.dart';

class InspectionHistoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> history = [];
  bool isLoading = false;

  Future<void> fetchHistory(String token) async {
    isLoading = true;
    notifyListeners();

    try {
      history = await InspectionService.getInspectionHistory(token);
    } catch (e) {
      history = [];
      debugPrint('Error fetching inspection history: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
