import 'package:equatable/equatable.dart';

enum AppThemeMode { system, light, dark }

/// How times of day are displayed. [system] follows the device's
/// 24-hour setting; the others force 24h or AM/PM.
enum AppHourFormat { system, h24, h12 }

/// Domain entity: user preferences.
class AppSettings extends Equatable {
  final AppThemeMode themeMode;

  /// 'es', 'en', or null to follow the system language.
  final String? languageCode;

  final AppHourFormat hourFormat;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.languageCode,
    this.hourFormat = AppHourFormat.system,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? Function()? languageCode,
    AppHourFormat? hourFormat,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        languageCode:
            languageCode != null ? languageCode() : this.languageCode,
        hourFormat: hourFormat ?? this.hourFormat,
      );

  @override
  List<Object?> get props => [themeMode, languageCode, hourFormat];
}
