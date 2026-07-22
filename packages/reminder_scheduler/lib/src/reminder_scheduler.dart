import 'reminder_models.dart';

/// Contract for scheduling local reminders. The default implementation
/// is [LocalNotificationsReminderScheduler]; tests or other backends can
/// provide their own.
abstract interface class ReminderScheduler {
  /// Prepares the platform (timezones, plugin, channel). Call once at
  /// startup before scheduling.
  Future<void> initialize();

  /// Requests notification permission where required (Android 13+, iOS).
  /// Returns whether it is (now) granted; null if unknown.
  Future<bool?> requestPermissions();

  /// (Re)schedules all triggers of [request.groupId], replacing any
  /// previously scheduled for that group.
  Future<void> schedule(ReminderRequest request);

  /// Cancels every reminder previously scheduled for [groupId].
  Future<void> cancelGroup(int groupId);

  /// Cancels all scheduled reminders.
  Future<void> cancelAll();
}
