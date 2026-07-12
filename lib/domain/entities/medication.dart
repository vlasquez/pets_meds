import 'package:equatable/equatable.dart';

/// Domain entity: a medication in the catalog (e.g. "Amoxicilina").
/// Standalone — treatments reference it to assign it to a pet
/// with a dosing schedule (1 medication → many treatments).
class Medication extends Equatable {
  final int? id;
  final String name;
  final String? notes;

  const Medication({this.id, required this.name, this.notes});

  Medication copyWith({int? id, String? name, String? notes}) => Medication(
        id: id ?? this.id,
        name: name ?? this.name,
        notes: notes ?? this.notes,
      );

  @override
  List<Object?> get props => [id, name, notes];
}
