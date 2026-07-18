import '../entities/dose_log.dart';
import '../entities/treatment.dart';
import '../repositories/dose_log_repository.dart';
import '../repositories/reminder_scheduler.dart';

/// Records that a dose was given now. For interval-based treatments the
/// next reminder is rolled forward.
class LogDose {
  final DoseLogRepository _doseLogs;
  final ReminderScheduler _scheduler;

  const LogDose(this._doseLogs, this._scheduler);

  /// Logs a dose, at [givenAt] when provided (e.g. checking a past day
  /// from the Progress screen) or now otherwise.
  Future<void> call(
    Treatment treatment, {
    required String notificationTitle,
    required String notificationBody,
    String? note,
    DateTime? givenAt,
  }) async {
    final at = givenAt ?? DateTime.now();
    await _doseLogs.insertDoseLog(DoseLog(
      treatmentId: treatment.id!,
      petId: treatment.petId,
      givenAt: at,
      note: note,
    ));
    // Interval and cyclic reminders are one-shot; roll them forward.
    // Backdated logs don't affect upcoming reminders.
    final now = DateTime.now();
    final isToday =
        at.year == now.year && at.month == now.month && at.day == now.day;
    if (isToday &&
        (treatment.frequencyType == FrequencyType.interval ||
            treatment.frequencyType == FrequencyType.cyclic)) {
      await _scheduler.schedule(treatment,
          title: notificationTitle, body: notificationBody);
    }
  }
}
