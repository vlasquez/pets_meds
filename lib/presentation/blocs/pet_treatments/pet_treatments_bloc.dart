import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/pet.dart';
import '../../../domain/entities/treatment.dart';
import '../../../domain/usecases/delete_treatment.dart';
import '../../../domain/usecases/get_treatments.dart';
import '../../../domain/usecases/log_dose.dart';
import '../../../domain/usecases/save_treatment.dart';

part 'pet_treatments_event.dart';
part 'pet_treatments_state.dart';

/// Manages the treatments of a single [pet].
class PetTreatmentsBloc extends Bloc<PetTreatmentsEvent, PetTreatmentsState> {
  final Pet pet;
  final GetTreatments _getTreatments;
  final SaveTreatment _saveTreatment;
  final DeleteTreatment _deleteTreatment;
  final LogDose _logDose;

  PetTreatmentsBloc({
    required this.pet,
    required GetTreatments getTreatments,
    required SaveTreatment saveTreatment,
    required DeleteTreatment deleteTreatment,
    required LogDose logDose,
  })  : _getTreatments = getTreatments,
        _saveTreatment = saveTreatment,
        _deleteTreatment = deleteTreatment,
        _logDose = logDose,
        super(const PetTreatmentsState()) {
    on<PetTreatmentsRequested>(_onRequested);
    on<PetTreatmentSaved>(_onSaved);
    on<PetTreatmentDeleted>(_onDeleted);
    on<DoseMarkedGiven>(_onDoseMarkedGiven);
  }

  Future<void> _onRequested(
      PetTreatmentsRequested event, Emitter<PetTreatmentsState> emit) async {
    emit(state.copyWith(status: PetTreatmentsStatus.loading));
    await _emitTreatments(emit);
  }

  Future<void> _onSaved(
      PetTreatmentSaved event, Emitter<PetTreatmentsState> emit) async {
    await _saveTreatment(
      event.treatment,
      notificationTitle: event.notificationTitle,
      notificationBody: event.notificationBody,
    );
    await _emitTreatments(emit);
  }

  Future<void> _onDeleted(
      PetTreatmentDeleted event, Emitter<PetTreatmentsState> emit) async {
    await _deleteTreatment(event.treatment);
    await _emitTreatments(emit);
  }

  Future<void> _onDoseMarkedGiven(
      DoseMarkedGiven event, Emitter<PetTreatmentsState> emit) async {
    await _logDose(
      event.treatment,
      notificationTitle: event.notificationTitle,
      notificationBody: event.notificationBody,
    );
    emit(state.copyWith(
      doseLogCount: state.doseLogCount + 1,
      lastDosedName: event.treatment.medicationName,
    ));
  }

  Future<void> _emitTreatments(Emitter<PetTreatmentsState> emit) async {
    try {
      final treatments = await _getTreatments(pet.id!);
      emit(state.copyWith(
          status: PetTreatmentsStatus.success, treatments: treatments));
    } catch (e) {
      emit(state.copyWith(
          status: PetTreatmentsStatus.failure, error: e.toString()));
    }
  }
}
