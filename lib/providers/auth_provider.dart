import 'package:flutter/material.dart';
import '../services/organization_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _role;
  Map<String, dynamic>? _org;
  Map<String, dynamic>? _user;

  String? get token => _token;
  String? get role => _role;
  Map<String, dynamic>? get org => _org;
  Map<String, dynamic>? get user => _user;


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

  void setToken(String token, String role, {Map<String, dynamic>? userData}) {
    _token = token;
    _role = role;
    if (userData != null) setUser(userData);
    notifyListeners();
  }

  void setUser(Map<String, dynamic>? userData) {
    _user = userData;
    notifyListeners();
  }

  void clearToken() {
    _token = null;
    _role = null;
    _user = null;
    notifyListeners();
  }
}
