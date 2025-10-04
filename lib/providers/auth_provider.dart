import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/ui_helpers.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _role;
  Map<String, dynamic>? _org;
  Map<String, dynamic>? _user;
  String? _error;

  // Getters
  String? get token => _token;
  String? get role => _role;
  Map<String, dynamic>? get org => _org;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;

  bool get hasOrg => _org != null;
  bool get isLoggedIn => _token != null;
  bool get isAdmin => _role == 'admin';

  // Setters
  void setToken(String token, String role, {Map<String, dynamic>? userData}) {
    _token = token;
    _role = role;

    if (userData != null) setUser(userData);

    notifyListeners();
  }

  void setRole(String role) {
  _role = role;
  if (_user != null) {
    _user!['role'] = role;
  }
  notifyListeners();
}


 void clearOrg() {
    _org = null;
    if (_user != null) {
      _role = 'driver';
      _user!['role'] = 'driver';
      _user!['org_id'] = null;
      _user!['org'] = null;
    }
    notifyListeners();
  }

  void setUser(Map<String, dynamic>? userData) {
    _user = userData;
    _role = userData?['role'];
    _org = userData?['org'];
    notifyListeners();
  }

  void setOrg(Map<String, dynamic>? orgData) {
    _org = orgData;
    notifyListeners();
  }


  void clearToken() {
    _token = null;
    _role = null;
    _user = null;
    _org = null;
    _error = null;
    notifyListeners();
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await AuthService.logout(_token!);
      } catch (e) {
        _error = UIHelpers.parseError(e.toString());
      }
    }
    clearToken();
  }

  Future<bool> login(String email, String password) async {
    try {
      final data = await AuthService.login(email, password);
      _token = data['access_token'];
      _role = data['user']['role'];
      _user = data['user'];
      if (_user?['org'] != null) _org = _user?['org'];
      notifyListeners();
      return true;
    } catch (e) {
      _error = UIHelpers.parseError(e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final data = await AuthService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      _token = data['access_token'];
      _role = data['user']['role'];
      _user = data['user'];
      _org = data['org'];
      notifyListeners();
      return true;
    } catch (e) {
      _error = UIHelpers.parseError(e.toString());
      return false;
    }
  }

  Future<bool> updateUser(Map<String, dynamic> updatedData) async {
    if (_token == null) {
      _error = "No token available";
      return false;
    }

    try {
      final updatedUser = await UserService.updateUser(_token!, updatedData);
      setUser(updatedUser);
      return true;
    } catch (e) {
      _error = UIHelpers.parseError(e.toString());
      return false;
    }
  }

}
