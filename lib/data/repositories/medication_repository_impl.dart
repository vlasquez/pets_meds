import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/local/medication_local_datasource.dart';
import '../models/medication_model.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final MedicationLocalDataSource _local;
  const MedicationRepositoryImpl(this._local);

  @override
  Future<List<Medication>> getMedicationsForPet(int petId) =>
      _local.getForPet(petId);

  @override
  Future<Medication> insertMedication(Medication medication) async {
    final id = await _local.insert(MedicationModel.fromEntity(medication));
    return medication.copyWith(id: id);
  }

  @override
  Future<void> updateMedication(Medication medication) =>
      _local.update(MedicationModel.fromEntity(medication));

  @override
  Future<void> deleteMedication(int id) => _local.delete(id);
}
