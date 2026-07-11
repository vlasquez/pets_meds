import '../entities/medication.dart';

/// Contract for scheduling medication reminders.
/// Implemented in the data layer (local notifications).
abstract interface class ReminderScheduler {
  /// (Re)schedules all reminders for [medication].
  /// [title] and [body] are already-localized notification texts.
  Future<void> schedule(Medication medication,
      {required String title, required String body});

  Future<void> cancel(Medication medication);
}
