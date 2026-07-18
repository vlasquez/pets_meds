part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

final class SettingsRequested extends SettingsEvent {
  const SettingsRequested();
}

final class ThemeModeChanged extends SettingsEvent {
  final AppThemeMode themeMode;
  const ThemeModeChanged(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

/// [languageCode] null means "follow the system language".
final class LanguageChanged extends SettingsEvent {
  final String? languageCode;
  const LanguageChanged(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}
