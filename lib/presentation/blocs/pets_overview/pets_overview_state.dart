part of 'pets_overview_bloc.dart';

enum PetsOverviewStatus { initial, loading, success, failure }

/// A pet plus its at-a-glance summary values.
final class PetOverview extends Equatable {
  final Pet pet;
  final double? lastWeightKg;
  final DateTime? lastVaccinationDate;
  final int activeTreatments;
  final int inactiveTreatments;
  final int completedTreatments;

  const PetOverview({
    required this.pet,
    required this.lastWeightKg,
    required this.lastVaccinationDate,
    required this.activeTreatments,
    required this.inactiveTreatments,
    required this.completedTreatments,
  });

  int get totalTreatments =>
      activeTreatments + inactiveTreatments + completedTreatments;

  @override
  List<Object?> get props => [
        pet,
        lastWeightKg,
        lastVaccinationDate,
        activeTreatments,
        inactiveTreatments,
        completedTreatments,
      ];
}

final class PetsOverviewState extends Equatable {
  final PetsOverviewStatus status;
  final List<PetOverview> items;
  final String? error;

  const PetsOverviewState({
    this.status = PetsOverviewStatus.initial,
    this.items = const [],
    this.error,
  });

  PetsOverviewState copyWith({
    PetsOverviewStatus? status,
    List<PetOverview>? items,
    String? error,
  }) =>
      PetsOverviewState(
        status: status ?? this.status,
        items: items ?? this.items,
        error: error,
      );

  @override
  List<Object?> get props => [status, items, error];
}
