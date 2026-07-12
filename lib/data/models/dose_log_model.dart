import '../../domain/entities/dose_log.dart';

/// Data-layer model: maps the [DoseLog] entity to/from SQLite rows.
class DoseLogModel extends DoseLog {
  const DoseLogModel({
    super.id,
    required super.treatmentId,
    required super.petId,
    required super.givenAt,
    super.note,
  });

  factory DoseLogModel.fromEntity(DoseLog log) => DoseLogModel(
        id: log.id,
        treatmentId: log.treatmentId,
        petId: log.petId,
        givenAt: log.givenAt,
        note: log.note,
      );

  factory DoseLogModel.fromMap(Map<String, dynamic> map) => DoseLogModel(
        id: map['id'] as int?,
        treatmentId: map['treatmentId'] as int,
        petId: map['petId'] as int,
        givenAt: DateTime.parse(map['givenAt'] as String),
        note: map['note'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'treatmentId': treatmentId,
        'petId': petId,
        'givenAt': givenAt.toIso8601String(),
        'note': note,
      };
}
