import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../datasources/local/pet_local_datasource.dart';
import '../models/pet_model.dart';

class PetRepositoryImpl implements PetRepository {
  final PetLocalDataSource _local;
  const PetRepositoryImpl(this._local);

  @override
  Future<List<Pet>> getPets() => _local.getPets();

  @override
  Future<Pet> insertPet(Pet pet) async {
    final id = await _local.insert(PetModel.fromEntity(pet));
    return pet.copyWith(id: id);
  }

  @override
  Future<void> updatePet(Pet pet) => _local.update(PetModel.fromEntity(pet));

  @override
  Future<void> deletePet(int id) => _local.delete(id);
}
