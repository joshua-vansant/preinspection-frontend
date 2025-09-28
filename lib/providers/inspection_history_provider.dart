import 'package:flutter/material.dart';
import '../services/inspection_service.dart';
import 'socket_provider.dart';

class InspectionHistoryProvider extends ChangeNotifier {
  final SocketProvider socketProvider;

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;
  String _error = '';

  List<Map<String, dynamic>> get history => _history;
  bool get isLoading => _isLoading;
  String get error => _error;

  InspectionHistoryProvider({required this.socketProvider}) {
    _listenForSocketUpdates();
  }

  /// Fetches the inspection history for the current user
  Future<void> fetchHistory(String token) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _history = await InspectionService.getInspectionHistory(token);

      _history.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate); //return newest first
      });
      
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

  /// Adds or updates an inspection in the list
  void addInspection(Map<String, dynamic> inspection) {
    final existingIndex =
        _history.indexWhere((i) => i['id'] == inspection['id']);
    if (existingIndex == -1) {
      _history.insert(0, inspection); 
    } else {
      _history[existingIndex] = inspection;
    }
    notifyListeners();
  }

  /// Refresh by clearing and fetching fresh data
  Future<void> refresh(String token) async {
    clearHistory();
    await fetchHistory(token);
  }

  void _listenForSocketUpdates() {
    socketProvider.onEvent('inspection_update', (data) {
      debugPrint("🔔 Socket inspection update: $data");
      if (data is Map<String, dynamic>) {
        addInspection(data);
      }
    });
  }

  @override
  void dispose() {
    socketProvider.offEvent('inspection_update');
    super.dispose();
  }
}
