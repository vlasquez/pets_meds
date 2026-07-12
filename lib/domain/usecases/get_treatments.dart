import '../entities/treatment.dart';
import '../repositories/treatment_repository.dart';

/// Treatments of one pet.
class GetTreatments {
  final TreatmentRepository _repository;
  const GetTreatments(this._repository);

  Future<List<Treatment>> call(int petId) =>
      _repository.getTreatmentsForPet(petId);
}
