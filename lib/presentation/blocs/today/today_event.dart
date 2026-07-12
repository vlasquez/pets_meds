part of 'today_bloc.dart';

sealed class TodayEvent extends Equatable {
  const TodayEvent();

  @override
  List<Object?> get props => [];
}

final class TodayRequested extends TodayEvent {
  const TodayRequested();
}

/// Marks a dose as given from the Home tab.
final class TodayDoseGiven extends TodayEvent {
  final Treatment treatment;
  final String notificationTitle;
  final String notificationBody;

  const TodayDoseGiven({
    required this.treatment,
    required this.notificationTitle,
    required this.notificationBody,
  });

  @override
  List<Object?> get props => [treatment, notificationTitle, notificationBody];
}

/// Unchecks a treatment on the Home tab: removes today's dose log.
final class TodayDoseUnmarked extends TodayEvent {
  final int logId;
  const TodayDoseUnmarked(this.logId);

  @override
  List<Object?> get props => [logId];
}
