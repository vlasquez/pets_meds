import '../entities/weight_entry.dart';
import '../repositories/weight_repository.dart';

class GetWeightHistory {
  final WeightRepository _repository;
  const GetWeightHistory(this._repository);

  /// Most recent first.
  Future<List<WeightEntry>> call(int petId) =>
      _repository.getWeightHistory(petId);
}
