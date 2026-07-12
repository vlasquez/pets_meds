part of 'vaccinations_bloc.dart';

enum VaccinationsStatus { initial, loading, success, failure }

final class VaccinationsState extends Equatable {
  final VaccinationsStatus status;

  /// Most recent first.
  final List<Vaccination> vaccinations;
  final String? error;

  const VaccinationsState({
    this.status = VaccinationsStatus.initial,
    this.vaccinations = const [],
    this.error,
  });

  VaccinationsState copyWith({
    VaccinationsStatus? status,
    List<Vaccination>? vaccinations,
    String? error,
  }) =>
      VaccinationsState(
        status: status ?? this.status,
        vaccinations: vaccinations ?? this.vaccinations,
        error: error,
      );

  @override
  List<Object?> get props => [status, vaccinations, error];
}
