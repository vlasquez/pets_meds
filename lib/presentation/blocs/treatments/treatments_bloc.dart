import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/pet.dart';
import '../../../domain/entities/treatment.dart';
import '../../../domain/usecases/delete_treatment.dart';
import '../../../domain/usecases/get_all_treatments.dart';
import '../../../domain/usecases/get_pets.dart';
import '../../../domain/usecases/save_treatment.dart';

part 'treatments_event.dart';
part 'treatments_state.dart';

/// Treatments tab: the full treatment list across pets, with
/// add/edit (assigning a catalog medication to a pet) and delete.
class TreatmentsBloc extends Bloc<TreatmentsEvent, TreatmentsState> {
  final GetPets _getPets;
  final GetAllTreatments _getAllTreatments;
  final SaveTreatment _saveTreatment;
  final DeleteTreatment _deleteTreatment;

  TreatmentsBloc({
    required GetPets getPets,
    required GetAllTreatments getAllTreatments,
    required SaveTreatment saveTreatment,
    required DeleteTreatment deleteTreatment,
  })  : _getPets = getPets,
        _getAllTreatments = getAllTreatments,
        _saveTreatment = saveTreatment,
        _deleteTreatment = deleteTreatment,
        super(const TreatmentsState()) {
    on<TreatmentsRequested>(_onRequested);
    on<TreatmentSaved>(_onSaved);
    on<TreatmentDeleted>(_onDeleted);
  }

  Future<void> _onRequested(
      TreatmentsRequested event, Emitter<TreatmentsState> emit) async {
    emit(state.copyWith(status: TreatmentsStatus.loading));
    await _emitTreatments(emit);
  }

  Future<void> _onSaved(
      TreatmentSaved event, Emitter<TreatmentsState> emit) async {
    await _saveTreatment(
      event.treatment,
      notificationTitle: event.notificationTitle,
      notificationBody: event.notificationBody,
    );
    await _emitTreatments(emit);
  }

  Future<void> _onDeleted(
      TreatmentDeleted event, Emitter<TreatmentsState> emit) async {
    await _deleteTreatment(event.treatment);
    await _emitTreatments(emit);
  }

  Future<void> _emitTreatments(Emitter<TreatmentsState> emit) async {
    try {
      final pets = await _getPets();
      final treatments = await _getAllTreatments();
      final petsById = {for (final p in pets) p.id!: p};
      emit(state.copyWith(
        status: TreatmentsStatus.success,
        entries: [
          for (final t in treatments)
            if (petsById.containsKey(t.petId))
              TreatmentEntry(treatment: t, pet: petsById[t.petId]!),
        ],
        pets: pets,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: TreatmentsStatus.failure, error: e.toString()));
    }
  }
}
