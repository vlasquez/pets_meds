import '../../domain/entities/pet.dart';

/// Data-layer model: maps the [Pet] entity to/from SQLite rows.
class PetModel extends Pet {
  const PetModel({super.id, required super.name, required super.species, super.notes});

  factory PetModel.fromEntity(Pet pet) => PetModel(
        id: pet.id,
        name: pet.name,
        species: pet.species,
        notes: pet.notes,
      );

  factory PetModel.fromMap(Map<String, dynamic> map) => PetModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        species: map['species'] as String,
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'species': species,
        'notes': notes,
      };
}
