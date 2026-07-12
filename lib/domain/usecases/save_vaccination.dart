import '../entities/vaccination.dart';
import '../repositories/vaccination_reminder_scheduler.dart';
import '../repositories/vaccination_repository.dart';

/// Inserts a vaccination and schedules its revaccination reminder (if any).
class SaveVaccination {
  final VaccinationRepository _vaccinations;
  final VaccinationReminderScheduler _scheduler;

  const SaveVaccination(this._vaccinations, this._scheduler);

  Future<Vaccination> call(
    Vaccination vaccination, {
    required String notificationTitle,
    required String notificationBody,
  }) async {
    final saved = await _vaccinations.insertVaccination(vaccination);
    await _scheduler.schedule(saved,
        title: notificationTitle, body: notificationBody);
    return saved;
  }
}
