import '../entities/pet.dart';
import '../repositories/pet_repository.dart';
import '../repositories/reminder_scheduler.dart';
import '../repositories/treatment_repository.dart';

/// Deletes a pet, cancelling the reminders of all its treatments first.
/// (Treatments and dose logs are removed by cascade in the data layer.)
class DeletePet {
  final PetRepository _pets;
  final TreatmentRepository _treatments;
  final ReminderScheduler _scheduler;

  const DeletePet(this._pets, this._treatments, this._scheduler);

  Future<void> call(Pet pet) async {
    final treatments = await _treatments.getTreatmentsForPet(pet.id!);
    for (final treatment in treatments) {
      await _scheduler.cancel(treatment);
    }
    await _pets.deletePet(pet.id!);
  }
}
