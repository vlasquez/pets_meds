import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../domain/entities/medication.dart';
import '../../../domain/entities/schedule_time.dart';

/// Wraps flutter_local_notifications: permission setup and
/// (re)scheduling of medication reminders.
class NotificationDataSource {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'pet_meds_reminders';

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Medication reminders',
          channelDescription: 'Reminders for pet medications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// One notification id per (medication, time slot).
  int _notificationId(int medicationId, int timeIndex) =>
      medicationId * 100 + timeIndex;

  Future<void> scheduleMedication(Medication med,
      {required String title, required String body}) async {
    await cancelMedication(med);
    if (!med.active || med.id == null) return;
    if (med.endDate != null && med.endDate!.isBefore(DateTime.now())) return;

    for (var i = 0; i < med.times.length; i++) {
      final time = med.times[i];
      final id = _notificationId(med.id!, i);

      if (med.frequencyType == FrequencyType.daily) {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          _nextInstanceOf(time),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        // Every N days: schedule the next single occurrence.
        // Rescheduled when a dose is logged or when the app starts.
        final next = _nextIntervalOccurrence(med, time);
        if (next != null) {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            next,
            _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    }
  }

  Future<void> cancelMedication(Medication med) async {
    if (med.id == null) return;
    // Cancel up to 100 possible time slots for this medication.
    for (var i = 0; i < 100; i++) {
      await _plugin.cancel(_notificationId(med.id!, i));
    }
  }

  tz.TZDateTime _nextInstanceOf(ScheduleTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime? _nextIntervalOccurrence(Medication med, ScheduleTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(tz.local, med.startDate.year,
        med.startDate.month, med.startDate.day, time.hour, time.minute);
    while (!candidate.isAfter(now)) {
      candidate = candidate.add(Duration(days: med.intervalDays));
    }
    if (med.endDate != null &&
        candidate.isAfter(tz.TZDateTime(tz.local, med.endDate!.year,
            med.endDate!.month, med.endDate!.day, 23, 59))) {
      return null;
    }
    return candidate;
  }
}
