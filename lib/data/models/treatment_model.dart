import '../../domain/entities/dose_unit.dart';
import '../../domain/entities/schedule_time.dart';
import '../../domain/entities/treatment.dart';

/// Data-layer model: maps the [Treatment] entity to/from SQLite rows.
/// Rows are expected to carry a joined `medicationName` column.
class TreatmentModel extends Treatment {
  const TreatmentModel({
    super.id,
    required super.petId,
    required super.medicationId,
    super.medicationName,
    required super.doseAmount,
    required super.doseUnit,
    required super.frequencyType,
    required super.times,
    super.intervalDays,
    required super.startDate,
    super.endDate,
    super.active,
    super.notes,
  });

  factory TreatmentModel.fromEntity(Treatment t) => TreatmentModel(
        id: t.id,
        petId: t.petId,
        medicationId: t.medicationId,
        medicationName: t.medicationName,
        doseAmount: t.doseAmount,
        doseUnit: t.doseUnit,
        frequencyType: t.frequencyType,
        times: t.times,
        intervalDays: t.intervalDays,
        startDate: t.startDate,
        endDate: t.endDate,
        active: t.active,
        notes: t.notes,
      );

  static DoseUnit _unitFromName(String? name) {
    if (name == null) return DoseUnit.unit;
    try {
      return DoseUnit.values.byName(name);
    } on ArgumentError {
      return DoseUnit.unit;
    }
  }

  static String encodeTimes(List<ScheduleTime> times) =>
      times.map((t) => t.format()).join(',');

  static List<ScheduleTime> decodeTimes(String value) {
    if (value.trim().isEmpty) return [];
    return value.split(',').map((s) {
      final parts = s.split(':');
      return ScheduleTime(int.parse(parts[0]), int.parse(parts[1]));
    }).toList();
  }

  factory TreatmentModel.fromMap(Map<String, dynamic> map) => TreatmentModel(
        id: map['id'] as int?,
        petId: map['petId'] as int,
        medicationId: map['medicationId'] as int,
        medicationName: map['medicationName'] as String? ?? '',
        doseAmount: (map['doseAmount'] as num? ?? 1).toDouble(),
        doseUnit: _unitFromName(map['doseUnit'] as String?),
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

  /// Persisted columns only — `medicationName` is a joined display field.
  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'medicationId': medicationId,
        'doseAmount': doseAmount,
        'doseUnit': doseUnit.name,
        'frequencyType': frequencyType.name,
        'times': encodeTimes(times),
        'intervalDays': intervalDays,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'active': active ? 1 : 0,
        'notes': notes,
      };
}
