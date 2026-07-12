import '../../domain/entities/medication.dart';

/// Data-layer model: maps the catalog [Medication] to/from SQLite rows.
class MedicationModel extends Medication {
  const MedicationModel({super.id, required super.name, super.notes});

  factory MedicationModel.fromEntity(Medication med) =>
      MedicationModel(id: med.id, name: med.name, notes: med.notes);

  factory MedicationModel.fromMap(Map<String, dynamic> map) => MedicationModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'notes': notes,
      };
}
