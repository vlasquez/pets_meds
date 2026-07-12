import 'package:flutter/widgets.dart';

import '../domain/entities/dose_unit.dart';
import '../domain/entities/vaccination.dart';

/// Lightweight ES/EN localization without codegen.
class S {
  final Locale locale;
  const S(this.locale);

  static S of(BuildContext context) =>
      Localizations.of<S>(context, S) ?? const S(Locale('en'));

  static const delegate = _SDelegate();

  bool get _es => locale.languageCode == 'es';

  String get appTitle => _es ? 'Medicinas de Mascotas' : 'Pet Meds';
  String get myPets => _es ? 'Mis mascotas' : 'My pets';
  String get noPets => _es
      ? 'Aún no hay mascotas. Toca + para agregar una.'
      : 'No pets yet. Tap + to add one.';
  String get addPet => _es ? 'Agregar mascota' : 'Add pet';
  String get editPet => _es ? 'Editar mascota' : 'Edit pet';
  String get deletePet => _es ? 'Eliminar mascota' : 'Delete pet';
  String get deletePetConfirm => _es
      ? '¿Eliminar esta mascota y todos sus medicamentos?'
      : 'Delete this pet and all its medications?';
  String get name => _es ? 'Nombre' : 'Name';
  String get species => _es ? 'Especie' : 'Species';
  String get dog => _es ? 'Perro' : 'Dog';
  String get cat => _es ? 'Gato' : 'Cat';
  String get other => _es ? 'Otro' : 'Other';
  String get notes => _es ? 'Notas' : 'Notes';
  String get save => _es ? 'Guardar' : 'Save';
  String get cancel => _es ? 'Cancelar' : 'Cancel';
  String get delete => _es ? 'Eliminar' : 'Delete';
  String get requiredField => _es ? 'Campo obligatorio' : 'Required field';

  String get medications => _es ? 'Medicamentos' : 'Medications';
  String get noMedications => _es
      ? 'Sin medicamentos. Toca + para agregar uno.'
      : 'No medications. Tap + to add one.';
  String get addMedication => _es ? 'Agregar medicamento' : 'Add medication';
  String get editMedication => _es ? 'Editar medicamento' : 'Edit medication';
  String get deleteMedication =>
      _es ? 'Eliminar medicamento' : 'Delete medication';
  String get deleteMedicationConfirm => _es
      ? '¿Eliminar este medicamento y sus recordatorios?'
      : 'Delete this medication and its reminders?';
  String get medicationName =>
      _es ? 'Nombre del medicamento' : 'Medication name';
  String get doseAmountLabel => _es ? 'Cantidad' : 'Amount';
  String get doseUnitLabel => _es ? 'Unidad' : 'Unit';

  /// Localized name of a unit, pluralized by [amount].
  String doseUnitName(DoseUnit unit, double amount) {
    final plural = amount != 1;
    if (_es) {
      switch (unit) {
        case DoseUnit.ampoule:
          return plural ? 'ampollas' : 'ampolla';
        case DoseUnit.application:
          return plural ? 'aplicaciones' : 'aplicación';
        case DoseUnit.capsule:
          return plural ? 'cápsulas' : 'cápsula';
        case DoseUnit.drop:
          return plural ? 'gotas' : 'gota';
        case DoseUnit.gram:
          return 'g';
        case DoseUnit.injection:
          return plural ? 'inyecciones' : 'inyección';
        case DoseUnit.milligram:
          return 'mg';
        case DoseUnit.milliliter:
          return 'ml';
        case DoseUnit.packet:
          return plural ? 'sobres' : 'sobre';
        case DoseUnit.pill:
          return plural ? 'pastillas' : 'pastilla';
        case DoseUnit.spray:
          return plural ? 'sprays' : 'spray';
        case DoseUnit.tablet:
          return plural ? 'tabletas' : 'tableta';
        case DoseUnit.unit:
          return plural ? 'unidades' : 'unidad';
      }
    }
    switch (unit) {
      case DoseUnit.ampoule:
        return plural ? 'ampoules' : 'ampoule';
      case DoseUnit.application:
        return plural ? 'applications' : 'application';
      case DoseUnit.capsule:
        return plural ? 'capsules' : 'capsule';
      case DoseUnit.drop:
        return plural ? 'drops' : 'drop';
      case DoseUnit.gram:
        return 'g';
      case DoseUnit.injection:
        return plural ? 'injections' : 'injection';
      case DoseUnit.milligram:
        return 'mg';
      case DoseUnit.milliliter:
        return 'ml';
      case DoseUnit.packet:
        return plural ? 'packets' : 'packet';
      case DoseUnit.pill:
        return plural ? 'pills' : 'pill';
      case DoseUnit.spray:
        return plural ? 'sprays' : 'spray';
      case DoseUnit.tablet:
        return plural ? 'tablets' : 'tablet';
      case DoseUnit.unit:
        return plural ? 'units' : 'unit';
    }
  }

