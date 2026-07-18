import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _local;
  const SettingsRepositoryImpl(this._local);

  @override
  Future<AppSettings> getSettings() => _local.load();

  @override
  Future<void> saveSettings(AppSettings settings) => _local.save(settings);
}
