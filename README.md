# Pet Meds 🐾

Flutter app to manage your pets' medications with local reminders. UI in **Spanish and English** (follows device language). Data stored locally with SQLite — no account needed.

## Features

- Multiple pets (dog, cat, other) with notes
- Medications per pet: name, dose, schedule
- Two schedule types: **daily** (one or more times per day) or **every N days**
- Local push notifications at each scheduled time
- Tap a medication to mark the dose as given (logged with timestamp)
- Dose history per pet

## Setup

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install).

```bash
cd pet_meds
flutter create . --platforms=android,ios   # generates android/ and ios/ folders
flutter pub get
flutter run
```

### Android — required manifest changes

After `flutter create .`, edit `android/app/src/main/AndroidManifest.xml` and add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

And inside `<application>` (to restore reminders after reboot):

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
    </intent-filter>
</receiver>
```

Also set `minSdkVersion 21` (or higher) in `android/app/build.gradle` and enable core library desugaring if the build asks for it (required by flutter_local_notifications):

```gradle
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}
dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
```

### iOS

Notification permission is requested automatically on first launch. No extra config needed for basic local notifications.

## Architecture (Clean Architecture + BLoC)

Three layers with a strict dependency rule — presentation → domain ← data. The domain layer is pure Dart (no Flutter, no SQLite, no notification APIs).

### Presentation layer (`lib/presentation/`)

Everything UI-related, in three parts:

- **Screens** (`screens/`) — full routes: `HomeScreen`, `PetDetailScreen`, `PetFormScreen`, `MedicationFormScreen`, `HistoryScreen`.
- **Widgets** (`widgets/`) — reusable building blocks: `PetListTile`, `MedicationCard`, `EmptyState`, `showConfirmDialog`.
- **State management** (`blocs/`) — `PetsBloc`, `MedicationsBloc`, `HistoryBloc`, each with its events (inputs) and states (outputs). Blocs depend only on domain use cases.

### Domain layer (`lib/domain/`)

The business rules — what the app does, not how:

- **Entities** (`entities/`) — `Pet`, `Medication`, `DoseLog`, `ScheduleTime` (pure value object replacing Flutter's `TimeOfDay`).
- **Repositories** (`repositories/`) — abstract contracts: `PetRepository`, `MedicationRepository`, `DoseLogRepository`, `ReminderScheduler`.
- **Use cases** (`usecases/`) — one file per business requirement: `GetPets`, `SavePet`, `DeletePet`, `GetMedications`, `SaveMedication`, `DeleteMedication`, `LogDose`, `GetDoseHistory`.

### Data layer (`lib/data/`)

Data fetching and persistence only — no UI, no state changes:

- **Models** (`models/`) — `PetModel`, `MedicationModel`, `DoseLogModel`: extend the domain entities and add SQLite row (de)serialization.
- **Repositories** (`repositories/`) — implementations of the domain contracts, bridging use cases and data sources.
- **Data sources** (`datasources/local/`) — the actual queries: `DatabaseProvider` (schema/connection), per-table SQLite datasources, and `NotificationDataSource` (flutter_local_notifications).

Dependency injection is wired in `lib/injection.dart` with `get_it`. Localized notification texts are produced in the presentation layer and passed through events/use cases, so inner layers never touch `BuildContext`.

## Project structure

```
lib/
  main.dart                       # App entry, PetsBloc provider, theme, l10n
  injection.dart                  # get_it wiring (datasources → repos → usecases)
  l10n/strings.dart               # ES/EN strings
  domain/
    entities/                     # Pet, Medication, DoseLog, ScheduleTime
    repositories/                 # Abstract contracts
    usecases/                     # One class per business operation
  data/
    models/                       # Entity ↔ SQLite row mapping
    datasources/local/            # sqflite + flutter_local_notifications
    repositories/                 # Contract implementations
  presentation/
    blocs/                        # pets/, medications/, history/
    screens/                      # Routes
    widgets/                      # Reusable UI components
```

## Notes

- "Every N days" reminders schedule the next occurrence and roll forward when you log a dose or reopen the medication.
- Deleting a pet removes its medications, reminders, and history.
