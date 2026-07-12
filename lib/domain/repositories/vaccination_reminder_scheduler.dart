import '../entities/vaccination.dart';

/// Contract for scheduling revaccination reminders.
/// Implemented in the data layer over local notifications.
abstract interface class VaccinationReminderScheduler {
  Future<void> schedule(Vaccination vaccination,
      {required String title, required String body});
  Future<void> cancel(Vaccination vaccination);
}
