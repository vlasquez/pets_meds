import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_models.dart';
import 'reminder_scheduler.dart';

/// [ReminderScheduler] backed by flutter_local_notifications. Handles
/// permission setup, timezone-aware scheduling and per-group id
/// allocation. Scheduled reminders are delivered by the OS even when
/// the app is closed, and survive reboot via the plugin's boot receiver.
class LocalNotificationsReminderScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderSchedulerConfig config;

  LocalNotificationsReminderScheduler({
    this.config = const ReminderSchedulerConfig(),
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    final androidInit =
        AndroidInitializationSettings(config.androidDefaultIcon);
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
    );
  }

  @override
  Future<bool?> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      // Needed for exact alarms on Android 12–13 (API 31/32) where the
      // SCHEDULE_EXACT_ALARM permission must be granted by the user.
      // On API 33+ USE_EXACT_ALARM (in the manifest) covers it.
      await android.requestExactAlarmsPermission();
      return granted;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return ios.requestPermissions(alert: true, badge: true, sound: true);
    }
    return null;
  }

  NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(
          config.androidChannelId,
          config.androidChannelName,
          channelDescription: config.androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  int _idFor(int groupId, int slot) => groupId * config.slotsPerGroup + slot;

  @override
  Future<void> schedule(ReminderRequest request) async {
    await cancelGroup(request.groupId);

    var slot = 0;
    for (final trigger in request.triggers) {
      if (slot >= config.slotsPerGroup) break; // Safety: don't overflow.
      final id = _idFor(request.groupId, slot);

      switch (trigger) {
        case DailyTrigger(:final time):
          await _zoned(id, request, _nextInstanceOf(time),
              match: DateTimeComponents.time);
          slot++;
        case WeeklyTrigger(:final weekday, :final time):
          await _zoned(id, request, _nextInstanceOfWeekday(weekday, time),
              match: DateTimeComponents.dayOfWeekAndTime);
          slot++;
        case OneShotTrigger(:final dateTime):
          final when = tz.TZDateTime.from(dateTime, tz.local);
          if (when.isAfter(tz.TZDateTime.now(tz.local))) {
            await _zoned(id, request, when);
            slot++;
          }
      }
    }
  }

  Future<void> _zoned(int id, ReminderRequest request, tz.TZDateTime when,
      {DateTimeComponents? match}) {
    return _plugin.zonedSchedule(
      id,
      request.title,
      request.body,
      when,
      _details,
      // Exact so medication reminders fire on time (inexact lets Doze
      // batch them to a later maintenance window).
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: match,
    );
  }

  @override
  Future<void> cancelGroup(int groupId) async {
    for (var slot = 0; slot < config.slotsPerGroup; slot++) {
      await _plugin.cancel(_idFor(groupId, slot));
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  tz.TZDateTime _nextInstanceOf(ReminderTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, ReminderTime time) {
    var scheduled = _nextInstanceOf(time);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
