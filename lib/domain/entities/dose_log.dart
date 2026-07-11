import 'package:equatable/equatable.dart';

/// Domain entity: a record of a dose that was given.
class DoseLog extends Equatable {
  final int? id;
  final int medicationId;
  final int petId;
  final DateTime givenAt;
  final String? note;

  const DoseLog({
    this.id,
    required this.medicationId,
    required this.petId,
    required this.givenAt,
    this.note,
  });

  @override
  List<Object?> get props => [id, medicationId, petId, givenAt, note];
}
