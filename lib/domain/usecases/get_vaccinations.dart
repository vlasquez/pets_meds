import '../entities/vaccination.dart';
import '../repositories/vaccination_repository.dart';

class GetVaccinations {
  final VaccinationRepository _repository;
  const GetVaccinations(this._repository);

  Future<List<Vaccination>> call(int petId) =>
      _repository.getVaccinationsForPet(petId);
}
