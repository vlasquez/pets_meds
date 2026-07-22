import 'package:reminder_scheduler/reminder_scheduler.dart' as rs;

import '../../domain/entities/vaccination.dart';
import '../../domain/repositories/vaccination_reminder_scheduler.dart';
import '../notifications/treatment_reminder_mapper.dart';

/// Bridges the app's vaccination reminder port to the reusable
/// [rs.ReminderScheduler], mapping [Vaccination] into the generic model.
class VaccinationReminderSchedulerImpl
    implements VaccinationReminderScheduler {
  final rs.ReminderScheduler _scheduler;
  const VaccinationReminderSchedulerImpl(this._scheduler);

  @override
  Future<void> schedule(Vaccination vaccination,
      {required String title, required String body}) async {
    if (vaccination.id == null) return;
    final triggers = ReminderMapper.triggersForVaccination(vaccination);
    final groupId = ReminderMapper.vaccinationGroupId(vaccination.id!);
    if (triggers.isEmpty) {
      await _scheduler.cancelGroup(groupId);
      return;
    }
    await _scheduler.schedule(rs.ReminderRequest(
      groupId: groupId,
      title: title,
      body: body,
      triggers: triggers,
    ));
  }

  @override
  Future<void> cancel(Vaccination vaccination) async {
    if (vaccination.id == null) return;
    await _scheduler
        .cancelGroup(ReminderMapper.vaccinationGroupId(vaccination.id!));
  }
}
