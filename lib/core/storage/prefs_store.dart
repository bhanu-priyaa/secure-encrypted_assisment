import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class PrefsStore {
  PrefsStore(this._prefs);

  static Future<PrefsStore> create() async =>
      PrefsStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  bool get introSeen => _prefs.getBool(PrefsKeys.introSeen) ?? false;

  Future<void> markIntroSeen() => _prefs.setBool(PrefsKeys.introSeen, true);

  String? get themeMode => _prefs.getString(PrefsKeys.themeMode);

  Future<void> setThemeMode(String value) => _prefs.setString(PrefsKeys.themeMode, value);
}
