import 'package:equatable/equatable.dart';

/// Domain entity: a weight measurement of a pet at a point in time.
class WeightEntry extends Equatable {
  final int? id;
  final int petId;
  final double weightKg;
  final DateTime measuredAt;
  final String? note;

  const WeightEntry({
    this.id,
    required this.petId,
    required this.weightKg,
    required this.measuredAt,
    this.note,
  });

  @override
  List<Object?> get props => [id, petId, weightKg, measuredAt, note];
}
