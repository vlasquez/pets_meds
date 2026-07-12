import '../entities/treatment.dart';
import '../repositories/treatment_repository.dart';

/// All treatments across every pet (for the Home and Treatments tabs).
class GetAllTreatments {
  final TreatmentRepository _repository;
  const GetAllTreatments(this._repository);

  Future<List<Treatment>> call() => _repository.getAllTreatments();
}
