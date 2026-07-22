import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/app_settings.dart';
import '../../../domain/usecases/get_settings.dart';
import '../../../domain/usecases/save_settings.dart';

part 'settings_event.dart';

/// App-wide user preferences (theme, language, hour format). The state
/// is the [AppSettings] itself; MaterialApp rebuilds on changes.
class SettingsBloc extends Bloc<SettingsEvent, AppSettings> {
  final GetSettings _getSettings;
  final SaveSettings _saveSettings;

  SettingsBloc({
    required GetSettings getSettings,
    required SaveSettings saveSettings,
  })  : _getSettings = getSettings,
        _saveSettings = saveSettings,
        super(const AppSettings()) {
    on<SettingsRequested>(_onRequested);
    on<ThemeModeChanged>(_onThemeChanged);
    on<LanguageChanged>(_onLanguageChanged);
    on<HourFormatChanged>(_onHourFormatChanged);
  }

  Future<void> _onRequested(
      SettingsRequested event, Emitter<AppSettings> emit) async {
    emit(await _getSettings());
  }

  Future<void> _persist(AppSettings settings, Emitter<AppSettings> emit) async {
    await _saveSettings(settings);
    emit(settings);
  }

  Future<void> _onThemeChanged(
          ThemeModeChanged event, Emitter<AppSettings> emit) =>
      _persist(state.copyWith(themeMode: event.themeMode), emit);

  Future<void> _onLanguageChanged(
          LanguageChanged event, Emitter<AppSettings> emit) =>
      _persist(state.copyWith(languageCode: () => event.languageCode), emit);

  Future<void> _onHourFormatChanged(
          HourFormatChanged event, Emitter<AppSettings> emit) =>
      _persist(state.copyWith(hourFormat: event.hourFormat), emit);
}
