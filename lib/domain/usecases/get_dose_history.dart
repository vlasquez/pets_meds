import '../entities/dose_log.dart';
import '../entities/treatment.dart';
import '../repositories/dose_log_repository.dart';
import '../repositories/treatment_repository.dart';

/// The dose history of a pet, with the treatments indexed by id
/// so the UI can display medication names and dosages.
class DoseHistory {
  final List<DoseLog> logs;
  final Map<int, Treatment> treatmentsById;

  const DoseHistory({required this.logs, required this.treatmentsById});
}

class GetDoseHistory {
  final DoseLogRepository _doseLogs;
  final TreatmentRepository _treatments;

  const GetDoseHistory(this._doseLogs, this._treatments);

  Future<DoseHistory> call(int petId) async {
    final logs = await _doseLogs.getDoseLogsForPet(petId);
    final treatments = await _treatments.getTreatmentsForPet(petId);
    return DoseHistory(
      logs: logs,
      treatmentsById: {for (final t in treatments) t.id!: t},
    );
  }
}
