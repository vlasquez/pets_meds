import '../entities/dose_log.dart';

/// Contract for dose-log persistence. Implemented in the data layer.
abstract interface class DoseLogRepository {
  Future<List<DoseLog>> getDoseLogsForPet(int petId, {int limit});
  Future<DoseLog> insertDoseLog(DoseLog log);
}
