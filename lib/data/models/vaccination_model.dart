import '../../domain/entities/vaccination.dart';

/// Data-layer model: maps the [Vaccination] entity to/from SQLite rows.
class VaccinationModel extends Vaccination {
  const VaccinationModel({
    super.id,
    required super.petId,
    required super.vaccineType,
    required super.appliedAt,
    super.reminderValue,
    super.reminderUnit,
    super.notes,
  });

  factory VaccinationModel.fromEntity(Vaccination v) => VaccinationModel(
        id: v.id,
        petId: v.petId,
        vaccineType: v.vaccineType,
        appliedAt: v.appliedAt,
        reminderValue: v.reminderValue,
        reminderUnit: v.reminderUnit,
        notes: v.notes,
      );

  static ReminderUnit? _unitFromName(String? name) {
    if (name == null) return null;
    try {
      return ReminderUnit.values.byName(name);
    } on ArgumentError {
      return null;
    }
  }

  factory VaccinationModel.fromMap(Map<String, dynamic> map) =>
      VaccinationModel(
        id: map['id'] as int?,
        petId: map['petId'] as int,
        vaccineType: map['vaccineType'] as String,
        appliedAt: DateTime.parse(map['appliedAt'] as String),
        reminderValue: map['reminderValue'] as int?,
        reminderUnit: _unitFromName(map['reminderUnit'] as String?),
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'vaccineType': vaccineType,
        'appliedAt': appliedAt.toIso8601String(),
        'reminderValue': reminderValue,
        'reminderUnit': reminderUnit?.name,
        'notes': notes,
      };
}
