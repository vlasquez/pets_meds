import 'package:equatable/equatable.dart';

import 'dose_unit.dart';
import 'schedule_time.dart';

enum FrequencyType {
  /// Every day at [Treatment.times].
  daily,

  /// Every [Treatment.intervalValue] [Treatment.intervalUnit]
  /// (hours, days or months).
  interval,

  /// On specific days of the week ([Treatment.weekdays], 1=Mon … 7=Sun).
  weekdays,

  /// Cyclic: [Treatment.cycleDaysOn] days of treatment followed by
  /// [Treatment.cycleDaysOff] days of rest, repeating from [startDate].
  cyclic,

  /// No schedule — given when needed. No reminders.
  onDemand,
}

enum IntervalUnit { hours, days, months }

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

  /// Times of day. Not used for [FrequencyType.onDemand] or hour-based
  /// intervals; a single time for day/month intervals.
  final List<ScheduleTime> times;

  /// Only used when [frequencyType] == interval (e.g. every 8 hours).
  final int intervalValue;
  final IntervalUnit intervalUnit;

  /// Only used when [frequencyType] == weekdays (1=Mon … 7=Sun).
  final List<int> weekdays;

  /// Only used when [frequencyType] == cyclic.
  final int cycleDaysOn;
  final int cycleDaysOff;

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
    this.intervalValue = 8,
    this.intervalUnit = IntervalUnit.hours,
    this.weekdays = const [],
    this.cycleDaysOn = 21,
    this.cycleDaysOff = 7,
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
    int? intervalValue,
    IntervalUnit? intervalUnit,
    List<int>? weekdays,
    int? cycleDaysOn,
    int? cycleDaysOff,
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
        intervalValue: intervalValue ?? this.intervalValue,
        intervalUnit: intervalUnit ?? this.intervalUnit,
        weekdays: weekdays ?? this.weekdays,
        cycleDaysOn: cycleDaysOn ?? this.cycleDaysOn,
        cycleDaysOff: cycleDaysOff ?? this.cycleDaysOff,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        active: active ?? this.active,
        notes: notes ?? this.notes,
      );

  /// Days remaining until [endDate] (0 = ends today, negative = already
  /// over), or null when the treatment has no end date.
  int? remainingDays(DateTime now) {
    if (endDate == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return end.difference(today).inDays;
  }

  /// [date] plus [months] calendar months, clamped to the target
  /// month's last day (Jan 31 + 1 month = Feb 28/29).
  static DateTime addMonths(DateTime date, int months) {
    final totalMonths = date.month - 1 + months;
    final year = date.year + totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }

  /// The intake hours of a scheduled day. For hour-based intervals the
  /// hours are generated from the first intake time ([times.first])
  /// stepping [intervalValue] hours until midnight (e.g. first intake
  /// 08:00 every 12 h → 08:00, 20:00). Empty for on-demand.
  List<ScheduleTime> get intakeTimesPerDay {
    switch (frequencyType) {
      case FrequencyType.daily:
      case FrequencyType.weekdays:
      case FrequencyType.cyclic:
        return List.of(times)..sort();
      case FrequencyType.interval:
        switch (intervalUnit) {
          case IntervalUnit.hours:
            final first =
                times.isEmpty ? const ScheduleTime(8, 0) : times.first;
            if (intervalValue <= 0 || intervalValue >= 24) return [first];
            // Full 24 h cycle from the first intake, wrapping past
            // midnight (e.g. 08:00 every 8 h → 08:00, 16:00, 00:00).
            final result = <ScheduleTime>[];
            final start = first.inMinutes;
            var minutes = start;
            while (minutes < start + 24 * 60) {
              result.add(ScheduleTime((minutes ~/ 60) % 24, minutes % 60));
              minutes += intervalValue * 60;
            }
            return result;
          case IntervalUnit.days:
          case IntervalUnit.months:
            return times.isEmpty
                ? const [ScheduleTime(8, 0)]
                : [times.first];
        }
      case FrequencyType.onDemand:
        return const [];
    }
  }

  /// Number of intakes expected on a scheduled day. The treatment is
  /// complete for the day once this many doses were logged.
  int get dosesPerDay {
    final intakes = intakeTimesPerDay.length;
    return intakes == 0 ? 1 : intakes;
  }

  /// Whether a dose is scheduled (or available, for on-demand) on [day]
  /// (date only, time ignored): the treatment is active, within its
  /// start/end range, and [day] matches the frequency pattern.
  bool isScheduledOn(DateTime day) {
    if (!active) return false;
    final date = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    if (date.isBefore(start)) return false;
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (date.isAfter(end)) return false;
    }
    switch (frequencyType) {
      case FrequencyType.daily:
      case FrequencyType.onDemand:
        return true;
      case FrequencyType.interval:
        switch (intervalUnit) {
          case IntervalUnit.hours:
            return true; // Repeats within every day.
          case IntervalUnit.days:
            return date.difference(start).inDays % intervalValue == 0;
          case IntervalUnit.months:
            var candidate = start;
            while (candidate.isBefore(date)) {
              candidate = addMonths(candidate, intervalValue);
            }
            return candidate == date;
        }
      case FrequencyType.weekdays:
        return weekdays.contains(date.weekday);
      case FrequencyType.cyclic:
        final cycle = cycleDaysOn + cycleDaysOff;
        if (cycle <= 0) return false;
        return date.difference(start).inDays % cycle < cycleDaysOn;
    }
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
        intervalValue,
        intervalUnit,
        weekdays,
        cycleDaysOn,
        cycleDaysOff,
        startDate,
        endDate,
        active,
        notes,
      ];
}
