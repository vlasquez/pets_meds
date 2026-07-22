import '../entities/treatment.dart';
import '../repositories/reminder_scheduler.dart';
import '../repositories/treatment_repository.dart';
import 'get_pets.dart';

/// Re-schedules reminders for every active treatment. Run at app start
/// so one-shot schedules (day/month intervals and cyclic treatments),
/// which only ever queue their next occurrence, keep going even if the
/// user never reopens the app after a reminder fires.
///
/// Daily/weekly/hourly repeats are OS-native and idempotent to reschedule.
class RescheduleReminders {
  final GetPets _getPets;
  final TreatmentRepository _treatments;
  final ReminderScheduler _scheduler;

  const RescheduleReminders(this._getPets, this._treatments, this._scheduler);

  /// [title] receives the pet's name; [body] receives the treatment.
  /// These stay in the caller so localization lives in the UI layer.
  Future<void> call({
    required String Function(String petName) title,
    required String Function(Treatment treatment) body,
  }) async {
    final pets = await _getPets();
    final petNames = {for (final p in pets) p.id: p.name};
    final treatments = await _treatments.getAllTreatments();
    for (final t in treatments) {
      await _scheduler.schedule(
        t,
        title: title(petNames[t.petId] ?? ''),
        body: body(t),
      );
    }
  }
}
