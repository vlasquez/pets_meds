import '../entities/weight_entry.dart';
import '../repositories/weight_repository.dart';

class LogWeight {
  final WeightRepository _repository;
  const LogWeight(this._repository);

  Future<WeightEntry> call(WeightEntry entry) =>
      _repository.insertWeightEntry(entry);
}
