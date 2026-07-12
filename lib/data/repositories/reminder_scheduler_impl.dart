import '../../domain/entities/treatment.dart';
import '../../domain/repositories/reminder_scheduler.dart';
import '../datasources/local/notification_datasource.dart';

class ReminderSchedulerImpl implements ReminderScheduler {
  final NotificationDataSource _notifications;
  const ReminderSchedulerImpl(this._notifications);

  @override
  Future<void> schedule(Treatment treatment,
          {required String title, required String body}) =>
      _notifications.scheduleTreatment(treatment, title: title, body: body);

  @override
  Future<void> cancel(Treatment treatment) =>
      _notifications.cancelTreatment(treatment);
}
