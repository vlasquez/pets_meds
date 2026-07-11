import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

/// Inserts the pet when it has no id, updates it otherwise.
class SavePet {
  final PetRepository _repository;
  const SavePet(this._repository);

  Future<Pet> call(Pet pet) async {
    if (pet.id == null) return _repository.insertPet(pet);
    await _repository.updatePet(pet);
    return pet;
  }
}
