part of 'treatments_bloc.dart';

enum TreatmentsStatus { initial, loading, success, failure }

/// A medication together with the pet it is assigned to.
final class Treatment extends Equatable {
  final Medication medication;
  final Pet pet;

  const Treatment({required this.medication, required this.pet});

  @override
  List<Object?> get props => [medication, pet];
}

final class TreatmentsState extends Equatable {
  final TreatmentsStatus status;
  final List<Treatment> treatments;

  /// All pets, for the "assign to pet" picker.
  final List<Pet> pets;
  final String? error;

  const TreatmentsState({
    this.status = TreatmentsStatus.initial,
    this.treatments = const [],
    this.pets = const [],
    this.error,
  });

  TreatmentsState copyWith({
    TreatmentsStatus? status,
    List<Treatment>? treatments,
    List<Pet>? pets,
    String? error,
  }) =>
      TreatmentsState(
        status: status ?? this.status,
        treatments: treatments ?? this.treatments,
        pets: pets ?? this.pets,
        error: error,
      );

  @override
  List<Object?> get props => [status, treatments, pets, error];
}
