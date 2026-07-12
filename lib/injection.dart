import 'package:get_it/get_it.dart';

import 'data/datasources/local/database_provider.dart';
import 'data/datasources/local/dose_log_local_datasource.dart';
import 'data/datasources/local/medication_local_datasource.dart';
import 'data/datasources/local/notification_datasource.dart';
import 'data/datasources/local/pet_local_datasource.dart';
import 'data/datasources/local/photo_storage.dart';
import 'data/datasources/local/treatment_local_datasource.dart';
import 'data/datasources/local/vaccination_local_datasource.dart';
import 'data/datasources/local/weight_local_datasource.dart';
import 'data/repositories/dose_log_repository_impl.dart';
import 'data/repositories/medication_repository_impl.dart';
import 'data/repositories/pet_repository_impl.dart';
import 'data/repositories/reminder_scheduler_impl.dart';
import 'data/repositories/treatment_repository_impl.dart';
import 'data/repositories/vaccination_reminder_scheduler_impl.dart';
import 'data/repositories/vaccination_repository_impl.dart';
import 'data/repositories/weight_repository_impl.dart';
import 'domain/repositories/dose_log_repository.dart';
import 'domain/repositories/medication_repository.dart';
import 'domain/repositories/pet_repository.dart';
import 'domain/repositories/reminder_scheduler.dart';
import 'domain/repositories/treatment_repository.dart';
import 'domain/repositories/vaccination_reminder_scheduler.dart';
import 'domain/repositories/vaccination_repository.dart';
import 'domain/repositories/weight_repository.dart';
import 'domain/usecases/delete_pet.dart';
import 'domain/usecases/delete_treatment.dart';
import 'domain/usecases/delete_vaccination.dart';
import 'domain/usecases/delete_weight_entry.dart';
import 'domain/usecases/get_all_treatments.dart';
import 'domain/usecases/get_dose_history.dart';
import 'domain/usecases/get_medications.dart';
import 'domain/usecases/get_pets.dart';
import 'domain/usecases/get_treatments.dart';
import 'domain/usecases/get_vaccinations.dart';
import 'domain/usecases/get_weight_history.dart';
import 'domain/usecases/log_dose.dart';
import 'domain/usecases/log_weight.dart';
import 'domain/usecases/save_medication.dart';
import 'domain/usecases/save_pet.dart';
import 'domain/usecases/save_treatment.dart';
import 'domain/usecases/save_vaccination.dart';

final sl = GetIt.instance;

/// Wires data sources → repositories → use cases.
Future<void> initDependencies() async {
  // Data sources
  sl.registerLazySingleton(() => DatabaseProvider());
  sl.registerLazySingleton(() => PetLocalDataSource(sl()));
  sl.registerLazySingleton(() => MedicationLocalDataSource(sl()));
  sl.registerLazySingleton(() => TreatmentLocalDataSource(sl()));
  sl.registerLazySingleton(() => DoseLogLocalDataSource(sl()));
  sl.registerLazySingleton(() => WeightLocalDataSource(sl()));
  sl.registerLazySingleton(() => VaccinationLocalDataSource(sl()));
  sl.registerLazySingleton(() => NotificationDataSource());
  sl.registerLazySingleton(() => PhotoStorage());

  // Repositories (domain contracts → data implementations)
  sl.registerLazySingleton<PetRepository>(() => PetRepositoryImpl(sl()));
  sl.registerLazySingleton<MedicationRepository>(
      () => MedicationRepositoryImpl(sl()));
  sl.registerLazySingleton<TreatmentRepository>(
      () => TreatmentRepositoryImpl(sl()));
  sl.registerLazySingleton<DoseLogRepository>(
      () => DoseLogRepositoryImpl(sl()));
  sl.registerLazySingleton<ReminderScheduler>(
      () => ReminderSchedulerImpl(sl()));
  sl.registerLazySingleton<WeightRepository>(
      () => WeightRepositoryImpl(sl()));
  sl.registerLazySingleton<VaccinationRepository>(
      () => VaccinationRepositoryImpl(sl()));
  sl.registerLazySingleton<VaccinationReminderScheduler>(
      () => VaccinationReminderSchedulerImpl(sl()));

  // Use cases
  sl.registerLazySingleton(() => GetPets(sl()));
  sl.registerLazySingleton(() => SavePet(sl()));
  sl.registerLazySingleton(() => DeletePet(sl(), sl(), sl()));
  sl.registerLazySingleton(() => GetMedications(sl()));
  sl.registerLazySingleton(() => SaveMedication(sl()));
  sl.registerLazySingleton(() => GetTreatments(sl()));
  sl.registerLazySingleton(() => GetAllTreatments(sl()));
  sl.registerLazySingleton(() => SaveTreatment(sl(), sl()));
  sl.registerLazySingleton(() => DeleteTreatment(sl(), sl()));
  sl.registerLazySingleton(() => LogDose(sl(), sl()));
  sl.registerLazySingleton(() => GetDoseHistory(sl(), sl()));
  sl.registerLazySingleton(() => GetWeightHistory(sl()));
  sl.registerLazySingleton(() => LogWeight(sl()));
  sl.registerLazySingleton(() => DeleteWeightEntry(sl()));
  sl.registerLazySingleton(() => GetVaccinations(sl()));
  sl.registerLazySingleton(() => SaveVaccination(sl(), sl()));
  sl.registerLazySingleton(() => DeleteVaccination(sl(), sl()));

  await sl<NotificationDataSource>().init();
}
