import '../../domain/entities/weight_entry.dart';
import '../../domain/repositories/weight_repository.dart';
import '../datasources/local/weight_local_datasource.dart';
import '../models/weight_entry_model.dart';

class WeightRepositoryImpl implements WeightRepository {
  final WeightLocalDataSource _local;
  const WeightRepositoryImpl(this._local);

  @override
  Future<List<WeightEntry>> getWeightHistory(int petId) =>
      _local.getForPet(petId);

  @override
  Future<WeightEntry> insertWeightEntry(WeightEntry entry) async {
    final id = await _local.insert(WeightEntryModel.fromEntity(entry));
    return WeightEntry(
      id: id,
      petId: entry.petId,
      weightKg: entry.weightKg,
      measuredAt: entry.measuredAt,
      note: entry.note,
    );
  }

  @override
  Future<void> deleteWeightEntry(int id) => _local.delete(id);
}
