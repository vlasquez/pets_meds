import '../entities/medication.dart';
import '../repositories/medication_repository.dart';
import '../repositories/reminder_scheduler.dart';

/// Deletes a medication and cancels its reminders.
class DeleteMedication {
  final MedicationRepository _medications;
  final ReminderScheduler _scheduler;

  const DeleteMedication(this._medications, this._scheduler);

  Future<void> call(Medication medication) async {
    await _scheduler.cancel(medication);
    await _medications.deleteMedication(medication.id!);
  }
}
