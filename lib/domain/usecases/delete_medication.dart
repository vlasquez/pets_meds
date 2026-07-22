import '../repositories/medication_repository.dart';
import '../repositories/reminder_scheduler.dart';
import '../repositories/treatment_repository.dart';

/// Deletes a catalog medication. Any treatments using it (and their dose
/// logs) are removed by cascade, so their pending reminders are cancelled
/// first to avoid orphaned notifications.
class DeleteMedication {
  final MedicationRepository _medications;
  final TreatmentRepository _treatments;
  final ReminderScheduler _scheduler;

  const DeleteMedication(this._medications, this._treatments, this._scheduler);

  Future<void> call(int medicationId) async {
    final treatments = await _treatments.getAllTreatments();
    for (final t in treatments.where((t) => t.medicationId == medicationId)) {
      await _scheduler.cancel(t);
    }
    await _medications.deleteMedication(medicationId);
  }
}
