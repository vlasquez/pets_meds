import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

/// The medication catalog, sorted by name.
class GetMedications {
  final MedicationRepository _repository;
  const GetMedications(this._repository);

  Future<List<Medication>> call() => _repository.getMedications();
}
