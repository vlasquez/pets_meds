import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/app_settings.dart';

/// Persists user preferences in SharedPreferences.
class SettingsLocalDataSource {
  static const _themeKey = 'themeMode';
  static const _languageKey = 'languageCode';
  static const _hourFormatKey = 'hourFormat';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      themeMode: _enumByName(
          AppThemeMode.values, prefs.getString(_themeKey), AppThemeMode.system),
      languageCode: prefs.getString(_languageKey),
      hourFormat: _enumByName(
          HourFormat.values, prefs.getString(_hourFormatKey), HourFormat.system),
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, settings.themeMode.name);
    await prefs.setString(_hourFormatKey, settings.hourFormat.name);
    if (settings.languageCode == null) {
      await prefs.remove(_languageKey);
    } else {
      await prefs.setString(_languageKey, settings.languageCode!);
    }
  }

  static T _enumByName<T extends Enum>(
      List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
