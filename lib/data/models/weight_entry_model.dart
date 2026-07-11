import '../../domain/entities/weight_entry.dart';

/// Data-layer model: maps the [WeightEntry] entity to/from SQLite rows.
class WeightEntryModel extends WeightEntry {
  const WeightEntryModel({
    super.id,
    required super.petId,
    required super.weightKg,
    required super.measuredAt,
    super.note,
  });

  factory WeightEntryModel.fromEntity(WeightEntry entry) => WeightEntryModel(
        id: entry.id,
        petId: entry.petId,
        weightKg: entry.weightKg,
        measuredAt: entry.measuredAt,
        note: entry.note,
      );

  factory WeightEntryModel.fromMap(Map<String, dynamic> map) =>
      WeightEntryModel(
        id: map['id'] as int?,
        petId: map['petId'] as int,
        weightKg: (map['weightKg'] as num).toDouble(),
        measuredAt: DateTime.parse(map['measuredAt'] as String),
        note: map['note'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'weightKg': weightKg,
        'measuredAt': measuredAt.toIso8601String(),
        'note': note,
      };
}
