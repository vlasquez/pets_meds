import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class GetMedications {
  final MedicationRepository _repository;
  const GetMedications(this._repository);

  Future<List<Medication>> call(int petId) =>
      _repository.getMedicationsForPet(petId);
}
