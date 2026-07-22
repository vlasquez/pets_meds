import 'package:flutter/material.dart';

import '../domain/entities/schedule_time.dart';

/// Formats a [ScheduleTime] respecting the app's hour-format setting.
///
/// Uses [TimeOfDay.format], which reads MediaQuery.alwaysUse24HourFormat
/// — set app-wide in main.dart from the user's preference. So this
/// renders "08:30" or "8:30 AM" automatically.
String formatScheduleTime(BuildContext context, ScheduleTime t) =>
    TimeOfDay(hour: t.hour, minute: t.minute).format(context);
