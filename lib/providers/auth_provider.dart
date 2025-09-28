import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/organization_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  DateTime? tokenExpiry;
  String? _role;
  Map<String, dynamic>? _org;
  Map<String, dynamic>? _user;

  String? get token => _token;
  String? get role => _role;
  Map<String, dynamic>? get org => _org;
  Map<String, dynamic>? get user => _user;

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

  void setToken(String token, String role,
      {Map<String, dynamic>? userData, int? expiresIn}) {
    _token = token;
    _role = role;

    if (expiresIn != null) {
      tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
      _scheduleTokenRefresh(); // schedule auto refresh
    }

    if (userData != null) setUser(userData);
    notifyListeners();
  }

  void setUser(Map<String, dynamic>? userData) {
    _user = userData;
    if (_user != null) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: _user!['id'].toString(),
        email: _user!['email'],
        username: _user!['first_name'] + ' ' + _user!['last_name'],
      ));
    });
  } else {
    Sentry.configureScope((scope) => scope.setUser(null));
  }
    notifyListeners();
  }

  void clearToken() {
    _token = null;
    _role = null;
    _user = null;
    tokenExpiry = null;
    notifyListeners();
  }

  Future<void> logout() async {
    if (_token != null) {
      await AuthService.logout(_token!);
    }
    clearToken();
  }

  Future<void> refreshToken() async {
    if (_token == null) throw Exception("No token to refresh");

    final result = await AuthService.refreshToken(_token!);
    final newToken = result['access_token'];
    final role = result['role'] ?? _role;
    final expiresIn = result['expires_in'];

    if (newToken == null) throw Exception("No token in refresh response");

    setToken(newToken, role, expiresIn: expiresIn);
    debugPrint("Token refreshed and updated");
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
        debugPrint("Token refresh failed: $e");
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
          _scheduleTokenRefresh(); // reschedule for next expiry
        } catch (e) {
          debugPrint("Auto token refresh failed: $e");
          await logout();
        }
      }
    });
  }
}
