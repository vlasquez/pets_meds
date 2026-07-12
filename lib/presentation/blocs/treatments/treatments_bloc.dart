import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/medication.dart';
import '../../../domain/entities/pet.dart';
import '../../../domain/usecases/delete_medication.dart';
import '../../../domain/usecases/get_all_medications.dart';
import '../../../domain/usecases/get_pets.dart';
import '../../../domain/usecases/save_medication.dart';

part 'treatments_event.dart';
part 'treatments_state.dart';

/// Treatments tab: the full medication list across pets, with
/// add/edit (assigning the medication to a pet) and delete.
class TreatmentsBloc extends Bloc<TreatmentsEvent, TreatmentsState> {
  final GetPets _getPets;
  final GetAllMedications _getAllMedications;
  final SaveMedication _saveMedication;
  final DeleteMedication _deleteMedication;

  TreatmentsBloc({
    required GetPets getPets,
    required GetAllMedications getAllMedications,
    required SaveMedication saveMedication,
    required DeleteMedication deleteMedication,
  })  : _getPets = getPets,
        _getAllMedications = getAllMedications,
        _saveMedication = saveMedication,
        _deleteMedication = deleteMedication,
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
    await _saveMedication(
      event.medication,
      notificationTitle: event.notificationTitle,
      notificationBody: event.notificationBody,
    );
    await _emitTreatments(emit);
  }

  Future<void> _onDeleted(
      TreatmentDeleted event, Emitter<TreatmentsState> emit) async {
    await _deleteMedication(event.medication);
    await _emitTreatments(emit);
  }

  Future<void> _emitTreatments(Emitter<TreatmentsState> emit) async {
    try {
      final pets = await _getPets();
      final meds = await _getAllMedications();
      final petsById = {for (final p in pets) p.id!: p};
      emit(state.copyWith(
        status: TreatmentsStatus.success,
        treatments: [
          for (final med in meds)
            if (petsById.containsKey(med.petId))
              Treatment(medication: med, pet: petsById[med.petId]!),
        ],
        pets: pets,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: TreatmentsStatus.failure, error: e.toString()));
    }
  }
}
