part of 'today_bloc.dart';

enum TodayStatus { initial, loading, success, failure }

/// A treatment scheduled today plus today's dose log (if already given).
final class TodayItem extends Equatable {
  final Treatment treatment;

  /// Id of today's latest dose log for this treatment, or null when
  /// no dose was logged today. Used to uncheck (delete the log).
  final int? todayLogId;

  const TodayItem({required this.treatment, this.todayLogId});

  bool get givenToday => todayLogId != null;

  @override
  List<Object?> get props => [treatment, todayLogId];
}

/// A pet with its treatments scheduled for today.
final class TodayEntry extends Equatable {
  final Pet pet;
  final List<TodayItem> items;

  const TodayEntry({required this.pet, required this.items});

  @override
  List<Object?> get props => [pet, items];
}

final class TodayState extends Equatable {
  final TodayStatus status;
  final List<TodayEntry> entries;

  /// Incremented on each dose logged from Home (for a snackbar via listener).
  final int doseLogCount;
  final String? lastDosedName;

  final String? error;

  const TodayState({
    this.status = TodayStatus.initial,
    this.entries = const [],
    this.doseLogCount = 0,
    this.lastDosedName,
    this.error,
  });

  TodayState copyWith({
    TodayStatus? status,
    List<TodayEntry>? entries,
    int? doseLogCount,
    String? lastDosedName,
    String? error,
  }) =>
      TodayState(
        status: status ?? this.status,
        entries: entries ?? this.entries,
        doseLogCount: doseLogCount ?? this.doseLogCount,
        lastDosedName: lastDosedName ?? this.lastDosedName,
        error: error,
      );

  @override
  List<Object?> get props =>
      [status, entries, doseLogCount, lastDosedName, error];
}
