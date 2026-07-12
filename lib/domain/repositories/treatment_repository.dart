import '../entities/treatment.dart';

/// Contract for treatment persistence. Implemented in the data layer.
/// Returned treatments carry the joined medication name.
abstract interface class TreatmentRepository {
  Future<List<Treatment>> getTreatmentsForPet(int petId);
  Future<List<Treatment>> getAllTreatments();
  Future<Treatment> insertTreatment(Treatment treatment);
  Future<void> updateTreatment(Treatment treatment);
  Future<void> deleteTreatment(int id);
}
