import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

class GetPets {
  final PetRepository _repository;
  const GetPets(this._repository);

  Future<List<Pet>> call() => _repository.getPets();
}
