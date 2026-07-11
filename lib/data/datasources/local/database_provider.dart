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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            species TEXT NOT NULL,
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
}
