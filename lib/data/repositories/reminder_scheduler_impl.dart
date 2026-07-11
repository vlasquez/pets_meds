import '../../domain/entities/medication.dart';
import '../../domain/repositories/reminder_scheduler.dart';
import '../datasources/local/notification_datasource.dart';

class ReminderSchedulerImpl implements ReminderScheduler {
  final NotificationDataSource _notifications;
  const ReminderSchedulerImpl(this._notifications);

  @override
  Future<void> schedule(Medication medication,
          {required String title, required String body}) =>
      _notifications.scheduleMedication(medication, title: title, body: body);

  @override
  Future<void> cancel(Medication medication) =>
      _notifications.cancelMedication(medication);
}
