import 'package:equatable/equatable.dart';

/// Domain entity: a pet. Pure Dart — no UI or persistence details.
class Pet extends Equatable {
  final int? id;
  final String name;
  final String species; // dog, cat, other
  final String? notes;

  /// Local file path of the pet's photo, if any.
  final String? photoPath;

  final DateTime? birthDate;

  const Pet({
    this.id,
    required this.name,
    required this.species,
    this.notes,
    this.photoPath,
    this.birthDate,
  });

  Pet copyWith({
    int? id,
    String? name,
    String? species,
    String? notes,
    String? photoPath,
    DateTime? birthDate,
  }) =>
      Pet(
        id: id ?? this.id,
        name: name ?? this.name,
        species: species ?? this.species,
        notes: notes ?? this.notes,
        photoPath: photoPath ?? this.photoPath,
        birthDate: birthDate ?? this.birthDate,
      );

  /// Age as (years, months) relative to [now], or null when birthDate is unset.
  (int years, int months)? ageAt(DateTime now) {
    final birth = birthDate;
    if (birth == null || birth.isAfter(now)) return null;
    var years = now.year - birth.year;
    var months = now.month - birth.month;
    if (now.day < birth.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    return (years, months);
  }

  @override
  List<Object?> get props => [id, name, species, notes, photoPath, birthDate];
}