  /// "2 pastillas", "5 mg", "1 drop"
  String formatDose(double amount, DoseUnit unit) {
    final amountText = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toString();
    return '$amountText ${doseUnitName(unit, amount)}';
  }

  String get frequency => _es ? 'Frecuencia' : 'Frequency';
  String get everyDay => _es ? 'Todos los días' : 'Every day';
  String everyXDays(int n) =>
      _es ? 'Cada $n día${n == 1 ? '' : 's'}' : 'Every $n day${n == 1 ? '' : 's'}';
  String get intervalDaysLabel =>
      _es ? 'Intervalo (días)' : 'Interval (days)';
  String get timesOfDay => _es ? 'Horarios' : 'Times';
  String get addTime => _es ? 'Agregar horario' : 'Add time';
  String get atLeastOneTime => _es
      ? 'Agrega al menos un horario'
      : 'Add at least one time';
  String get startDate => _es ? 'Fecha de inicio' : 'Start date';
  String get endDate => _es ? 'Fecha de fin (opcional)' : 'End date (optional)';
  String get noEndDate => _es ? 'Sin fecha de fin' : 'No end date';
  String get active => _es ? 'Activo' : 'Active';

  String get markGiven => _es ? 'Dosis aplicada' : 'Dose given';
  String doseGivenSnack(String med) =>
      _es ? 'Dosis de $med registrada' : 'Dose of $med logged';
  String get history => _es ? 'Historial' : 'History';
  String get noHistory =>
      _es ? 'Aún no hay dosis registradas.' : 'No doses logged yet.';

  String get photo => _es ? 'Foto' : 'Photo';
  String get fromGallery => _es ? 'Galería' : 'Gallery';
  String get fromCamera => _es ? 'Cámara' : 'Camera';
  String get removePhoto => _es ? 'Quitar foto' : 'Remove photo';
  String get birthDate => _es ? 'Fecha de nacimiento' : 'Birth date';
  String get notSet => _es ? 'Sin definir' : 'Not set';

  String age(int years, int months) {
    if (_es) {
      if (years == 0) return '$months mes${months == 1 ? '' : 'es'}';
      return '$years año${years == 1 ? '' : 's'}, $months mes${months == 1 ? '' : 'es'}';
    }
    if (years == 0) return '$months month${months == 1 ? '' : 's'}';
    return '$years year${years == 1 ? '' : 's'}, $months month${months == 1 ? '' : 's'}';
  }

  String get weight => _es ? 'Peso' : 'Weight';
  String get weightKgLabel => _es ? 'Peso (kg)' : 'Weight (kg)';
  String get logWeight => _es ? 'Registrar peso' : 'Log weight';
  String get weightHistory => _es ? 'Historial de peso' : 'Weight history';
  String get noWeightEntries =>
      _es ? 'Aún no hay registros de peso.' : 'No weight entries yet.';
  String get deleteWeightEntry =>
      _es ? 'Eliminar registro' : 'Delete entry';
  String get deleteWeightEntryConfirm =>
      _es ? '¿Eliminar este registro de peso?' : 'Delete this weight entry?';
  String get invalidNumber => _es ? 'Número inválido' : 'Invalid number';
  String get date => _es ? 'Fecha' : 'Date';
  String weightLoggedSnack(String kg) =>
      _es ? 'Peso registrado: $kg kg' : 'Weight logged: $kg kg';

