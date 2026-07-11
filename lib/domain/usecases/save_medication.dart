import '../entities/medication.dart';
import '../repositories/medication_repository.dart';
import '../repositories/reminder_scheduler.dart';

/// Inserts or updates a medication and (re)schedules its reminders.
class SaveMedication {
  final MedicationRepository _medications;
  final ReminderScheduler _scheduler;

  const SaveMedication(this._medications, this._scheduler);

  Future<Medication> call(
    Medication medication, {
    required String notificationTitle,
    required String notificationBody,
  }) async {
    Medication saved;
    if (medication.id == null) {
      saved = await _medications.insertMedication(medication);
    } else {
      await _medications.updateMedication(medication);
      saved = medication;
    }
    await _scheduler.schedule(saved,
        title: notificationTitle, body: notificationBody);
    return saved;
  }
}
