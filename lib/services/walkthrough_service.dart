import 'package:shared_preferences/shared_preferences.dart';

class WalkthroughService {
  static late SharedPreferences _prefs;

  static const _driverKey = 'has_seen_driver_walkthrough';
  static const _adminKey = 'has_seen_admin_walkthrough';
  static const _inspectionFormKey = 'has_seen_inspection_form_walkthrough';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool hasSeenDriverWalkthrough() {
    return _prefs.getBool(_driverKey) ?? false;
  }

  static Future<void> markDriverWalkthroughSeen() async {
    await _prefs.setBool(_driverKey, true);
  }

  static bool hasSeenAdminWalkthrough() {
    return _prefs.getBool(_adminKey) ?? false;
  }

  static Future<void> markAdminWalkthroughSeen() async {
    await _prefs.setBool(_adminKey, true);
  }

  static Future<void> resetAll() async {
    await _prefs.remove(_driverKey);
    await _prefs.remove(_adminKey);
  }

  static Future<void> resetDriverWalkthrough() async {
    await _prefs.remove(_driverKey);
  }

  static Future<void> resetAdminWalkthrough() async {
    await _prefs.remove(_adminKey);
  }

  static Future<bool> hasSeenInspectionFormWalkthrough() async {
    return _prefs.getBool(_inspectionFormKey) ?? false;
  }

  static Future<void> markInspectionFormWalkthroughSeen() async {
    await _prefs.setBool(_inspectionFormKey, true);
  }

  static Future<void> resetInspectionFormWalkthrough() async {
    await _prefs.remove(_inspectionFormKey);
  }
}
