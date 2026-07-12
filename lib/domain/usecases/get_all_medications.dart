import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

/// All medications across every pet (for the Home and Treatments tabs).
class GetAllMedications {
  final MedicationRepository _repository;
  const GetAllMedications(this._repository);

  Future<List<Medication>> call() => _repository.getAllMedications();
}
