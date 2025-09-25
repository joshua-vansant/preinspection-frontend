import 'package:flutter/material.dart';
import '../services/organization_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _role;
  Map<String, dynamic>? _org;

  String? get token => _token;
  String? get role => _role;
  Map<String, dynamic>? get org => _org;

  void setOrg(Map<String, dynamic>? orgData) {
    _org = orgData;
    notifyListeners();
  }

  void clearOrg() {
    _org = null;
    notifyListeners();
  }

    Future<void> loadOrg() async {
    if (_token == null) return;
    try {
      final fetchedOrg = await OrganizationService.getMyOrg(_token!);
      _org = fetchedOrg;
      notifyListeners();
    } catch (e) {
      _org = null;
      notifyListeners();
    }
  }

  bool get isLoggedIn => _token != null;

  void setToken(String token, String role) {
    _token = token;
    _role = role;
    notifyListeners();
  }

  void clearToken() {
    _token = null;
    _role = null;
    notifyListeners();
  }
}
