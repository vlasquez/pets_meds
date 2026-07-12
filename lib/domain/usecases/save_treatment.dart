import '../entities/treatment.dart';
import '../repositories/reminder_scheduler.dart';
import '../repositories/treatment_repository.dart';

/// Inserts or updates a treatment and (re)schedules its reminders.
class SaveTreatment {
  final TreatmentRepository _treatments;
  final ReminderScheduler _scheduler;

  const SaveTreatment(this._treatments, this._scheduler);

  Future<Treatment> call(
    Treatment treatment, {
    required String notificationTitle,
    required String notificationBody,
  }) async {
    Treatment saved;
    if (treatment.id == null) {
      saved = await _treatments.insertTreatment(treatment);
    } else {
      await _treatments.updateTreatment(treatment);
      saved = treatment;
    }
    await _scheduler.schedule(saved,
        title: notificationTitle, body: notificationBody);
    return saved;
  }
}
