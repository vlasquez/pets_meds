import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/app_settings.dart';

/// Persists user preferences in SharedPreferences.
class SettingsLocalDataSource {
  static const _themeKey = 'themeMode';
  static const _languageKey = 'languageCode';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey);
    AppThemeMode themeMode;
    try {
      themeMode = AppThemeMode.values.byName(themeName ?? 'system');
    } on ArgumentError {
      themeMode = AppThemeMode.system;
    }
    return AppSettings(
      themeMode: themeMode,
      languageCode: prefs.getString(_languageKey),
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, settings.themeMode.name);
    if (settings.languageCode == null) {
      await prefs.remove(_languageKey);
    } else {
      await prefs.setString(_languageKey, settings.languageCode!);
    }
  }
}
