import 'package:reminder_scheduler/reminder_scheduler.dart' as rs;

import '../../domain/entities/treatment.dart';
import '../../domain/repositories/reminder_scheduler.dart';
import '../notifications/treatment_reminder_mapper.dart';

/// Bridges the app's treatment reminder port to the reusable
/// [rs.ReminderScheduler], mapping [Treatment] into the generic model.
class ReminderSchedulerImpl implements ReminderScheduler {
  final rs.ReminderScheduler _scheduler;
  const ReminderSchedulerImpl(this._scheduler);

  @override
  Future<void> schedule(Treatment treatment,
      {required String title, required String body}) async {
    if (treatment.id == null) return;
    final triggers = ReminderMapper.triggersForTreatment(treatment);
    final groupId = ReminderMapper.treatmentGroupId(treatment.id!);
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
  Future<void> cancel(Treatment treatment) async {
    if (treatment.id == null) return;
    await _scheduler
        .cancelGroup(ReminderMapper.treatmentGroupId(treatment.id!));
  }
}
