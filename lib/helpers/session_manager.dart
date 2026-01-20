import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  // Save user login status and UID
  static Future<void> saveUserSession({
    required bool isLoggedIn,
    required String uid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
    await prefs.setString('uid', uid);
  }

  // Get UID
  static Future<String?> getUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid');
  }

  // Check if user is logged in
  static Future<bool> getLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final uid = prefs.getString('uid');
    print('🔒 getLoginStatus() -> isLoggedIn: $isLoggedIn, uid: $uid');
    return isLoggedIn && uid != null;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('uid');
  }

  // Check if it's the first time the app is launched
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
    }
    return isFirstTime;
  }
}
