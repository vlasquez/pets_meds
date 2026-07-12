import 'package:equatable/equatable.dart';

import 'dose_unit.dart';
import 'schedule_time.dart';

enum FrequencyType { daily, intervalDays }

/// Domain entity: a treatment — a [Medication] from the catalog assigned
/// to one pet, with its dosing schedule. A medication can back many
/// treatments (1-to-many).
class Treatment extends Equatable {
  final int? id;
  final int petId;

  /// The catalog medication this treatment applies.
  final int medicationId;

  /// Denormalized medication name (joined by the repository for display).
  final String medicationName;

  final double doseAmount; // e.g. 2 (pills), 5 (mg)
  final DoseUnit doseUnit;
  final FrequencyType frequencyType;

  /// For [FrequencyType.daily]: one or more times of day.
  /// For [FrequencyType.intervalDays]: a single time of day.
  final List<ScheduleTime> times;

  /// Only used when [frequencyType] == intervalDays (e.g. every 3 days).
  final int intervalDays;

  final DateTime startDate;
  final DateTime? endDate;
  final bool active;
  final String? notes;

  const Treatment({
    this.id,
    required this.petId,
    required this.medicationId,
    this.medicationName = '',
    required this.doseAmount,
    required this.doseUnit,
    required this.frequencyType,
    required this.times,
    this.intervalDays = 1,
    required this.startDate,
    this.endDate,
    this.active = true,
    this.notes,
  });

  Treatment copyWith({
    int? id,
    int? petId,
    int? medicationId,
    String? medicationName,
    double? doseAmount,
    DoseUnit? doseUnit,
    FrequencyType? frequencyType,
    List<ScheduleTime>? times,
    int? intervalDays,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    String? notes,
  }) =>
      Treatment(
        id: id ?? this.id,
        petId: petId ?? this.petId,
        medicationId: medicationId ?? this.medicationId,
        medicationName: medicationName ?? this.medicationName,
        doseAmount: doseAmount ?? this.doseAmount,
        doseUnit: doseUnit ?? this.doseUnit,
        frequencyType: frequencyType ?? this.frequencyType,
        times: times ?? this.times,
        intervalDays: intervalDays ?? this.intervalDays,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        active: active ?? this.active,
        notes: notes ?? this.notes,
      );

  /// Whether a dose is scheduled on [day] (date only, time ignored):
  /// the treatment is active, within its start/end range, and — for
  /// interval-based schedules — [day] falls on a multiple of the interval.
  bool isScheduledOn(DateTime day) {
    if (!active) return false;
    final date = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    if (date.isBefore(start)) return false;
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (date.isAfter(end)) return false;
    }
    if (frequencyType == FrequencyType.daily) return true;
    final daysSinceStart = date.difference(start).inDays;
    return daysSinceStart % intervalDays == 0;
  }

  @override
  List<Object?> get props => [
        id,
        petId,
        medicationId,
        medicationName,
        doseAmount,
        doseUnit,
        frequencyType,
        times,
        intervalDays,
        startDate,
        endDate,
        active,
        notes,
      ];
}
