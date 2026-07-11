import '../entities/dose_log.dart';
import '../entities/medication.dart';
import '../repositories/dose_log_repository.dart';
import '../repositories/reminder_scheduler.dart';

/// Records that a dose was given now. For interval-based medications the
/// next reminder is rolled forward.
class LogDose {
  final DoseLogRepository _doseLogs;
  final ReminderScheduler _scheduler;

  const LogDose(this._doseLogs, this._scheduler);

  Future<void> call(
    Medication medication, {
    required String notificationTitle,
    required String notificationBody,
    String? note,
  }) async {
    await _doseLogs.insertDoseLog(DoseLog(
      medicationId: medication.id!,
      petId: medication.petId,
      givenAt: DateTime.now(),
      note: note,
    ));
    if (medication.frequencyType == FrequencyType.intervalDays) {
      await _scheduler.schedule(medication,
          title: notificationTitle, body: notificationBody);
    }
  }
}
