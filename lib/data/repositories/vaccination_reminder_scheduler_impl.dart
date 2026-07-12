import '../../domain/entities/vaccination.dart';
import '../../domain/repositories/vaccination_reminder_scheduler.dart';
import '../datasources/local/notification_datasource.dart';

class VaccinationReminderSchedulerImpl implements VaccinationReminderScheduler {
  final NotificationDataSource _notifications;
  const VaccinationReminderSchedulerImpl(this._notifications);

  @override
  Future<void> schedule(Vaccination vaccination,
          {required String title, required String body}) =>
      _notifications.scheduleVaccination(vaccination,
          title: title, body: body);

  @override
  Future<void> cancel(Vaccination vaccination) =>
      _notifications.cancelVaccination(vaccination);
}
