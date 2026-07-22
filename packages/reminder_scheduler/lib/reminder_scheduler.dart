/// Reusable local-notification reminder scheduler.
///
/// Host apps depend only on the generic model here ([ReminderRequest],
/// [ReminderTrigger] and friends) and map their own domain objects into
/// it — this package has no knowledge of any app's models.
library reminder_scheduler;

export 'src/reminder_models.dart';
export 'src/reminder_scheduler.dart';
export 'src/local_notifications_reminder_scheduler.dart';
