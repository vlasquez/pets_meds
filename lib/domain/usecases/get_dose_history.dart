import '../entities/dose_log.dart';
import '../entities/medication.dart';
import '../repositories/dose_log_repository.dart';
import '../repositories/medication_repository.dart';

/// The dose history of a pet, with the medications indexed by id
/// so the UI can display names and dosages.
class DoseHistory {
  final List<DoseLog> logs;
  final Map<int, Medication> medicationsById;

  const DoseHistory({required this.logs, required this.medicationsById});
}

class GetDoseHistory {
  final DoseLogRepository _doseLogs;
  final MedicationRepository _medications;

  const GetDoseHistory(this._doseLogs, this._medications);

  Future<DoseHistory> call(int petId) async {
    final logs = await _doseLogs.getDoseLogsForPet(petId);
    final meds = await _medications.getMedicationsForPet(petId);
    return DoseHistory(
      logs: logs,
      medicationsById: {for (final m in meds) m.id!: m},
    );
  }
}
