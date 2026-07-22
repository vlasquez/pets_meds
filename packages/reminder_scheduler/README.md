# reminder_scheduler

A small, reusable Flutter package for scheduling local-notification
reminders. It exposes a **generic contract** so any app can use it
without leaking its own domain models into the package.

## Concept

The package knows only about a generic model:

- `ReminderRequest` — a `groupId`, a `title`/`body`, and a list of
  `ReminderTrigger`s.
- `ReminderTrigger` (sealed): `DailyTrigger`, `WeeklyTrigger`,
  `OneShotTrigger`.

Your app maps its own models (treatments, tasks, habits…) into these
types. Repeating patterns the OS can't express natively (every N
days/months, cyclic on/off) are represented as a `OneShotTrigger` for
the next occurrence, which the app re-schedules on startup / after the
user acts.

## Usage

```dart
final scheduler = LocalNotificationsReminderScheduler(
  config: const ReminderSchedulerConfig(
    androidChannelId: 'my_reminders',
    androidChannelName: 'Reminders',
    androidChannelDescription: 'Scheduled reminders',
  ),
);

await scheduler.initialize();
await scheduler.requestPermissions();

await scheduler.schedule(ReminderRequest(
  groupId: task.id,               // unique & stable per owner
  title: 'Time for ${task.name}',
  body: 'Tap to open',
  triggers: [
    DailyTrigger(ReminderTime(8, 0)),
    DailyTrigger(ReminderTime(20, 0)),
  ],
));

// Replace this group's reminders by scheduling the same groupId again,
// or remove them:
await scheduler.cancelGroup(task.id);
```

## Notes

- Reminders are delivered by the OS even when the app is closed and
  survive reboot (via flutter_local_notifications' boot receiver — add
  the standard manifest entries and `RECEIVE_BOOT_COMPLETED` in the
  host app).
- `groupId` reserves `slotsPerGroup` (default 64) notification ids;
  keep group ids disjoint and small enough that
  `groupId * slotsPerGroup` stays within a 32-bit int.
- Android alarms use inexact scheduling (no special permission); timing
  may drift a few minutes under Doze.

## Host manifest (Android)

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<!-- plus the flutter_local_notifications ScheduledNotification receivers -->
```
