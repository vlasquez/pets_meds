import '../entities/medication.dart';

/// Contract for the medication catalog. Implemented in the data layer.
abstract interface class MedicationRepository {
  /// All catalog medications, sorted by name.
  Future<List<Medication>> getMedications();
  Future<Medication> insertMedication(Medication medication);
  Future<void> updateMedication(Medication medication);
}
