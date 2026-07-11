part of 'weight_bloc.dart';

enum WeightStatus { initial, loading, success, failure }

final class WeightState extends Equatable {
  final WeightStatus status;

  /// Most recent first.
  final List<WeightEntry> entries;
  final String? error;

  const WeightState({
    this.status = WeightStatus.initial,
    this.entries = const [],
    this.error,
  });

  WeightEntry? get latest => entries.isEmpty ? null : entries.first;

  WeightState copyWith({
    WeightStatus? status,
    List<WeightEntry>? entries,
    String? error,
  }) =>
      WeightState(
        status: status ?? this.status,
        entries: entries ?? this.entries,
        error: error,
      );

  @override
  List<Object?> get props => [status, entries, error];
}
