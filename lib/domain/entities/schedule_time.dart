import 'package:equatable/equatable.dart';

/// A time of day (hour/minute) as a pure value object,
/// keeping the domain layer independent of Flutter's TimeOfDay.
class ScheduleTime extends Equatable implements Comparable<ScheduleTime> {
  final int hour;
  final int minute;

  const ScheduleTime(this.hour, this.minute)
      : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60);

  int get inMinutes => hour * 60 + minute;

  /// "08:30"
  String format() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(ScheduleTime other) => inMinutes.compareTo(other.inMinutes);

  @override
  List<Object?> get props => [hour, minute];
}
