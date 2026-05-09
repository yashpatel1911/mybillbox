import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static SessionManager? _instance;
  late SharedPreferences _sharedPreferences;

  SessionManager._();

  factory SessionManager() => _instance ??= SessionManager._();

  Future<void> initPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  Future<void> setPreference(String key, String value) async {
    await _sharedPreferences.setString(key, value);
    print('Preference set: $key = $value'); // Debug
  }

  // Existing getters
  String get name => _sharedPreferences.getString('name') ?? '';

  String get mobile => _sharedPreferences.getString('mobile') ?? '';

  String get status => _sharedPreferences.getString('status') ?? '';

  String get user_type => _sharedPreferences.getString('user_type') ?? '';

  String get token => _sharedPreferences.getString('token') ?? '';

  String get role => _sharedPreferences.getString('role') ?? '';

  String get isDarkLight => _sharedPreferences.getString('isDarkLight') ?? '';

  String get isNews => _sharedPreferences.getString('isNews') ?? '';
}
