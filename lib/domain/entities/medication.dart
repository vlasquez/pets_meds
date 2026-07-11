import 'package:equatable/equatable.dart';

import 'dose_unit.dart';
import 'schedule_time.dart';

enum FrequencyType { daily, intervalDays }

/// Domain entity: a medication and its dosing schedule.
class Medication extends Equatable {
  final int? id;
  final int petId;
  final String name;
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

  const Medication({
    this.id,
    required this.petId,
    required this.name,
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

  Medication copyWith({
    int? id,
    int? petId,
    String? name,
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
      Medication(
        id: id ?? this.id,
        petId: petId ?? this.petId,
        name: name ?? this.name,
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

  @override
  List<Object?> get props => [
        id,
        petId,
        name,
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
