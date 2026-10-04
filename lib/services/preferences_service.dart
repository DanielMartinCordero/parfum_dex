import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;
  static const String _keyFirstTime = 'first_time';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isFirstTime {
    return _prefs.getBool(_keyFirstTime) ?? true;
  }

  static Future<void> setNotFirstTime() async {
    await _prefs.setBool(_keyFirstTime, false);
  }
}
