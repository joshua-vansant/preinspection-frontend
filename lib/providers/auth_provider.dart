import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/organization_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../utils/ui_helpers.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _refresh_token;
  DateTime? tokenExpiry;
  String? _role;
  Map<String, dynamic>? _org;
  Map<String, dynamic>? _user;
  String? _error;

  // Getters
  String? get token => _token;
  String? get refresh_token => _refresh_token;
  String? get role => _role;
  Map<String, dynamic>? get org => _org;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;

  bool get isAuth {
    if (tokenExpiry == null || _token == null) return false;
    return tokenExpiry!.isAfter(DateTime.now());
  }

  bool get isLoggedIn => _token != null;

  void setOrg(Map<String, dynamic>? orgData) {
    _org = orgData;
    notifyListeners();
  }

  void clearOrg() {
    debugPrint('AuthProvider.clearOrg called, role set to $_role');
    _org = null;
    if (_user != null) {
      _user!['org_id'] = null;
      _user!['role'] = 'driver';
      _role = 'driver';
      }
    notifyListeners();
  }

  Future<void> loadOrg() async {
    if (_token == null) return;
    try {
      final fetchedOrg = await OrganizationService.getMyOrg(_token!);
      _org = fetchedOrg;
      _error = null;
      notifyListeners();
    } catch (e) {
      _org = null;
      _error = UIHelpers.parseError(e.toString());
      notifyListeners();
    }
  }

  void setToken(String token, String role,
      {Map<String, dynamic>? userData, int? expiresIn}) {
    _token = token;
    _role = role;

    if (expiresIn != null) {
      tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
      _scheduleTokenRefresh();
    }

    if (userData != null) setUser(userData);
    notifyListeners();
  }

  void setUser(Map<String, dynamic>? userData) {
    _user = userData;
    _role = _user?['role'];
    debugPrint('DEBUG AuthProvider.setUser called, role=$_role');

    if (_user != null) {
      Sentry.configureScope((scope) {
        scope.setUser(SentryUser(
          id: _user!['id'].toString(),
          email: _user!['email'],
          // username: _user!['first_name'] + ' ' + _user!['last_name'],
        ));
      });
    } else {
      Sentry.configureScope((scope) => scope.setUser(null));
    }
    // final authProvider = context.watch<AuthProvider>();
    // debugPrint("AuthProvider role after redeem: ${authProvider.role}");

    notifyListeners();
  }

  void clearToken() {
    _token = null;
    _role = null;
    _user = null;
    _org = null;
    tokenExpiry = null;
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
      // _refreshToken = data['refresh_token'];
      _user = data['user']; 
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login failed: $e');
      return false;
    }
  }

  Future<void> refreshToken() async {
    if (_token == null) throw Exception("No token to refresh");

    try {
      final result = await AuthService.refreshToken(_token!);
      final newToken = result['access_token'];
      final role = result['role'] ?? _role;
      final expiresIn = result['expires_in'];

      if (newToken == null) throw Exception("No token in refresh response");

      setToken(newToken, role, expiresIn: expiresIn);
      debugPrint("Token refreshed and updated");
      _error = null;
    } catch (e) {
      _error = UIHelpers.parseError(e.toString());
      rethrow;
    }
  }

  /// Checks if token needs refresh and refreshes proactively
  Future<bool> refreshTokenIfNeeded() async {
    if (_token == null) return false;
    final now = DateTime.now();

    // Refresh 2 minutes before actual expiry
    if (tokenExpiry != null &&
        now.isAfter(tokenExpiry!.subtract(const Duration(minutes: 2)))) {
      try {
        debugPrint("Refreshing token proactively...");
        await refreshToken();
        return true;
      } catch (e) {
        debugPrint("Token refresh failed: $_error");
        await logout();
        return false;
      }
    }
    return true; // still valid
  }

  /// Internal: schedule automatic refresh before token expires
  void _scheduleTokenRefresh() {
    if (_token == null || tokenExpiry == null) return;

    final now = DateTime.now();
    final refreshAt = tokenExpiry!.subtract(const Duration(minutes: 2));
    final delay = refreshAt.difference(now);

    if (delay.isNegative) return; // already passed, refresh will happen on next request

    Future.delayed(delay, () async {
      if (_token != null) {
        try {
          await refreshToken();
          _scheduleTokenRefresh();
        } catch (e) {
          debugPrint("Auto token refresh failed: $_error");
          await logout();
        }
      }
    });
  }
}
