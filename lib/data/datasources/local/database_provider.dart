import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema.
///
/// Since v7 the model is: `medications` is a standalone catalog and
/// `treatments` assigns a medication to a pet with a dosing schedule
/// (1 medication → many treatments). Dose logs reference treatments.
class DatabaseProvider {
  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'pet_meds.db'),
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            species TEXT NOT NULL,
            breed TEXT,
            notes TEXT,
            photoPath TEXT,
            birthDate TEXT
          )
        ''');
        await _createMedicationsTable(db);
        await _createTreatmentsTable(db);
        await _createDoseLogsTable(db);
        await _createWeightTable(db);
        await _createVaccinationsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE pets ADD COLUMN photoPath TEXT');
          await db.execute('ALTER TABLE pets ADD COLUMN birthDate TEXT');
          await _createWeightTable(db);
        }
        if (oldVersion < 3) {
          await db.execute(
              "ALTER TABLE medications ADD COLUMN doseAmount REAL NOT NULL DEFAULT 1");
          await db.execute(
              "ALTER TABLE medications ADD COLUMN doseUnit TEXT NOT NULL DEFAULT 'unit'");
          // Keep the old free-text dose visible by appending it to notes.
          await db.execute(
              "UPDATE medications SET notes = COALESCE(notes || ' · ', '') || dosage "
              "WHERE dosage IS NOT NULL AND dosage != ''");
        }
        if (oldVersion < 4) {
          await _createVaccinationsTable(db);
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE pets ADD COLUMN breed TEXT');
        }
        if (oldVersion < 7) {
          await _migrateToCatalogAndTreatments(db);
        }
        if (oldVersion >= 7 && oldVersion < 8) {
          // v8: richer frequency model. (<7 already got the new columns
          // via the rebuilt treatments table above.) Idempotent: only
          // adds what's missing, so a previously interrupted upgrade
          // can't hit 'duplicate column'.
          final columns = await _tableColumns(db, 'treatments');
          const added = {
            'intervalValue': 'INTEGER NOT NULL DEFAULT 8',
            'intervalUnit': "TEXT NOT NULL DEFAULT 'hours'",
            'weekdays': "TEXT NOT NULL DEFAULT ''",
            'cycleDaysOn': 'INTEGER NOT NULL DEFAULT 21',
            'cycleDaysOff': 'INTEGER NOT NULL DEFAULT 7',
          };
          for (final entry in added.entries) {
            if (!columns.contains(entry.key)) {
              await db.execute(
                  'ALTER TABLE treatments ADD COLUMN ${entry.key} ${entry.value}');
            }
          }
          if (columns.contains('intervalDays')) {
            await db.execute(
                "UPDATE treatments SET intervalValue = intervalDays, intervalUnit = 'days', "
                "frequencyType = 'interval' WHERE frequencyType = 'intervalDays'");
          } else {
            await db.execute(
                "UPDATE treatments SET intervalUnit = 'days', frequencyType = 'interval' "
                "WHERE frequencyType = 'intervalDays'");
          }
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<Set<String>> _tableColumns(Database db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.map((r) => r['name'] as String).toSet();
  }

  Future<void> _createMedicationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE medications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<void> _createTreatmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE treatments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
        medicationId INTEGER NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
        doseAmount REAL NOT NULL DEFAULT 1,
        doseUnit TEXT NOT NULL DEFAULT 'unit',
        frequencyType TEXT NOT NULL,
        times TEXT NOT NULL,
        intervalValue INTEGER NOT NULL DEFAULT 8,
        intervalUnit TEXT NOT NULL DEFAULT 'hours',
        weekdays TEXT NOT NULL DEFAULT '',
        cycleDaysOn INTEGER NOT NULL DEFAULT 21,
        cycleDaysOff INTEGER NOT NULL DEFAULT 7,
        startDate TEXT NOT NULL,
        endDate TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        notes TEXT
      )
    ''');
  }

  Future<void> _createDoseLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE dose_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        treatmentId INTEGER NOT NULL REFERENCES treatments(id) ON DELETE CASCADE,
        petId INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
        givenAt TEXT NOT NULL,
        note TEXT
      )
    ''');
  }

  /// v7: the old `medications` table (one row per pet+med+schedule, possibly
  /// still carrying a legacy NOT NULL `dosage` column from v1/v2) is split
  /// into a `medications` catalog and a `treatments` table. Existing rows
  /// become treatments; distinct names seed the catalog. Dose logs are
  /// backed up first — with foreign_keys ON, dropping their parent table
  /// would cascade-delete them — then rebuilt referencing treatments.
  Future<void> _migrateToCatalogAndTreatments(Database db) async {
    // 1. Back up dose_logs without FKs, then drop it (child first).
    await db.execute('''
      CREATE TABLE dose_logs_backup(
        id INTEGER,
        medicationId INTEGER NOT NULL,
        petId INTEGER NOT NULL,
        givenAt TEXT NOT NULL,
        note TEXT
      )
    ''');
    await db.execute(
        'INSERT INTO dose_logs_backup SELECT id, medicationId, petId, givenAt, note FROM dose_logs');
    await db.execute('DROP TABLE dose_logs');

    // 2. Free up the `medications` name for the catalog.
    await db.execute('ALTER TABLE medications RENAME TO old_treatments');

    // 3. Catalog: one row per distinct medication name.
    await _createMedicationsTable(db);
    await db.execute(
        'INSERT INTO medications(name) SELECT DISTINCT name FROM old_treatments');

    // 4. Treatments: old rows keep their ids, linked to the catalog by
    //    name. Legacy 'intervalDays' frequency maps to the richer
    //    interval model (value + unit).
    await _createTreatmentsTable(db);
    await db.execute('''
      INSERT INTO treatments (id, petId, medicationId, doseAmount, doseUnit,
                              frequencyType, times, intervalValue,
                              intervalUnit, startDate, endDate, active, notes)
      SELECT t.id, t.petId, m.id, t.doseAmount, t.doseUnit,
             CASE t.frequencyType WHEN 'intervalDays' THEN 'interval'
                                  ELSE t.frequencyType END,
             t.times,
             CASE t.frequencyType WHEN 'intervalDays' THEN t.intervalDays
                                  ELSE 8 END,
             CASE t.frequencyType WHEN 'intervalDays' THEN 'days'
                                  ELSE 'hours' END,
             t.startDate, t.endDate, t.active, t.notes
      FROM old_treatments t
      JOIN medications m ON m.name = t.name
    ''');
    await db.execute('DROP TABLE old_treatments');

    // 5. Restore dose logs referencing treatments (same ids as before).
    await _createDoseLogsTable(db);
    await db.execute(
        'INSERT INTO dose_logs (id, treatmentId, petId, givenAt, note) '
        'SELECT id, medicationId, petId, givenAt, note FROM dose_logs_backup');
    await db.execute('DROP TABLE dose_logs_backup');
  }

  Future<void> _createWeightTable(Database db) async {
    await db.execute('''
      CREATE TABLE weight_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
        weightKg REAL NOT NULL,
        measuredAt TEXT NOT NULL,
        note TEXT
      )
    ''');
  }

  Future<void> _createVaccinationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE vaccinations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
        vaccineType TEXT NOT NULL,
        appliedAt TEXT NOT NULL,
        reminderValue INTEGER,
        reminderUnit TEXT,
        notes TEXT
      )
    ''');
  }
}
