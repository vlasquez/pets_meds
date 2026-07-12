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

  Future<void> call(
    Treatment treatment, {
    required String notificationTitle,
    required String notificationBody,
    String? note,
  }) async {
    await _doseLogs.insertDoseLog(DoseLog(
      treatmentId: treatment.id!,
      petId: treatment.petId,
      givenAt: DateTime.now(),
      note: note,
    ));
    // Interval and cyclic reminders are one-shot; roll them forward.
    if (treatment.frequencyType == FrequencyType.interval ||
        treatment.frequencyType == FrequencyType.cyclic) {
      await _scheduler.schedule(treatment,
          title: notificationTitle, body: notificationBody);
    }
  }
}
