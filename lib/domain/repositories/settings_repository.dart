import '../entities/app_settings.dart';

/// Contract for settings persistence. Implemented in the data layer.
abstract interface class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}
