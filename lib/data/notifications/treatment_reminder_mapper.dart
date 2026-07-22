import 'package:reminder_scheduler/reminder_scheduler.dart';

import '../../domain/entities/schedule_time.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/vaccination.dart';

/// Maps app domain models to the reminder package's generic model.
///
/// This is the ONLY place that knows both sides; the package stays free
/// of any app model. Group ids are namespaced so treatments and
/// vaccinations never collide:
///   treatments:    groupId = treatmentId
///   vaccinations:  groupId = _vaccinationBase + vaccinationId
/// (kept small enough for the package's 32-bit id math).
class ReminderMapper {
  static const _vaccinationBase = 1000000;

  static int treatmentGroupId(int treatmentId) => treatmentId;
  static int vaccinationGroupId(int vaccinationId) =>
      _vaccinationBase + vaccinationId;

  static ReminderTime _time(ScheduleTime t) => ReminderTime(t.hour, t.minute);

  /// Triggers for a treatment. Repeating frequencies map to native
  /// daily/weekly repeats; day/month-interval and cyclic frequencies map
  /// to the single next occurrence (re-armed on app start / dose log).
  /// Returns empty when inactive, on demand, or already ended.
  static List<ReminderTrigger> triggersForTreatment(Treatment t) {
    if (!t.active) return const [];
    if (t.endDate != null && t.endDate!.isBefore(DateTime.now())) {
      return const [];
    }

    switch (t.frequencyType) {
      case FrequencyType.onDemand:
        return const [];
      case FrequencyType.daily:
        return [for (final time in t.times) DailyTrigger(_time(time))];
      case FrequencyType.weekdays:
        return [
          for (final weekday in t.weekdays)
            for (final time in t.times)
              WeeklyTrigger(weekday: weekday, time: _time(time)),
        ];
      case FrequencyType.interval:
        if (t.intervalUnit == IntervalUnit.hours) {
          // Repeats daily at each generated intake hour.
          return [
            for (final time in t.intakeTimesPerDay) DailyTrigger(_time(time)),
          ];
        }
        return _nextOccurrenceTriggers(t);
      case FrequencyType.cyclic:
        return _nextOccurrenceTriggers(t);
    }
  }

  /// One-shot trigger(s) at the next scheduled day for each time of day.
  static List<ReminderTrigger> _nextOccurrenceTriggers(Treatment t) {
    final triggers = <ReminderTrigger>[];
    for (final time in t.times) {
      final next = _nextScheduledDate(t, time);
      if (next != null) triggers.add(OneShotTrigger(next));
    }
    return triggers;
  }

  /// Next date on/after today where the treatment is scheduled and the
  /// [time] is still in the future, bounded by end date. Scans forward.
  static DateTime? _nextScheduledDate(Treatment t, ScheduleTime time) {
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 800; i++) {
      if (t.isScheduledOn(day)) {
        final candidate =
            DateTime(day.year, day.month, day.day, time.hour, time.minute);
        if (candidate.isAfter(now)) {
          if (t.endDate != null) {
            final end = DateTime(
                t.endDate!.year, t.endDate!.month, t.endDate!.day, 23, 59);
            if (candidate.isAfter(end)) return null;
          }
          return candidate;
        }
      }
      day = day.add(const Duration(days: 1));
    }
    return null;
  }

  /// A vaccination reminder at 09:00 on its next due date, if any.
  static List<ReminderTrigger> triggersForVaccination(Vaccination v) {
    final due = v.nextDueDate;
    if (due == null) return const [];
    return [OneShotTrigger(DateTime(due.year, due.month, due.day, 9, 0))];
  }
}
