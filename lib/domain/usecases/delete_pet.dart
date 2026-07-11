import '../entities/pet.dart';
import '../repositories/medication_repository.dart';
import '../repositories/pet_repository.dart';
import '../repositories/reminder_scheduler.dart';

/// Deletes a pet, cancelling the reminders of all its medications first.
/// (Medications and dose logs are removed by cascade in the data layer.)
class DeletePet {
  final PetRepository _pets;
  final MedicationRepository _medications;
  final ReminderScheduler _scheduler;

  const DeletePet(this._pets, this._medications, this._scheduler);

  Future<void> call(Pet pet) async {
    final meds = await _medications.getMedicationsForPet(pet.id!);
    for (final med in meds) {
      await _scheduler.cancel(med);
    }
    await _pets.deletePet(pet.id!);
  }
}
