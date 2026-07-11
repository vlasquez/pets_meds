import '../repositories/weight_repository.dart';

class DeleteWeightEntry {
  final WeightRepository _repository;
  const DeleteWeightEntry(this._repository);

  Future<void> call(int id) => _repository.deleteWeightEntry(id);
}