  // Bottom navigation.
  String get homeTab => _es ? 'Inicio' : 'Home';
  String get petsTab => _es ? 'Mascotas' : 'Pets';
  String get treatmentsTab => _es ? 'Tratamientos' : 'Treatments';
  String get today => _es ? 'Hoy' : 'Today';
  String get noTreatmentsToday => _es
      ? 'No hay tratamientos programados para hoy.'
      : 'No treatments scheduled for today.';
  String get noTreatments => _es
      ? 'Aún no hay medicamentos. Toca + para agregar uno.'
      : 'No medications yet. Tap + to add one.';
  String get selectPet => _es ? 'Selecciona una mascota' : 'Select a pet';
  String get addPetFirst => _es
      ? 'Primero agrega una mascota en la pestaña Mascotas.'
      : 'First add a pet in the Pets tab.';

  // Vaccinations.
  String get vaccinations => _es ? 'Vacunas' : 'Vaccinations';
  String get addVaccination => _es ? 'Agregar vacuna' : 'Add vaccination';
  String get vaccineType => _es ? 'Tipo de vacuna' : 'Vaccine type';
  String get vaccinationDate =>
      _es ? 'Fecha de aplicación' : 'Application date';
  String get reminderLabel => _es ? 'Recordatorio' : 'Reminder';
  String get noReminder => _es ? 'Sin recordatorio' : 'No reminder';
  String get noVaccinations => _es
      ? 'Aún no hay vacunas registradas.'
      : 'No vaccinations recorded yet.';
  String get deleteVaccination =>
      _es ? 'Eliminar vacuna' : 'Delete vaccination';
  String get deleteVaccinationConfirm => _es
      ? '¿Eliminar esta vacuna y su recordatorio?'
      : 'Delete this vaccination and its reminder?';

  /// "mes(es)", "año(s)", "semana(s)" — localized unit name.
  String reminderUnitName(ReminderUnit unit, int value) {
    final plural = value != 1;
    if (_es) {
      switch (unit) {
        case ReminderUnit.weeks:
          return plural ? 'semanas' : 'semana';
        case ReminderUnit.months:
          return plural ? 'meses' : 'mes';
        case ReminderUnit.years:
          return plural ? 'años' : 'año';
      }
    }
    switch (unit) {
      case ReminderUnit.weeks:
        return plural ? 'weeks' : 'week';
      case ReminderUnit.months:
        return plural ? 'months' : 'month';
      case ReminderUnit.years:
        return plural ? 'years' : 'year';
    }
  }

  /// "Cada 6 meses" / "Every 6 months"
  String reminderEvery(int value, ReminderUnit unit) => _es
      ? 'Cada $value ${reminderUnitName(unit, value)}'
      : 'Every $value ${reminderUnitName(unit, value)}';

  /// "Próxima dosis: 2027-01-11"
  String nextDose(String date) =>
      _es ? 'Próxima dosis: $date' : 'Next dose: $date';

  String vaccineReminderTitle(String petName) => _es
      ? 'Vacuna para $petName'
      : 'Vaccination for $petName';
  String vaccineReminderBody(String vaccineType) => _es
      ? 'Es hora de renovar la vacuna: $vaccineType'
      : 'Time to renew the vaccine: $vaccineType';

  String reminderTitle(String petName) => _es
      ? 'Medicamento para $petName'
      : 'Medication for $petName';
  String reminderBody(String medName, String dosage) =>
      _es ? 'Es hora de: $medName ($dosage)' : 'Time for: $medName ($dosage)';
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'es'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) async => S(locale);

  @override
  bool shouldReload(_SDelegate old) => false;
}
