import 'package:flutter/widgets.dart';

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
  String get dosage => _es ? 'Dosis (ej. 5 mg, 1 tableta)' : 'Dose (e.g. 5 mg, 1 tablet)';
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
