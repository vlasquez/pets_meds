import '../entities/vaccination.dart';
import '../repositories/vaccination_reminder_scheduler.dart';
import '../repositories/vaccination_repository.dart';

/// Deletes a vaccination and cancels its pending reminder.
class DeleteVaccination {
  final VaccinationRepository _vaccinations;
  final VaccinationReminderScheduler _scheduler;

  const DeleteVaccination(this._vaccinations, this._scheduler);

  Future<void> call(Vaccination vaccination) async {
    await _scheduler.cancel(vaccination);
    await _vaccinations.deleteVaccination(vaccination.id!);
  }
}
