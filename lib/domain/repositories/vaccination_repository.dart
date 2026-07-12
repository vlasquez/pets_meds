import '../entities/vaccination.dart';

/// Contract for vaccination persistence. Implemented in the data layer.
abstract interface class VaccinationRepository {
  /// Vaccinations for a pet, most recent first.
  Future<List<Vaccination>> getVaccinationsForPet(int petId);
  Future<Vaccination> insertVaccination(Vaccination vaccination);
  Future<void> deleteVaccination(int id);
}
