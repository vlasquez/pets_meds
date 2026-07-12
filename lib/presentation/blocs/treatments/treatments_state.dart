part of 'treatments_bloc.dart';

enum TreatmentsStatus { initial, loading, success, failure }

/// A treatment together with the pet it is assigned to.
final class TreatmentEntry extends Equatable {
  final Treatment treatment;
  final Pet pet;

  const TreatmentEntry({required this.treatment, required this.pet});

  @override
  List<Object?> get props => [treatment, pet];
}

final class TreatmentsState extends Equatable {
  final TreatmentsStatus status;
  final List<TreatmentEntry> entries;

  /// All pets, for the "assign to pet" selector.
  final List<Pet> pets;
  final String? error;

  const TreatmentsState({
    this.status = TreatmentsStatus.initial,
    this.entries = const [],
    this.pets = const [],
    this.error,
  });

  TreatmentsState copyWith({
    TreatmentsStatus? status,
    List<TreatmentEntry>? entries,
    List<Pet>? pets,
    String? error,
  }) =>
      TreatmentsState(
        status: status ?? this.status,
        entries: entries ?? this.entries,
        pets: pets ?? this.pets,
        error: error,
      );

  @override
  List<Object?> get props => [status, entries, pets, error];
}
