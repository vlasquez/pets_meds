import '../../domain/entities/medication.dart';
import '../../domain/entities/schedule_time.dart';

/// Data-layer model: maps the [Medication] entity to/from SQLite rows.
class MedicationModel extends Medication {
  const MedicationModel({
    super.id,
    required super.petId,
    required super.name,
    required super.dosage,
    required super.frequencyType,
    required super.times,
    super.intervalDays,
    required super.startDate,
    super.endDate,
    super.active,
    super.notes,
  });

  factory MedicationModel.fromEntity(Medication med) => MedicationModel(
        id: med.id,
        petId: med.petId,
        name: med.name,
        dosage: med.dosage,
        frequencyType: med.frequencyType,
        times: med.times,
        intervalDays: med.intervalDays,
        startDate: med.startDate,
        endDate: med.endDate,
        active: med.active,
        notes: med.notes,
      );

  static String encodeTimes(List<ScheduleTime> times) =>
      times.map((t) => t.format()).join(',');

  static List<ScheduleTime> decodeTimes(String value) {
    if (value.trim().isEmpty) return [];
    return value.split(',').map((s) {
      final parts = s.split(':');
      return ScheduleTime(int.parse(parts[0]), int.parse(parts[1]));
    }).toList();
  }

  factory MedicationModel.fromMap(Map<String, dynamic> map) => MedicationModel(
        id: map['id'] as int?,
        petId: map['petId'] as int,
        name: map['name'] as String,
        dosage: map['dosage'] as String,
        frequencyType:
            FrequencyType.values.byName(map['frequencyType'] as String),
        times: decodeTimes(map['times'] as String),
        intervalDays: map['intervalDays'] as int? ?? 1,
        startDate: DateTime.parse(map['startDate'] as String),
        endDate: map['endDate'] == null
            ? null
            : DateTime.parse(map['endDate'] as String),
        active: (map['active'] as int? ?? 1) == 1,
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'name': name,
        'dosage': dosage,
        'frequencyType': frequencyType.name,
        'times': encodeTimes(times),
        'intervalDays': intervalDays,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'active': active ? 1 : 0,
        'notes': notes,
      };
}
