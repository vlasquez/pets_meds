import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../datasources/local/treatment_local_datasource.dart';
import '../models/treatment_model.dart';

class TreatmentRepositoryImpl implements TreatmentRepository {
  final TreatmentLocalDataSource _local;
  const TreatmentRepositoryImpl(this._local);

  @override
  Future<List<Treatment>> getTreatmentsForPet(int petId) async =>
      List<Treatment>.of(await _local.getForPet(petId));

  @override
  Future<List<Treatment>> getAllTreatments() async =>
      List<Treatment>.of(await _local.getAll());

  @override
  Future<Treatment> insertTreatment(Treatment treatment) async {
    final id = await _local.insert(TreatmentModel.fromEntity(treatment));
    return treatment.copyWith(id: id);
  }

  @override
  Future<void> updateTreatment(Treatment treatment) =>
      _local.update(TreatmentModel.fromEntity(treatment));

  @override
  Future<void> deleteTreatment(int id) => _local.delete(id);
}
