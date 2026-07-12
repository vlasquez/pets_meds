import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../domain/entities/schedule_time.dart';
import '../../../domain/entities/treatment.dart';
import '../../../domain/entities/vaccination.dart';

/// Wraps flutter_local_notifications: permission setup and
/// (re)scheduling of treatment and vaccination reminders.
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

  /// One notification id per (treatment, time slot).
  int _notificationId(int treatmentId, int timeIndex) =>
      treatmentId * 100 + timeIndex;

  Future<void> scheduleTreatment(Treatment treatment,
      {required String title, required String body}) async {
    await cancelTreatment(treatment);
    if (!treatment.active || treatment.id == null) return;
    if (treatment.endDate != null &&
        treatment.endDate!.isBefore(DateTime.now())) {
      return;
    }

    for (var i = 0; i < treatment.times.length; i++) {
      final time = treatment.times[i];
      final id = _notificationId(treatment.id!, i);

      if (treatment.frequencyType == FrequencyType.daily) {
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
        final next = _nextIntervalOccurrence(treatment, time);
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

  Future<void> cancelTreatment(Treatment treatment) async {
    if (treatment.id == null) return;
    // Cancel up to 100 possible time slots for this treatment.
    for (var i = 0; i < 100; i++) {
      await _plugin.cancel(_notificationId(treatment.id!, i));
    }
  }

  /// Vaccination ids live in their own range to avoid colliding with
  /// treatment reminder ids (treatmentId * 100 + timeIndex).
  int _vaccinationNotificationId(int vaccinationId) =>
      2000000000 - vaccinationId;

  /// Schedules a one-shot reminder at 09:00 on the vaccination's due date.
  Future<void> scheduleVaccination(Vaccination vaccination,
      {required String title, required String body}) async {
    await cancelVaccination(vaccination);
    final due = vaccination.nextDueDate;
    if (vaccination.id == null || due == null) return;

    final when =
        tz.TZDateTime(tz.local, due.year, due.month, due.day, 9, 0);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _vaccinationNotificationId(vaccination.id!),
      title,
      body,
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelVaccination(Vaccination vaccination) async {
    if (vaccination.id == null) return;
    await _plugin.cancel(_vaccinationNotificationId(vaccination.id!));
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

  tz.TZDateTime? _nextIntervalOccurrence(
      Treatment treatment, ScheduleTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(tz.local, treatment.startDate.year,
        treatment.startDate.month, treatment.startDate.day, time.hour,
        time.minute);
    while (!candidate.isAfter(now)) {
      candidate = candidate.add(Duration(days: treatment.intervalDays));
    }
    if (treatment.endDate != null &&
        candidate.isAfter(tz.TZDateTime(tz.local, treatment.endDate!.year,
            treatment.endDate!.month, treatment.endDate!.day, 23, 59))) {
      return null;
    }
    return candidate;
  }
}
