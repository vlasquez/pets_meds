import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

/// Inserts (id == null) or updates a catalog medication.
class SaveMedication {
  final MedicationRepository _repository;
  const SaveMedication(this._repository);

  Future<Medication> call(Medication medication) async {
    if (medication.id == null) {
      return _repository.insertMedication(medication);
    }
    await _repository.updateMedication(medication);
    return medication;
  }
}
