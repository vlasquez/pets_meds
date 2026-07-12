import '../../domain/entities/dose_log.dart';
import '../../domain/repositories/dose_log_repository.dart';
import '../datasources/local/dose_log_local_datasource.dart';
import '../models/dose_log_model.dart';

class DoseLogRepositoryImpl implements DoseLogRepository {
  final DoseLogLocalDataSource _local;
  const DoseLogRepositoryImpl(this._local);

  @override
  Future<List<DoseLog>> getDoseLogsForPet(int petId, {int limit = 200}) =>
      _local.getForPet(petId, limit: limit);

  @override
  Future<DoseLog> insertDoseLog(DoseLog log) async {
    final id = await _local.insert(DoseLogModel.fromEntity(log));
    return DoseLog(
      id: id,
      treatmentId: log.treatmentId,
      petId: log.petId,
      givenAt: log.givenAt,
      note: log.note,
    );
  }

  @override
  Future<void> deleteDoseLog(int id) => _local.delete(id);
}
