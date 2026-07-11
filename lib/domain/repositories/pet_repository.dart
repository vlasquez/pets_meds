import '../entities/pet.dart';

/// Contract for pet persistence. Implemented in the data layer.
abstract interface class PetRepository {
  Future<List<Pet>> getPets();
  Future<Pet> insertPet(Pet pet);
  Future<void> updatePet(Pet pet);
  Future<void> deletePet(int id);
}
