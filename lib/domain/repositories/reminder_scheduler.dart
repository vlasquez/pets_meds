import '../entities/treatment.dart';

/// Contract for scheduling treatment reminders.
/// Implemented in the data layer (local notifications).
abstract interface class ReminderScheduler {
  /// (Re)schedules all reminders for [treatment].
  /// [title] and [body] are already-localized notification texts.
  Future<void> schedule(Treatment treatment,
      {required String title, required String body});

  Future<void> cancel(Treatment treatment);
}
