import 'package:equatable/equatable.dart';

/// Domain entity: a pet. Pure Dart — no UI or persistence details.
class Pet extends Equatable {
  final int? id;
  final String name;
  final String species; // dog, cat, other
  final String? notes;

  const Pet({this.id, required this.name, required this.species, this.notes});

  Pet copyWith({int? id, String? name, String? species, String? notes}) => Pet(
        id: id ?? this.id,
        name: name ?? this.name,
        species: species ?? this.species,
        notes: notes ?? this.notes,
      );

  @override
  List<Object?> get props => [id, name, species, notes];
}
