import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/pet.dart';
import '../../../domain/entities/treatment.dart';
import '../../../domain/usecases/get_pets.dart';
import '../../../domain/usecases/get_treatments.dart';
import '../../../domain/usecases/get_vaccinations.dart';
import '../../../domain/usecases/get_weight_history.dart';

part 'pets_overview_event.dart';
part 'pets_overview_state.dart';

/// Pets tab: every pet with a quick summary — last weight, last
/// vaccination date and number of active treatments.
class PetsOverviewBloc extends Bloc<PetsOverviewEvent, PetsOverviewState> {
  final GetPets _getPets;
  final GetWeightHistory _getWeightHistory;
  final GetVaccinations _getVaccinations;
  final GetTreatments _getTreatments;

  PetsOverviewBloc({
    required GetPets getPets,
    required GetWeightHistory getWeightHistory,
    required GetVaccinations getVaccinations,
    required GetTreatments getTreatments,
  })  : _getPets = getPets,
        _getWeightHistory = getWeightHistory,
        _getVaccinations = getVaccinations,
        _getTreatments = getTreatments,
        super(const PetsOverviewState()) {
    on<PetsOverviewRequested>(_onRequested);
  }

  Future<void> _onRequested(
      PetsOverviewRequested event, Emitter<PetsOverviewState> emit) async {
    emit(state.copyWith(status: PetsOverviewStatus.loading));
    try {
      final pets = await _getPets();
      final items = <PetOverview>[];
      for (final pet in pets) {
        final weights = await _getWeightHistory(pet.id!);
        final vaccinations = await _getVaccinations(pet.id!);
        final treatments = await _getTreatments(pet.id!);
        final now = DateTime.now();
        var active = 0, inactive = 0, completed = 0;
        for (final t in treatments) {
          switch (t.statusOn(now)) {
            case TreatmentStatus.active:
              active++;
            case TreatmentStatus.inactive:
              inactive++;
            case TreatmentStatus.completed:
              completed++;
          }
        }
        items.add(PetOverview(
          pet: pet,
          lastWeightKg: weights.isEmpty ? null : weights.first.weightKg,
          lastVaccinationDate:
              vaccinations.isEmpty ? null : vaccinations.first.appliedAt,
          activeTreatments: active,
          inactiveTreatments: inactive,
          completedTreatments: completed,
        ));
      }
      emit(state.copyWith(status: PetsOverviewStatus.success, items: items));
    } catch (e) {
      emit(state.copyWith(
          status: PetsOverviewStatus.failure, error: e.toString()));
    }
  }
}
