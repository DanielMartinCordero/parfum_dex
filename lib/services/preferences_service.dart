import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;
  static const String _keyFirstTime = 'first_time';
  static const String _keyPendingPhotoItemId = 'pending_photo_item_id';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isFirstTime {
    return _prefs.getBool(_keyFirstTime) ?? true;
  }

  static Future<void> setNotFirstTime() async {
    await _prefs.setBool(_keyFirstTime, false);
  }

  static String? get pendingPhotoItemId {
    return _prefs.getString(_keyPendingPhotoItemId);
  }

  static Future<void> setPendingPhotoItemId(String itemId) async {
    await _prefs.setString(_keyPendingPhotoItemId, itemId);
  }

  static Future<void> clearPendingPhotoItemId() async {
    await _prefs.remove(_keyPendingPhotoItemId);
  }
}
