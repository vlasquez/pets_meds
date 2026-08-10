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
    super.intervalValue,
    super.intervalUnit,
    super.weekdays,
    super.cycleDaysOn,
    super.cycleDaysOff,
    required super.startDate,
    super.endDate,
    super.active,
    super.notes,
    super.dosesGiven,
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
        intervalValue: t.intervalValue,
        intervalUnit: t.intervalUnit,
        weekdays: t.weekdays,
        cycleDaysOn: t.cycleDaysOn,
        cycleDaysOff: t.cycleDaysOff,
        startDate: t.startDate,
        endDate: t.endDate,
        active: t.active,
        notes: t.notes,
      );

  static DoseUnit _doseUnitFromName(String? name) {
    if (name == null) return DoseUnit.unit;
    try {
      return DoseUnit.values.byName(name);
    } on ArgumentError {
      return DoseUnit.unit;
    }
  }

  static IntervalUnit _intervalUnitFromName(String? name) {
    if (name == null) return IntervalUnit.hours;
    try {
      return IntervalUnit.values.byName(name);
    } on ArgumentError {
      return IntervalUnit.hours;
    }
  }

  static FrequencyType _frequencyFromName(String? name) {
    // Legacy value from schemas < v8.
    if (name == 'intervalDays') return FrequencyType.interval;
    try {
      return FrequencyType.values.byName(name ?? 'daily');
    } on ArgumentError {
      return FrequencyType.daily;
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

  static String encodeWeekdays(List<int> weekdays) => weekdays.join(',');

  static List<int> decodeWeekdays(String? value) {
    if (value == null || value.trim().isEmpty) return [];
    return value.split(',').map(int.parse).toList();
  }

  factory TreatmentModel.fromMap(Map<String, dynamic> map) => TreatmentModel(
        id: map['id'] as int?,
        petId: map['petId'] as int,
        medicationId: map['medicationId'] as int,
        medicationName: map['medicationName'] as String? ?? '',
        doseAmount: (map['doseAmount'] as num? ?? 1).toDouble(),
        doseUnit: _doseUnitFromName(map['doseUnit'] as String?),
        frequencyType: _frequencyFromName(map['frequencyType'] as String?),
        times: decodeTimes(map['times'] as String),
        intervalValue: map['intervalValue'] as int? ?? 8,
        intervalUnit: _intervalUnitFromName(map['intervalUnit'] as String?),
        weekdays: decodeWeekdays(map['weekdays'] as String?),
        cycleDaysOn: map['cycleDaysOn'] as int? ?? 21,
        cycleDaysOff: map['cycleDaysOff'] as int? ?? 7,
        startDate: DateTime.parse(map['startDate'] as String),
        endDate: map['endDate'] == null
            ? null
            : DateTime.parse(map['endDate'] as String),
        active: (map['active'] as int? ?? 1) == 1,
        notes: map['notes'] as String?,
        dosesGiven: (map['dosesGiven'] as int?) ?? 0,
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
        'intervalValue': intervalValue,
        'intervalUnit': intervalUnit.name,
        'weekdays': encodeWeekdays(weekdays),
        'cycleDaysOn': cycleDaysOn,
        'cycleDaysOff': cycleDaysOff,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'active': active ? 1 : 0,
        'notes': notes,
      };
}
