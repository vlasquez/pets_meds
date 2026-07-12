import '../entities/treatment.dart';
import '../repositories/reminder_scheduler.dart';
import '../repositories/treatment_repository.dart';

/// Deletes a treatment and cancels its reminders.
class DeleteTreatment {
  final TreatmentRepository _treatments;
  final ReminderScheduler _scheduler;

  const DeleteTreatment(this._treatments, this._scheduler);

  Future<void> call(Treatment treatment) async {
    await _scheduler.cancel(treatment);
    await _treatments.deleteTreatment(treatment.id!);
  }
}
