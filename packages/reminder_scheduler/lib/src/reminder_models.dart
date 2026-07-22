// Generic model the scheduler understands. Host apps translate their
// own domain (treatments, tasks, habits…) into these types.

/// A time of day, 24h.
class ReminderTime {
  final int hour;
  final int minute;
  const ReminderTime(this.hour, this.minute)
      : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60);
}

/// One way a reminder repeats or fires. Sealed so hosts (and the
/// implementation) handle every case exhaustively.
sealed class ReminderTrigger {
  const ReminderTrigger();
}

/// Fires every day at [time] (OS-native daily repeat).
class DailyTrigger extends ReminderTrigger {
  final ReminderTime time;
  const DailyTrigger(this.time);
}

/// Fires weekly on [weekday] (1 = Monday … 7 = Sunday) at [time]
/// (OS-native weekly repeat).
class WeeklyTrigger extends ReminderTrigger {
  final int weekday;
  final ReminderTime time;
  const WeeklyTrigger({required this.weekday, required this.time})
      : assert(weekday >= 1 && weekday <= 7);
}

/// Fires once at [dateTime] (local time). Non-repeating — hosts that
/// need "every N days/months" or cyclic patterns compute the next
/// occurrence and re-schedule it (e.g. on app start / after logging).
class OneShotTrigger extends ReminderTrigger {
  final DateTime dateTime;
  const OneShotTrigger(this.dateTime);
}

/// A group of triggers that share a [title]/[body] and belong to one
/// owner ([groupId]). Scheduling the same [groupId] again atomically
/// replaces its previous triggers.
///
/// [groupId] must be unique per owner and stable across app runs. The
/// implementation reserves a block of notification ids per group
/// (see [ReminderSchedulerConfig.slotsPerGroup]); callers must keep
/// group ids disjoint and small enough that
/// `groupId * slotsPerGroup + slots` stays within a 32-bit int.
class ReminderRequest {
  final int groupId;
  final String title;
  final String body;
  final List<ReminderTrigger> triggers;

  const ReminderRequest({
    required this.groupId,
    required this.title,
    required this.body,
    required this.triggers,
  });
}

/// Platform configuration for the notification channel and id layout.
class ReminderSchedulerConfig {
  final String androidChannelId;
  final String androidChannelName;
  final String androidChannelDescription;

  /// Small icon resource, e.g. '@mipmap/ic_launcher'.
  final String androidDefaultIcon;

  /// Notification ids reserved per group. Must exceed the largest number
  /// of triggers any single group will have. Bounds max group id to
  /// `2^31 / slotsPerGroup`.
  final int slotsPerGroup;

  const ReminderSchedulerConfig({
    this.androidChannelId = 'reminders',
    this.androidChannelName = 'Reminders',
    this.androidChannelDescription = 'Scheduled reminders',
    this.androidDefaultIcon = '@mipmap/ic_launcher',
    this.slotsPerGroup = 64,
  });
}
