import '../entities/medication.dart';

/// Contract for medication persistence. Implemented in the data layer.
abstract interface class MedicationRepository {
  Future<List<Medication>> getMedicationsForPet(int petId);
  Future<Medication> insertMedication(Medication medication);
  Future<void> updateMedication(Medication medication);
  Future<void> deleteMedication(int id);
}
