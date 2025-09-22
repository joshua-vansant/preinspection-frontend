import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _role;

  String? get token => _token;
  String? get role => _role;

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
