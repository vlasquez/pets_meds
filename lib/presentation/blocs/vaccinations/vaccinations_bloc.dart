import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/pet.dart';
import '../../../domain/entities/vaccination.dart';
import '../../../domain/usecases/delete_vaccination.dart';
import '../../../domain/usecases/get_vaccinations.dart';
import '../../../domain/usecases/save_vaccination.dart';

part 'vaccinations_event.dart';
part 'vaccinations_state.dart';

/// Manages the vaccinations of a single [pet].
class VaccinationsBloc extends Bloc<VaccinationsEvent, VaccinationsState> {
  final Pet pet;
  final GetVaccinations _getVaccinations;
  final SaveVaccination _saveVaccination;
  final DeleteVaccination _deleteVaccination;

  VaccinationsBloc({
    required this.pet,
    required GetVaccinations getVaccinations,
    required SaveVaccination saveVaccination,
    required DeleteVaccination deleteVaccination,
  })  : _getVaccinations = getVaccinations,
        _saveVaccination = saveVaccination,
        _deleteVaccination = deleteVaccination,
        super(const VaccinationsState()) {
    on<VaccinationsRequested>(_onRequested);
    on<VaccinationSaved>(_onSaved);
    on<VaccinationDeleted>(_onDeleted);
  }

  Future<void> _onRequested(
      VaccinationsRequested event, Emitter<VaccinationsState> emit) async {
    emit(state.copyWith(status: VaccinationsStatus.loading));
    await _emitVaccinations(emit);
  }

  Future<void> _onSaved(
      VaccinationSaved event, Emitter<VaccinationsState> emit) async {
    await _saveVaccination(
      event.vaccination,
      notificationTitle: event.notificationTitle,
      notificationBody: event.notificationBody,
    );
    await _emitVaccinations(emit);
  }

  Future<void> _onDeleted(
      VaccinationDeleted event, Emitter<VaccinationsState> emit) async {
    await _deleteVaccination(event.vaccination);
    await _emitVaccinations(emit);
  }

  Future<void> _emitVaccinations(Emitter<VaccinationsState> emit) async {
    try {
      final vaccinations = await _getVaccinations(pet.id!);
      emit(state.copyWith(
          status: VaccinationsStatus.success, vaccinations: vaccinations));
    } catch (e) {
      emit(state.copyWith(
          status: VaccinationsStatus.failure, error: e.toString()));
    }
  }
}
