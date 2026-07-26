import '../../domain/entities/pet.dart';

/// Data-layer model: maps the [Pet] entity to/from SQLite rows.
class PetModel extends Pet {
  const PetModel({
    super.id,
    required super.name,
    required super.species,
    super.breed,
    super.gender,
    super.notes,
    super.photoPath,
    super.birthDate,
  });

  factory PetModel.fromEntity(Pet pet) => PetModel(
        id: pet.id,
        name: pet.name,
        species: pet.species,
        breed: pet.breed,
        gender: pet.gender,
        notes: pet.notes,
        photoPath: pet.photoPath,
        birthDate: pet.birthDate,
      );

  static PetGender? _genderFromName(String? name) {
    if (name == null) return null;
    try {
      return PetGender.values.byName(name);
    } on ArgumentError {
      return null;
    }
  }

  factory PetModel.fromMap(Map<String, dynamic> map) => PetModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        species: map['species'] as String,
        breed: map['breed'] as String?,
        gender: _genderFromName(map['gender'] as String?),
        notes: map['notes'] as String?,
        photoPath: map['photoPath'] as String?,
        birthDate: map['birthDate'] == null
            ? null
            : DateTime.parse(map['birthDate'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'species': species,
        'breed': breed,
        'gender': gender?.name,
        'notes': notes,
        'photoPath': photoPath,
        'birthDate': birthDate?.toIso8601String(),
      };
}
