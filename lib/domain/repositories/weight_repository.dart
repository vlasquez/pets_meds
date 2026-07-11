import '../entities/weight_entry.dart';

/// Contract for weight-entry persistence. Implemented in the data layer.
abstract interface class WeightRepository {
  /// Entries for a pet, most recent first.
  Future<List<WeightEntry>> getWeightHistory(int petId);
  Future<WeightEntry> insertWeightEntry(WeightEntry entry);
  Future<void> deleteWeightEntry(int id);
}
