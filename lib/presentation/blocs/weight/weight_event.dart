part of 'weight_bloc.dart';

sealed class WeightEvent extends Equatable {
  const WeightEvent();

  @override
  List<Object?> get props => [];
}

final class WeightHistoryRequested extends WeightEvent {
  const WeightHistoryRequested();
}

final class WeightLogged extends WeightEvent {
  final double weightKg;
  final DateTime measuredAt;
  final String? note;

  const WeightLogged({
    required this.weightKg,
    required this.measuredAt,
    this.note,
  });

  @override
  List<Object?> get props => [weightKg, measuredAt, note];
}

final class WeightEntryDeleted extends WeightEvent {
  final WeightEntry entry;
  const WeightEntryDeleted(this.entry);

  @override
  List<Object?> get props => [entry];
}
