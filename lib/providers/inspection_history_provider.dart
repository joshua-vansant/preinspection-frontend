import 'package:flutter/material.dart';
import '../services/inspection_service.dart';
import '../utils/ui_helpers.dart';
import 'auth_provider.dart';
import 'socket_provider.dart';

class InspectionHistoryProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final SocketProvider socketProvider;

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;
  String _error = '';

  final Set<int> _fetchingIds = {};

  List<Map<String, dynamic>> get history => _history;
  bool get isLoading => _isLoading;
  String get error => _error;

  InspectionHistoryProvider({
    required this.authProvider,
    required this.socketProvider,
  }) {
    _listenForSocketUpdates();
  }

  // Fetch inspection history for the logged-in user
  Future<void> fetchHistory() async {
    final token = authProvider.token;
    if (token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _history = await InspectionService.getInspectionHistory(token);

      // Sort newest first
      _history.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
        final bDate =
            DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    } catch (e) {
      _history = [];
      _error = UIHelpers.parseError(e.toString());
      debugPrint('DEBUG: InspectionHistory error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clears cached history
  void clearHistory() {
    _history = [];
    _error = '';
    notifyListeners();
  }

  // Adds or updates an inspection in the list
  void addInspection(Map<String, dynamic> inspection) {
    // Avoid duplicates
    final exists = _history.any((i) => i['id'] == inspection['id']);
    if (!exists) {
      _history.insert(0, inspection);
      debugPrint('DEBUG: Inspection added via socket: ${inspection['id']}');
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> fetchFullInspection(int id) async {
    debugPrint('DEBUG: fetchFullInspection called for $id');
    final token = authProvider.token;
    if (token == null) throw Exception('No auth token');

    final fullInspection = await InspectionService.getInspectionById(id, token);
    debugPrint('DEBUG: Full inspection fetched: $fullInspection');

    // Merge or update history
    final index = _history.indexWhere((i) => i['id'] == id);
    if (index >= 0) {
      _history[index] = fullInspection;
      debugPrint('DEBUG: Full inspection merged at index $index');
    } else {
      _history.insert(0, fullInspection);
      debugPrint('DEBUG: Full inspection added at index 0');
    }

    notifyListeners();

    return fullInspection; // <--- RETURN the fetched data
  }

  // Refresh by clearing + fetching
  Future<void> refresh() async {
    clearHistory();
    await fetchHistory();
  }

  void _listenForSocketUpdates() {
    socketProvider.onEvent('inspection_update', (data) {
      debugPrint("DEBUG: 🔔 Socket inspection update: $data");
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
