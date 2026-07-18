part of 'progress_bloc.dart';

sealed class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object?> get props => [];
}

final class ProgressRequested extends ProgressEvent {
  const ProgressRequested();
}

/// Checks one intake on a specific day (possibly in the past).
final class ProgressDoseChecked extends ProgressEvent {
  final DayProgress day;
  final String notificationTitle;
  final String notificationBody;

  const ProgressDoseChecked({
    required this.day,
    required this.notificationTitle,
    required this.notificationBody,
  });

  @override
  List<Object?> get props => [day, notificationTitle, notificationBody];
}

/// Unchecks one intake (removes that day's latest dose log).
final class ProgressDoseUnchecked extends ProgressEvent {
  final int logId;
  const ProgressDoseUnchecked(this.logId);

  @override
  List<Object?> get props => [logId];
}
