import 'package:shared_preferences/shared_preferences.dart';

class Preference {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isLogin => _prefs?.getBool('isLogin') ?? false;
  static int get userId => _prefs?.getInt('userId') ?? 0;
  static String get username => _prefs?.getString('username') ?? 'Guest';
  static String get email => _prefs?.getString('email') ?? '';

  static Future<void> saveUserSession(int id, String name, String email) async {
    await _prefs?.setBool('isLogin', true);
    await _prefs?.setInt('userId', id);
    await _prefs?.setString('username', name);
    await _prefs?.setString('email', email);
  }

  // Fungsi hapus sesi saat LOGOUT
  static Future<void> logOut() async {
    await _prefs?.clear();
  }
}
