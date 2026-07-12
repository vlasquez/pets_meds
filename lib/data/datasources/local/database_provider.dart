import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema.
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
      version: 6,
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
        await db.execute('''
          CREATE TABLE medications(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            petId INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            doseAmount REAL NOT NULL DEFAULT 1,
            doseUnit TEXT NOT NULL DEFAULT 'unit',
            frequencyType TEXT NOT NULL,
            times TEXT NOT NULL,
            intervalDays INTEGER NOT NULL DEFAULT 1,
            startDate TEXT NOT NULL,
            endDate TEXT,
            active INTEGER NOT NULL DEFAULT 1,
            notes TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE dose_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medicationId INTEGER NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
            petId INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
            givenAt TEXT NOT NULL,
            note TEXT
          )
        ''');
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
        if (oldVersion < 6) {
          await _rebuildMedicationsTable(db);
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
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

  /// Databases created before v3 have a legacy `dosage TEXT NOT NULL`
  /// column that later schemas no longer write, so inserts fail with a
  /// NOT NULL constraint. SQLite can't drop/relax a column, so rebuild
  /// the table with the current schema. Dose logs are backed up first:
  /// with foreign_keys ON, dropping `medications` would cascade-delete
  /// them.
  Future<void> _rebuildMedicationsTable(Database db) async {
    const columns =
        'id, petId, name, doseAmount, doseUnit, frequencyType, times, '
        'intervalDays, startDate, endDate, active, notes';

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

    // 2. Rebuild medications with the current schema.
    await db.execute('''
      CREATE TABLE medications_new(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        doseAmount REAL NOT NULL DEFAULT 1,
        doseUnit TEXT NOT NULL DEFAULT 'unit',
        frequencyType TEXT NOT NULL,
        times TEXT NOT NULL,
        intervalDays INTEGER NOT NULL DEFAULT 1,
        startDate TEXT NOT NULL,
        endDate TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        notes TEXT
      )
    ''');
    await db.execute(
        'INSERT INTO medications_new ($columns) SELECT $columns FROM medications');
    await db.execute('DROP TABLE medications');
    await db.execute('ALTER TABLE medications_new RENAME TO medications');

    // 3. Restore dose_logs with its FKs.
    await db.execute('''
      CREATE TABLE dose_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicationId INTEGER NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
        petId INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
        givenAt TEXT NOT NULL,
        note TEXT
      )
    ''');
    await db.execute(
        'INSERT INTO dose_logs SELECT id, medicationId, petId, givenAt, note FROM dose_logs_backup');
    await db.execute('DROP TABLE dose_logs_backup');
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
