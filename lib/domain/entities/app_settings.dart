import 'package:equatable/equatable.dart';

enum AppThemeMode { system, light, dark }

/// Domain entity: user preferences.
class AppSettings extends Equatable {
  final AppThemeMode themeMode;

  /// 'es', 'en', or null to follow the system language.
  final String? languageCode;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.languageCode,
  });

  @override
  List<Object?> get props => [themeMode, languageCode];
}
