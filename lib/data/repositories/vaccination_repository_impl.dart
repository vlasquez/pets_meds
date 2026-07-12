import '../../domain/entities/vaccination.dart';
import '../../domain/repositories/vaccination_repository.dart';
import '../datasources/local/vaccination_local_datasource.dart';
import '../models/vaccination_model.dart';

class VaccinationRepositoryImpl implements VaccinationRepository {
  final VaccinationLocalDataSource _local;
  const VaccinationRepositoryImpl(this._local);

  @override
  Future<List<Vaccination>> getVaccinationsForPet(int petId) =>
      _local.getForPet(petId);

  @override
  Future<Vaccination> insertVaccination(Vaccination vaccination) async {
    final id = await _local.insert(VaccinationModel.fromEntity(vaccination));
    return vaccination.copyWith(id: id);
  }

  @override
  Future<void> deleteVaccination(int id) => _local.delete(id);
}
