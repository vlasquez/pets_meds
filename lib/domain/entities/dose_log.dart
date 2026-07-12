import 'package:equatable/equatable.dart';

/// Domain entity: a record of a dose that was given for a treatment.
class DoseLog extends Equatable {
  final int? id;
  final int treatmentId;
  final int petId;
  final DateTime givenAt;
  final String? note;

  const DoseLog({
    this.id,
    required this.treatmentId,
    required this.petId,
    required this.givenAt,
    this.note,
  });

  @override
  List<Object?> get props => [id, treatmentId, petId, givenAt, note];
}
